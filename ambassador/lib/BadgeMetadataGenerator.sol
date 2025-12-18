// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/NekoAmbassadorBadge.sol";

/**
 * @title BadgeMetadataGenerator
 * @dev Helper library for generating badge NFT metadata JSON
 */
library BadgeMetadataGenerator {
    
    /**
     * @dev Get badge type name
     */
    function getBadgeTypeName(NekoAmbassadorBadge.BadgeType badgeType) internal pure returns (string memory) {
        if (badgeType == NekoAmbassadorBadge.BadgeType.NinjaStandard) {
            return "ninja-ambassador-standard";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.NinjaElite) {
            return "ninja-ambassador-elite";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SamuraiStandard) {
            return "samurai-ambassador-standard";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SamuraiElite) {
            return "samurai-ambassador-elite";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.GeishaStandard) {
            return "geisha-ambassador-standard";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.GeishaElite) {
            return "geisha-ambassador-elite";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SumoStandard) {
            return "sumo-ambassador-standard";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SumoElite) {
            return "sumo-ambassador-elite";
        }
        return "unknown";
    }
    
    /**
     * @dev Get badge display name (for metadata)
     */
    function getBadgeDisplayName(NekoAmbassadorBadge.BadgeType badgeType) internal pure returns (string memory) {
        if (badgeType == NekoAmbassadorBadge.BadgeType.NinjaStandard) {
            return "Ninja Ambassador (Standard)";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.NinjaElite) {
            return "Ninja Ambassador (Elite)";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SamuraiStandard) {
            return "Samurai Ambassador (Standard)";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SamuraiElite) {
            return "Samurai Ambassador (Elite)";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.GeishaStandard) {
            return "Geisha Ambassador (Standard)";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.GeishaElite) {
            return "Geisha Ambassador (Elite)";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SumoStandard) {
            return "Sumo Ambassador (Standard)";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SumoElite) {
            return "Sumo Ambassador (Elite)";
        }
        return "Unknown Ambassador";
    }
    
    /**
     * @dev Get badge emoji
     */
    function getBadgeEmoji(NekoAmbassadorBadge.BadgeType badgeType) internal pure returns (string memory) {
        if (badgeType == NekoAmbassadorBadge.BadgeType.NinjaStandard || 
            badgeType == NekoAmbassadorBadge.BadgeType.NinjaElite) {
            return unicode"🥷";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SamuraiStandard || 
                   badgeType == NekoAmbassadorBadge.BadgeType.SamuraiElite) {
            return unicode"⚔️";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.GeishaStandard || 
                   badgeType == NekoAmbassadorBadge.BadgeType.GeishaElite) {
            return unicode"🎭";
        } else if (badgeType == NekoAmbassadorBadge.BadgeType.SumoStandard || 
                   badgeType == NekoAmbassadorBadge.BadgeType.SumoElite) {
            return unicode"🤼";
        }
        return unicode"🎖️";
    }
    
    /**
     * @dev Get badge tier name
     */
    function getBadgeTierName(NekoAmbassadorBadge.BadgeType badgeType) internal pure returns (string memory) {
        if (badgeType == NekoAmbassadorBadge.BadgeType.NinjaElite ||
            badgeType == NekoAmbassadorBadge.BadgeType.SamuraiElite ||
            badgeType == NekoAmbassadorBadge.BadgeType.GeishaElite ||
            badgeType == NekoAmbassadorBadge.BadgeType.SumoElite) {
            return "Elite";
        }
        return "Standard";
    }
    
    /**
     * @dev Build image path for badge
     * @param badgeType Type of badge
     * @param imageBaseURI Base URI for images (IPFS)
     */
    function buildImagePath(
        NekoAmbassadorBadge.BadgeType badgeType,
        uint256 /* tokenId */,
        string memory imageBaseURI,
        string memory badgeTypeImageHash
    ) internal pure returns (string memory) {
        if (bytes(badgeTypeImageHash).length > 0) {
            return string(abi.encodePacked("ipfs://", badgeTypeImageHash));
        }
        string memory badgeName = getBadgeTypeName(badgeType);
        return string(abi.encodePacked(
            imageBaseURI,
            badgeName,
            ".png"
        ));
    }
    
    /**
     * @dev Generate metadata JSON for badge
     */
    function generateMetadataJson(
        uint256 tokenId,
        address ambassador,
        NekoAmbassadorBadge.BadgeType badgeType,
        uint256 mintedAt,
        uint256 expiresAt,
        string memory imageBaseURI,
        string memory badgeTypeImageHash
    ) internal pure returns (string memory) {
        string memory badgeName = getBadgeTypeName(badgeType);
        string memory displayName = getBadgeDisplayName(badgeType);
        string memory tierName = getBadgeTierName(badgeType);
        string memory emoji = getBadgeEmoji(badgeType);
        string memory imagePath = buildImagePath(badgeType, tokenId, imageBaseURI, badgeTypeImageHash);
        
        return string(abi.encodePacked(
            '{"name":"NekoCat Ambassador Badge #',
            _toString(tokenId),
            '","description":"',
            emoji,
            ' ',
            displayName,
            ' Badge - Official NekoCat Ambassador NFT. This badge represents your status as a NekoCat Ambassador.","image":"',
            imagePath,
            '","external_url":"https://nekocat.world/ambassador/',
            _toString(tokenId),
            '","attributes":[',
            '{"trait_type":"Badge Type","value":"',
            badgeName,
            '"},',
            '{"trait_type":"Tier","value":"',
            tierName,
            '"},',
            '{"trait_type":"Ambassador","value":"',
            _addressToString(ambassador),
            '"},',
            '{"trait_type":"Minted At","value":"',
            _toString(mintedAt),
            '","display_type":"date"},',
            '{"trait_type":"Expires At","value":"',
            _toString(expiresAt),
            '","display_type":"date"}',
            ']}'
        ));
    }
    
    /**
     * @dev Base64 encode
     */
    function base64Encode(bytes memory data) internal pure returns (string memory) {
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        
        bytes memory result = new bytes(encodedLen);
        uint256 i = 0;
        uint256 j = 0;
        
        for (; i + 3 <= data.length; i += 3) {
            uint256 a = uint256(uint8(data[i]));
            uint256 b = uint256(uint8(data[i + 1]));
            uint256 c = uint256(uint8(data[i + 2]));
            
            uint256 bitmap = (a << 16) | (b << 8) | c;
            
            result[j++] = bytes(table)[bitmap >> 18];
            result[j++] = bytes(table)[(bitmap >> 12) & 63];
            result[j++] = bytes(table)[(bitmap >> 6) & 63];
            result[j++] = bytes(table)[bitmap & 63];
        }
        
        if (i < data.length) {
            uint256 a = uint256(uint8(data[i]));
            uint256 b = i + 1 < data.length ? uint256(uint8(data[i + 1])) : 0;
            uint256 c = 0;
            
            uint256 bitmap = (a << 16) | (b << 8) | c;
            
            result[j++] = bytes(table)[bitmap >> 18];
            result[j++] = bytes(table)[(bitmap >> 12) & 63];
            
            if (i + 1 < data.length) {
                result[j++] = bytes(table)[(bitmap >> 6) & 63];
            } else {
                result[j++] = '=';
            }
            result[j++] = '=';
        }
        
        return string(result);
    }
    
    /**
     * @dev Convert uint256 to string
     */
    function _toString(uint256 value) private pure returns (string memory) {
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
    
    /**
     * @dev Convert address to string
     */
    function _addressToString(address addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}

