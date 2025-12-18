// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title INekoAmbassadorBadge
 * @dev Interface for NekoAmbassadorBadge contract
 */
interface INekoAmbassadorBadge {
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
    
    function mintBadge(
        address ambassador,
        BadgeType badgeType,
        uint256 expiresAt
    ) external payable returns (uint256);
    
    function setEliteBadgeFee(uint256 newFee) external;
    function eliteBadgeFee() external view returns (uint256);
    
    function burnBadge(uint256 tokenId) external;
    function updateExpiration(uint256 tokenId, uint256 newExpiresAt) external;
    function checkAndBurnExpired(uint256[] calldata tokenIds) external;
    
    function getBadgeInfo(uint256 tokenId) external view returns (BadgeInfo memory);
    function getAmbassadorBadge(address ambassador) external view returns (uint256);
    function isExpired(uint256 tokenId) external view returns (bool);
    
    function badgeTypeCounts(BadgeType) external view returns (uint256);
    function ambassadorToTokenId(address) external view returns (uint256);
}

