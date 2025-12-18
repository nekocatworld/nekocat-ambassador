// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/NekoAmbassadorBadge.sol";

/**
 * @title INekoAmbassadorRegistry
 * @dev Interface for NekoAmbassadorRegistry contract
 */
interface INekoAmbassadorRegistry {
    enum FormType {
        Ambassador,
        Partner,
        Contact
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
    
    function submitApplication(
        FormType formType,
        string calldata dataHash
    ) external payable;
    
    function submitApplicationWithData(
        FormType formType,
        string calldata data,
        NekoAmbassadorBadge.BadgeType badgeType
    ) external payable;
    
    
    function onBadgeMinted(
        address ambassador,
        NekoAmbassadorBadge.BadgeType badgeType,
        uint256 tokenId,
        uint256 expiresAt
    ) external;
    
    function revokeAmbassador(address ambassador) external;
    function extendAmbassador(address ambassador, uint256 additionalDuration) external;
    function updateAmbassadorExpiration(address ambassador, uint256 newExpiresAt) external;
    function checkAndBurnExpiredBadges(address[] calldata ambassadors) external;
    
    function setAmbassadorDuration(uint256 newDuration) external;
    function setSubmissionFee(uint256 newFee) external;
    function setAdmin(address admin, bool isAdmin) external;
    
    function getApplication(uint256 applicationId) external view returns (Application memory);
    function getApplicantApplications(address applicant) external view returns (uint256[] memory);
    function getAmbassadorInfo(address ambassador) external view returns (AmbassadorInfo memory);
    function isActiveAmbassador(address account) external view returns (bool);
    
    function nextApplicationId() external view returns (uint256);
    function ambassadorDuration() external view returns (uint256);
    function minSubmissionFee() external view returns (uint256);
    function totalApplications() external view returns (uint256);
    function totalApproved() external view returns (uint256);
}

