// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../lib/AmbassadorErrors.sol";
import "../lib/BadgeMetadataGenerator.sol";
import "../interfaces/INekoAmbassadorRegistry.sol";

/**
 * @title NekoAmbassadorBadge
 * @dev NFT Badge system for Ambassadors
 *
 * Features:
 * - 4 badge types: Ninja, Samurai, Geisha, Sumo
 * - 1 badge per ambassador
 * - Auto-burn on expiration
 * - Minted by AmbassadorRegistry on approval
 */
contract NekoAmbassadorBadge is
    ERC721,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    enum BadgeType {
        NinjaStandard,
        NinjaElite,
        SamuraiStandard,
        SamuraiElite,
        GeishaStandard,
        GeishaElite,
        SumoStandard,
        SumoElite
    }

    enum BadgeTier {
        Standard,
        Elite
    }

    struct BadgeInfo {
        uint256 tokenId;
        address ambassador;
        BadgeType badgeType;
        BadgeTier tier;
        uint256 mintedAt;
        uint256 expiresAt;
        bool exists;
    }

    address public ambassadorRegistry;
    mapping(address => uint256) public ambassadorToTokenId;
    mapping(uint256 => BadgeInfo) public badgeInfo;
    mapping(BadgeType => uint256) public badgeTypeCounts;
    mapping(BadgeType => string) public badgeTypeImageHash;

    uint256 public eliteBadgeFee = 0.007 ether; // 0.007 ETH default fee for elite badges

    uint256 private _nextTokenId = 1;
    string private _baseTokenURI;
    string private _imageBaseURI;

    event BadgeMinted(
        uint256 indexed tokenId,
        address indexed ambassador,
        BadgeType badgeType,
        uint256 expiresAt
    );

    event BadgeBurned(
        uint256 indexed tokenId,
        address indexed ambassador,
        BadgeType badgeType
    );

    event BadgeExpirationUpdated(uint256 indexed tokenId, uint256 newExpiresAt);
    event EliteBadgeFeeUpdated(uint256 newFee);
    event BadgeTypeImageHashUpdated(BadgeType indexed badgeType, string ipfsHash);

    modifier onlyRegistry() {
        require(msg.sender == ambassadorRegistry, "Only registry");
        _;
    }

    constructor(
        address _owner
    ) ERC721("NekoAmbassadorBadge", "NEKOAB") Ownable(_owner) {
        _baseTokenURI = "https://api.nekocat.world/ambassador-badge/";
        _imageBaseURI = "ipfs://QmBadgeHash/"; // Default IPFS base URI for images
    }

    function setAmbassadorRegistry(address _registry) external onlyOwner {
        ambassadorRegistry = _registry;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setImageBaseURI(
        string calldata newImageBaseURI
    ) external onlyOwner {
        _imageBaseURI = newImageBaseURI;
    }

    function imageBaseURI() external view returns (string memory) {
        return _imageBaseURI;
    }

    /**
     * @dev Set elite badge fee (only owner)
     * @param newFee New fee in wei
     */
    function setEliteBadgeFee(uint256 newFee) external onlyOwner {
        eliteBadgeFee = newFee;
        emit EliteBadgeFeeUpdated(newFee);
    }

    /**
     * @dev Check if badge type is elite
     */
    function isEliteBadge(BadgeType badgeType) internal pure returns (bool) {
        return
            badgeType == BadgeType.NinjaElite ||
            badgeType == BadgeType.SamuraiElite ||
            badgeType == BadgeType.GeishaElite ||
            badgeType == BadgeType.SumoElite;
    }

    /**
     * @dev Get badge tier from badge type
     */
    function getBadgeTier(
        BadgeType badgeType
    ) internal pure returns (BadgeTier) {
        if (isEliteBadge(badgeType)) {
            return BadgeTier.Elite;
        }
        return BadgeTier.Standard;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Get token URI with on-chain metadata
     * @param tokenId Token ID
     * @return data URI with JSON metadata
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        BadgeInfo memory info = badgeInfo[tokenId];
        require(info.exists, "Badge not found");

        // Generate metadata JSON
        string memory json = BadgeMetadataGenerator.generateMetadataJson(
            tokenId,
            info.ambassador,
            info.badgeType,
            info.mintedAt,
            info.expiresAt,
            _imageBaseURI,
            badgeTypeImageHash[info.badgeType]
        );

        // Return data URI
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    BadgeMetadataGenerator.base64Encode(bytes(json))
                )
            );
    }

    /**
     * @dev Get image URI for badge
     * @param tokenId Token ID
     * @return IPFS image URI
     */
    function getImageURI(
        uint256 tokenId
    ) external view returns (string memory) {
        BadgeInfo memory info = badgeInfo[tokenId];
        require(info.exists, "Badge not found");

        return
            BadgeMetadataGenerator.buildImagePath(
                info.badgeType,
                tokenId,
                _imageBaseURI,
                badgeTypeImageHash[info.badgeType]
            );
    }

    /**
     * @dev Mint badge for approved ambassador (called by registry)
     * @param ambassador Address of the ambassador
     * @param badgeType Type of badge to mint
     * @param expiresAt Expiration timestamp
     * @notice Elite badges require payment, standard badges are free
     */
    function mintBadge(
        address ambassador,
        BadgeType badgeType,
        uint256 expiresAt
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(ambassadorToTokenId[ambassador] == 0, "Already has badge");
        require(expiresAt > block.timestamp, "Invalid expiration");
        require(msg.sender == ambassador || msg.sender == ambassadorRegistry, "Not authorized");

        BadgeTier tier = getBadgeTier(badgeType);

        // Check payment for elite badges
        if (tier == BadgeTier.Elite) {
            require(
                msg.value >= eliteBadgeFee,
                "Insufficient fee for elite badge"
            );
        } else {
            require(msg.value == 0, "Standard badges are free");
        }

        uint256 tokenId = _nextTokenId++;

        _safeMint(ambassador, tokenId);

        badgeInfo[tokenId] = BadgeInfo({
            tokenId: tokenId,
            ambassador: ambassador,
            badgeType: badgeType,
            tier: tier,
            mintedAt: block.timestamp,
            expiresAt: expiresAt,
            exists: true
        });

        ambassadorToTokenId[ambassador] = tokenId;
        badgeTypeCounts[badgeType]++;

        emit BadgeMinted(tokenId, ambassador, badgeType, expiresAt);

        if (ambassadorRegistry != address(0)) {
            try INekoAmbassadorRegistry(payable(ambassadorRegistry)).onBadgeMinted(
                ambassador,
                badgeType,
                tokenId,
                expiresAt
            ) {} catch {}
        }

        return tokenId;
    }

    /**
     * @dev Burn expired badge (called by registry or auto-check)
     * @param tokenId Token ID to burn
     */
    function burnBadge(uint256 tokenId) external {
        BadgeInfo memory info = badgeInfo[tokenId];
        require(info.exists, "Badge not found");

        bool canBurn = false;

        if (msg.sender == ambassadorRegistry || msg.sender == owner()) {
            canBurn = true;
        } else if (
            msg.sender == info.ambassador && block.timestamp >= info.expiresAt
        ) {
            canBurn = true;
        }

        require(canBurn, "Not authorized or not expired");

        address ambassador = info.ambassador;
        BadgeType badgeType = info.badgeType;

        delete badgeInfo[tokenId];
        delete ambassadorToTokenId[ambassador];
        badgeTypeCounts[badgeType]--;

        _burn(tokenId);

        emit BadgeBurned(tokenId, ambassador, badgeType);
    }

    /**
     * @dev Update badge expiration (called by registry)
     * @param tokenId Token ID
     * @param newExpiresAt New expiration timestamp
     */
    function updateExpiration(
        uint256 tokenId,
        uint256 newExpiresAt
    ) external onlyRegistry {
        require(badgeInfo[tokenId].exists, "Badge not found");
        require(newExpiresAt > block.timestamp, "Invalid expiration");

        badgeInfo[tokenId].expiresAt = newExpiresAt;

        emit BadgeExpirationUpdated(tokenId, newExpiresAt);
    }

    /**
     * @dev Check and burn expired badges
     * @param tokenIds Array of token IDs to check
     */
    function checkAndBurnExpired(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            BadgeInfo memory info = badgeInfo[tokenIds[i]];
            if (info.exists && block.timestamp >= info.expiresAt) {
                this.burnBadge(tokenIds[i]);
            }
        }
    }

    /**
     * @dev Get badge info
     */
    function getBadgeInfo(
        uint256 tokenId
    ) external view returns (BadgeInfo memory) {
        return badgeInfo[tokenId];
    }

    /**
     * @dev Get ambassador's badge token ID
     */
    function getAmbassadorBadge(
        address ambassador
    ) external view returns (uint256) {
        return ambassadorToTokenId[ambassador];
    }

    /**
     * @dev Check if badge is expired
     */
    function isExpired(uint256 tokenId) external view returns (bool) {
        BadgeInfo memory info = badgeInfo[tokenId];
        return info.exists && block.timestamp >= info.expiresAt;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Withdraw collected elite badge fees (only owner)
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert("No funds to withdraw");
        }
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Receive ETH for elite badge fees
     */
    receive() external payable {
        // Accept ETH for elite badge fees
    }
}
