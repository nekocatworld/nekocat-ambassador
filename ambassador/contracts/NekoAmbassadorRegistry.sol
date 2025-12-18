// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./NekoAmbassadorBadge.sol";
import "../lib/AmbassadorConstants.sol";
import "../lib/AmbassadorErrors.sol";

/**
 * @title NekoAmbassadorRegistry
 * @dev On-chain registry for ambassador applications, approvals, and management
 *
 * Features:
 * - Submit ambassador forms on-chain
 * - Admin approval/rejection system
 * - Ambassador status tracking with expiration dates
 * - Configurable ambassador duration
 * - Event-based tracking for frontend
 * - Gas-efficient storage with struct packing
 */
contract NekoAmbassadorRegistry is Ownable, ReentrancyGuard, Pausable {
    // =============================================================================
    // ENUMS & STRUCTS
    // =============================================================================

    enum FormType {
        Ambassador
    }

    enum ApplicationStatus {
        Approved,
        Expired
    }

    struct Application {
        uint256 applicationId;
        address applicant;
        FormType formType;
        ApplicationStatus status;
        uint256 submittedAt;
        uint256 reviewedAt;
        address reviewedBy;
        uint256 expiresAt;
        string dataHash;
        NekoAmbassadorBadge.BadgeType badgeType; // Badge type assigned by admin
        bool exists;
    }

    struct AmbassadorInfo {
        address ambassador;
        uint256 approvedAt;
        uint256 expiresAt;
        bool isActive;
        FormType originalFormType;
        NekoAmbassadorBadge.BadgeType badgeType;
        uint256 badgeTokenId;
    }

    // =============================================================================
    // STATE VARIABLES
    // =============================================================================

    mapping(uint256 => Application) public applications;
    mapping(address => uint256[]) public applicantApplications;
    mapping(address => AmbassadorInfo) public ambassadors;
    mapping(address => bool) public admins;

    NekoAmbassadorBadge public badgeContract;

    uint256 public nextApplicationId = 1;
    uint256 public ambassadorDuration =
        AmbassadorConstants.DEFAULT_AMBASSADOR_DURATION;
    uint256 public minSubmissionFee =
        AmbassadorConstants.DEFAULT_SUBMISSION_FEE;

    uint256 public totalApplications;
    uint256 public totalApproved;

    // =============================================================================
    // EVENTS
    // =============================================================================

    event ApplicationSubmitted(
        uint256 indexed applicationId,
        address indexed applicant,
        FormType formType,
        string dataHash,
        uint256 timestamp
    );

    event ApplicationReviewed(
        uint256 indexed applicationId,
        address indexed applicant,
        ApplicationStatus status,
        address indexed reviewer,
        uint256 expiresAt,
        uint256 timestamp
    );

    event AmbassadorStatusUpdated(
        address indexed ambassador,
        bool isActive,
        uint256 expiresAt,
        uint256 timestamp
    );

    event AmbassadorDurationUpdated(uint256 newDuration, uint256 timestamp);
    event AdminUpdated(address indexed admin, bool isAdmin, uint256 timestamp);
    event SubmissionFeeUpdated(uint256 newFee, uint256 timestamp);
    event BadgeMinted(
        address indexed ambassador,
        uint256 indexed tokenId,
        NekoAmbassadorBadge.BadgeType badgeType,
        uint256 expiresAt
    );
    event BadgeBurned(address indexed ambassador, uint256 indexed tokenId);
    event BadgeContractUpdated(address indexed newBadgeContract);

    // =============================================================================
    // MODIFIERS
    // =============================================================================

    modifier onlyAdmin() {
        if (!admins[msg.sender] && msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    modifier validApplicationId(uint256 applicationId) {
        if (!applications[applicationId].exists) {
            revert ApplicationNotFound();
        }
        _;
    }

    // =============================================================================
    // CONSTRUCTOR
    // =============================================================================

    constructor(address _owner) Ownable(_owner) {
        admins[_owner] = true;
        emit AdminUpdated(_owner, true, block.timestamp);
    }

    function setBadgeContract(address _badgeContract) external onlyOwner {
        require(_badgeContract != address(0), "Invalid address");
        badgeContract = NekoAmbassadorBadge(payable(_badgeContract));
        emit BadgeContractUpdated(_badgeContract);
    }

    // =============================================================================
    // PUBLIC FUNCTIONS - FORM SUBMISSION
    // =============================================================================

    /**
     * @dev Submit an ambassador application (legacy function - use submitApplicationWithData instead)
     * @param formType Type of form (Ambassador)
     * @param dataHash IPFS hash or encoded form data
     * @notice This function is deprecated - use submitApplicationWithData instead
     */
    function submitApplication(
        FormType formType,
        string calldata dataHash
    ) external payable whenNotPaused nonReentrant {
        if (bytes(dataHash).length == 0) {
            revert DataHashRequired();
        }
        if (msg.value < minSubmissionFee) {
            revert InsufficientFee();
        }

        uint256 applicationId = nextApplicationId++;

        applications[applicationId] = Application({
            applicationId: applicationId,
            applicant: msg.sender,
            formType: formType,
            status: ApplicationStatus.Approved,
            submittedAt: block.timestamp,
            reviewedAt: 0,
            reviewedBy: address(0),
            expiresAt: 0,
            dataHash: dataHash,
            badgeType: NekoAmbassadorBadge.BadgeType.NinjaStandard, // Default, will be set on approval
            exists: true
        });

        applicantApplications[msg.sender].push(applicationId);
        totalApplications++;

        emit ApplicationSubmitted(
            applicationId,
            msg.sender,
            formType,
            dataHash,
            block.timestamp
        );
    }

    /**
     * @dev Submit application with detailed data and automatically approve & mint badge
     * @param formType Type of form
     * @param data Encoded form data (must include preferredBadgeType)
     * @param badgeType Badge type selected by user (0-7)
     * @notice Standard badges are free (only gas), elite badges require 0.007 ETH fee + gas
     * @notice No signature verification needed - msg.sender is already authenticated by the transaction
     */
    function submitApplicationWithData(
        FormType formType,
        string calldata data,
        NekoAmbassadorBadge.BadgeType badgeType
    ) external payable whenNotPaused nonReentrant {
        if (bytes(data).length == 0) {
            revert DataRequired();
        }
        // No signature verification needed - msg.sender is already authenticated by the transaction

        // Check if elite badge and validate fee
        bool isElite = badgeType == NekoAmbassadorBadge.BadgeType.NinjaElite ||
            badgeType == NekoAmbassadorBadge.BadgeType.SamuraiElite ||
            badgeType == NekoAmbassadorBadge.BadgeType.GeishaElite ||
            badgeType == NekoAmbassadorBadge.BadgeType.SumoElite;

        uint256 requiredFee = isElite ? badgeContract.eliteBadgeFee() : 0;

        if (isElite) {
            if (msg.value < requiredFee) {
                revert InsufficientFee();
            }
        } else {
            if (msg.value > 0) {
                revert("Standard badges are free");
            }
        }

        uint256 applicationId = nextApplicationId++;
        string memory dataHash = string(
            abi.encodePacked(keccak256(bytes(data)))
        );

        uint256 expiresAt = block.timestamp + ambassadorDuration;

        // Auto-approve and mint badge
        applications[applicationId] = Application({
            applicationId: applicationId,
            applicant: msg.sender,
            formType: formType,
            status: ApplicationStatus.Approved,
            submittedAt: block.timestamp,
            reviewedAt: block.timestamp,
            reviewedBy: address(0), // Auto-approved
            expiresAt: expiresAt,
            dataHash: dataHash,
            badgeType: badgeType,
            exists: true
        });

        applicantApplications[msg.sender].push(applicationId);
        totalApplications++;
        totalApproved++;

        // Mint badge (elite fee is already included in msg.value)
        uint256 badgeTokenId = badgeContract.mintBadge{value: requiredFee}(
            msg.sender,
            badgeType,
            expiresAt
        );

        // Refund excess if any
        if (msg.value > requiredFee) {
            payable(msg.sender).transfer(msg.value - requiredFee);
        }

        ambassadors[msg.sender] = AmbassadorInfo({
            ambassador: msg.sender,
            approvedAt: block.timestamp,
            expiresAt: expiresAt,
            isActive: true,
            originalFormType: formType,
            badgeType: badgeType,
            badgeTokenId: badgeTokenId
        });

        emit ApplicationSubmitted(
            applicationId,
            msg.sender,
            formType,
            dataHash,
            block.timestamp
        );

        emit ApplicationReviewed(
            applicationId,
            msg.sender,
            ApplicationStatus.Approved,
            address(0), // Auto-approved
            expiresAt,
            block.timestamp
        );

        emit AmbassadorStatusUpdated(
            msg.sender,
            true,
            expiresAt,
            block.timestamp
        );

        emit BadgeMinted(msg.sender, badgeTokenId, badgeType, expiresAt);
    }

    // =============================================================================
    // ADMIN FUNCTIONS - APPLICATION REVIEW
    // =============================================================================
    // Note: approveApplication and batchApprove functions removed
    // Applications are now auto-approved and badges are minted immediately upon submission

    /**
     * @dev Called by badge contract when badge is minted
     * Automatically marks the address as verified ambassador
     * @param ambassador Address of the ambassador
     * @param badgeType Type of badge minted
     * @param tokenId Token ID of the minted badge
     * @param expiresAt Expiration timestamp
     */
    function onBadgeMinted(
        address ambassador,
        NekoAmbassadorBadge.BadgeType badgeType,
        uint256 tokenId,
        uint256 expiresAt
    ) external {
        require(msg.sender == address(badgeContract), "Only badge contract");

        if (ambassadors[ambassador].isActive) {
            return;
        }

        ambassadors[ambassador] = AmbassadorInfo({
            ambassador: ambassador,
            approvedAt: block.timestamp,
            expiresAt: expiresAt,
            isActive: true,
            originalFormType: FormType.Ambassador,
            badgeType: badgeType,
            badgeTokenId: tokenId
        });

        emit AmbassadorStatusUpdated(
            ambassador,
            true,
            expiresAt,
            block.timestamp
        );
    }

    // =============================================================================
    // ADMIN FUNCTIONS - AMBASSADOR MANAGEMENT
    // =============================================================================

    /**
     * @dev Revoke ambassador status and burn badge
     * @param ambassador Address of the ambassador to revoke
     */
    function revokeAmbassador(address ambassador) external onlyAdmin {
        AmbassadorInfo storage info = ambassadors[ambassador];
        if (!info.isActive) {
            revert NotAnActiveAmbassador();
        }

        info.isActive = false;
        info.expiresAt = block.timestamp;

        if (info.badgeTokenId > 0) {
            badgeContract.burnBadge(info.badgeTokenId);
            emit BadgeBurned(ambassador, info.badgeTokenId);
            info.badgeTokenId = 0;
        }

        emit AmbassadorStatusUpdated(
            ambassador,
            false,
            block.timestamp,
            block.timestamp
        );
    }

    /**
     * @dev Extend ambassador status and badge expiration
     * @param ambassador Address of the ambassador
     * @param additionalDuration Additional time to extend (in seconds)
     */
    function extendAmbassador(
        address ambassador,
        uint256 additionalDuration
    ) external onlyAdmin {
        AmbassadorInfo storage info = ambassadors[ambassador];
        if (!info.isActive) {
            revert NotAnActiveAmbassador();
        }

        info.expiresAt += additionalDuration;

        if (info.badgeTokenId > 0) {
            badgeContract.updateExpiration(info.badgeTokenId, info.expiresAt);
        }

        emit AmbassadorStatusUpdated(
            ambassador,
            true,
            info.expiresAt,
            block.timestamp
        );
    }

    /**
     * @dev Update ambassador expiration (set new absolute time)
     * @param ambassador Address of the ambassador
     * @param newExpiresAt New expiration timestamp
     */
    function updateAmbassadorExpiration(
        address ambassador,
        uint256 newExpiresAt
    ) external onlyAdmin {
        AmbassadorInfo storage info = ambassadors[ambassador];
        if (!info.isActive) {
            revert NotAnActiveAmbassador();
        }
        if (newExpiresAt <= block.timestamp) {
            revert InvalidDuration();
        }

        info.expiresAt = newExpiresAt;

        if (info.badgeTokenId > 0) {
            badgeContract.updateExpiration(info.badgeTokenId, newExpiresAt);
        }

        emit AmbassadorStatusUpdated(
            ambassador,
            true,
            newExpiresAt,
            block.timestamp
        );
    }

    /**
     * @dev Check and burn expired badges
     * @param ambassadorAddresses Array of ambassador addresses to check
     * @notice Limited to prevent DDoS attacks - max 50 addresses per call
     */
    function checkAndBurnExpiredBadges(
        address[] calldata ambassadorAddresses
    ) external {
        if (ambassadorAddresses.length > AmbassadorConstants.MAX_BATCH_SIZE) {
            revert InvalidBatchSize();
        }

        for (uint256 i = 0; i < ambassadorAddresses.length; i++) {
            address ambassadorAddr = ambassadorAddresses[i];
            AmbassadorInfo storage info = ambassadors[ambassadorAddr];
            if (
                info.isActive &&
                block.timestamp >= info.expiresAt &&
                info.badgeTokenId > 0
            ) {
                info.isActive = false;
                badgeContract.burnBadge(info.badgeTokenId);
                emit BadgeBurned(ambassadorAddresses[i], info.badgeTokenId);
                emit AmbassadorStatusUpdated(
                    ambassadorAddresses[i],
                    false,
                    block.timestamp,
                    block.timestamp
                );
                info.badgeTokenId = 0;
            }
        }
    }

    /**
     * @dev Update ambassador duration for new approvals
     * @param newDuration New duration in seconds
     */
    function setAmbassadorDuration(uint256 newDuration) external onlyOwner {
        if (
            newDuration < AmbassadorConstants.MIN_AMBASSADOR_DURATION ||
            newDuration > AmbassadorConstants.MAX_AMBASSADOR_DURATION
        ) {
            revert InvalidDuration();
        }
        ambassadorDuration = newDuration;
        emit AmbassadorDurationUpdated(newDuration, block.timestamp);
    }

    /**
     * @dev Update minimum submission fee
     * @param newFee New minimum fee in wei
     */
    function setSubmissionFee(uint256 newFee) external onlyOwner {
        if (
            newFee < AmbassadorConstants.MIN_SUBMISSION_FEE ||
            newFee > AmbassadorConstants.MAX_SUBMISSION_FEE
        ) {
            revert InvalidFee();
        }
        minSubmissionFee = newFee;
        emit SubmissionFeeUpdated(newFee, block.timestamp);
    }

    /**
     * @dev Add or remove admin
     * @param admin Address to update
     * @param isAdmin Whether the address should be an admin
     */
    function setAdmin(address admin, bool isAdmin) external onlyOwner {
        admins[admin] = isAdmin;
        emit AdminUpdated(admin, isAdmin, block.timestamp);
    }

    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================

    /**
     * @dev Get application details
     */
    function getApplication(
        uint256 applicationId
    ) external view returns (Application memory) {
        if (!applications[applicationId].exists) {
            revert ApplicationNotFound();
        }
        return applications[applicationId];
    }

    /**
     * @dev Get all applications for an applicant
     */
    function getApplicantApplications(
        address applicant
    ) external view returns (uint256[] memory) {
        return applicantApplications[applicant];
    }

    /**
     * @dev Get ambassador info
     */
    function getAmbassadorInfo(
        address ambassador
    ) external view returns (AmbassadorInfo memory) {
        return ambassadors[ambassador];
    }

    /**
     * @dev Check if address is an active ambassador
     */
    function isActiveAmbassador(address account) external view returns (bool) {
        AmbassadorInfo memory info = ambassadors[account];
        return info.isActive && info.expiresAt > block.timestamp;
    }

    // =============================================================================
    // WITHDRAWAL
    // =============================================================================

    /**
     * @dev Withdraw collected fees
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoFundsToWithdraw();
        }
        payable(owner()).transfer(balance);
    }

    // =============================================================================
    // RECEIVE
    // =============================================================================

    receive() external payable {
        // Accept ETH for submission fees
    }

    // =============================================================================
    // INTERNAL HELPERS
    // =============================================================================

    /**
     * @dev Convert address to string
     */
    function _addressToString(
        address addr
    ) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789ABCDEF"; // Use uppercase for checksum compatibility
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @dev Convert uint256 to string
     */
    function _uintToString(
        uint256 value
    ) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
