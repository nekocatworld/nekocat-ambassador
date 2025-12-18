# NekoCat Ambassador Registry Contracts

On-chain ambassador application and management system for the NekoCat World ecosystem.

**Repository:** [https://github.com/nekocatworld/nekocat-ambassador](https://github.com/nekocatworld/nekocat-ambassador)  
**Domain:** nekocat-world  
**Project:** NekoCat World

## Overview

The NekoCat Ambassador Registry is a comprehensive smart contract system that enables decentralized ambassador management for the NekoCat World ecosystem. The system handles on-chain form submissions, admin approval workflows, NFT badge minting, and ambassador status tracking with expiration dates.

### Key Features

- **On-Chain Storage**: All ambassador applications stored permanently on blockchain
- **NFT Badge System**: ERC721 badges with 8 unique types (Ninja, Samurai, Geisha, Sumo - each with Standard and Elite tiers)
- **Admin System**: Multi-admin support with owner-controlled permissions
- **Batch Operations**: Approve/reject multiple applications efficiently
- **Pagination**: Efficient querying of pending applications
- **Custom Errors**: Gas-efficient error handling
- **Events**: Comprehensive event logging for frontend integration
- **Pausable**: Emergency pause functionality for security
- **Fee Management**: Configurable submission fees and elite badge fees
- **Auto-Expiration**: Badges automatically expire and can be burned after expiration date
- **On-Chain Metadata**: Badge metadata generated on-chain with IPFS image support

## Project Structure

```
ambassador/
├── contracts/
│   ├── NekoAmbassadorRegistry.sol    # Main registry contract
│   └── NekoAmbassadorBadge.sol      # ERC721 badge NFT contract
├── interfaces/
│   ├── INekoAmbassadorRegistry.sol   # Registry interface
│   └── INekoAmbassadorBadge.sol     # Badge interface
├── lib/
│   ├── AmbassadorConstants.sol      # System constants
│   ├── AmbassadorErrors.sol         # Custom error definitions
│   └── BadgeMetadataGenerator.sol   # On-chain metadata generator
├── scripts/
│   ├── deploy.ts                     # Basic deployment script
│   ├── deploy-complete.ts            # Complete deployment with verification
│   ├── deploy-complete-interactive.ts # Interactive deployment (no .env key)
│   ├── verify.ts                     # Contract verification
│   ├── upload-images-to-pinata.js    # IPFS image upload
│   ├── set-image-base-uri.ts         # Set badge image base URI
│   ├── set-elite-badge-fee.ts        # Configure elite badge fee
│   └── update-frontend.ts            # Update frontend config
├── test/
│   └── AmbassadorRegistry.test.ts    # Comprehensive test suite
├── deployments/
│   ├── baseSepolia/                  # Base Sepolia testnet deployments
│   └── soneiumMainnet/               # Sonneium mainnet deployments
├── images/                           # Badge image assets
├── metadata/                         # Badge metadata templates
├── abi/                              # Extracted contract ABIs
├── hardhat.config.ts                 # Hardhat configuration
├── package.json                      # Dependencies and scripts
├── tsconfig.json                     # TypeScript configuration
├── env.example                       # Environment variables template
├── DEPLOYMENT_GUIDE.md               # Detailed deployment guide
└── DEPLOYMENT_SONNEIUM.md            # Sonneium mainnet deployment guide
```

## Badge System

The system includes 8 unique badge types organized into 4 categories with 2 tiers each:

### Badge Types

1. **Ninja**

   - Ninja Standard
   - Ninja Elite

2. **Samurai**

   - Samurai Standard
   - Samurai Elite

3. **Geisha**

   - Geisha Standard
   - Geisha Elite

4. **Sumo**
   - Sumo Standard
   - Sumo Elite

### Badge Features

- **One Badge Per Ambassador**: Each ambassador can only hold one badge at a time
- **Standard Badges**: Free to mint upon approval
- **Elite Badges**: Require payment (default: 0.007 ETH) to mint
- **Auto-Expiration**: Badges expire after the configured duration (default: 365 days)
- **On-Chain Metadata**: Metadata generated on-chain with IPFS image references
- **Enumerable**: Full ERC721Enumerable support for indexing

## Setup

### Prerequisites

- Node.js >= 18.0.0
- npm >= 8.0.0
- Hardhat development environment

### Installation

1. **Install dependencies:**

```bash
npm install
```

2. **Configure environment:**

```bash
cp env.example .env
```

3. **Edit `.env` file with your configuration:**

```env
PRIVATE_KEY=your_private_key_here
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_SEPOLIA_API_KEY=your_base_api_key
SONEIUM_RPC_URL=https://rpc.soneium.org/
SONEIUM_API_KEY=your_soneium_api_key

# Optional: Pinata for IPFS image uploads
PINATA_JWT_TOKEN=your_pinata_jwt_token
# OR
PINATA_API_KEY=your_pinata_api_key
PINATA_SECRET_KEY=your_pinata_secret_key
```

## Deployment

### Base Sepolia (Testnet)

**Basic Deployment:**

```bash
npm run deploy:testnet
```

**Complete Deployment (with verification and frontend update):**

```bash
npm run deploy-complete:testnet
```

**Interactive Deployment (no private key in .env):**

```bash
npm run deploy-complete:interactive:testnet
```

### Sonneium Mainnet

**Basic Deployment:**

```bash
npm run deploy:soneium
```

**Complete Deployment:**

```bash
npm run deploy-complete:mainnet
```

**Interactive Deployment:**

```bash
npm run deploy-complete:interactive:mainnet
```

### Deployed Contracts (Sonneium Mainnet)

- **NekoAmbassadorRegistry**: `0x88733f41dDE2cADc0C959c0d4D6EB31dA3B3C562`
- **NekoAmbassadorBadge**: `0xE1DEF9302e5A7bE8672B89C3dCcF4887e0CD7384`

**Explorer:**

- [Sonneium Blockscout](https://soneium.blockscout.com)
- [Base Sepolia Basescan](https://sepolia.basescan.org)

### Complete Deployment Process

The complete deployment script (`deploy-complete.ts`) performs:

1. Deploys `NekoAmbassadorBadge` contract
2. Deploys `NekoAmbassadorRegistry` contract
3. Links contracts (sets badge address in registry, registry address in badge)
4. Sets elite badge fee (0.007 ETH)
5. Saves deployment information to JSON
6. Extracts ABIs to `abi/` directory
7. Verifies contracts on block explorer
8. Updates frontend configuration (if applicable)

## Contract Functions

### Public Functions

#### Application Submission

- `submitApplication(FormType formType, string calldata dataHash)` - Submit application with IPFS hash
- `submitApplicationWithData(FormType formType, string calldata data, BadgeType badgeType)` - Submit application with data and preferred badge type

### Admin Functions

#### Application Management

- `approveApplication(uint256 applicationId)` - Approve single application
- `rejectApplication(uint256 applicationId)` - Reject single application
- `batchApprove(uint256[] calldata applicationIds)` - Approve multiple applications
- `batchReject(uint256[] calldata applicationIds)` - Reject multiple applications

#### Ambassador Management

- `revokeAmbassador(address ambassador)` - Revoke ambassador status and burn badge
- `extendAmbassador(address ambassador, uint256 additionalDuration)` - Extend ambassador duration
- `updateAmbassadorExpiration(address ambassador, uint256 newExpiresAt)` - Update expiration timestamp
- `checkAndBurnExpiredBadges(address[] calldata ambassadors)` - Batch check and burn expired badges

### Owner Functions

#### Configuration

- `setAmbassadorDuration(uint256 newDuration)` - Set default ambassador duration (30-3650 days)
- `setSubmissionFee(uint256 newFee)` - Set minimum submission fee (0.0001-0.1 ETH)
- `setAdmin(address admin, bool isAdmin)` - Add/remove admin addresses
- `withdrawFees()` - Withdraw collected submission fees

#### Emergency Controls

- `pause()` - Pause all contract operations
- `unpause()` - Resume contract operations

### View Functions

#### Application Queries

- `getApplication(uint256 applicationId)` - Get application details
- `getApplicantApplications(address applicant)` - Get all applications by address
- `getPendingApplicationsCount()` - Get total pending applications
- `getPendingApplications(uint256 offset, uint256 limit)` - Get pending applications with pagination

#### Ambassador Queries

- `getAmbassadorInfo(address ambassador)` - Get ambassador status and details
- `isActiveAmbassador(address ambassador)` - Check if address is active ambassador
- `badgeContract()` - Get badge contract address

### Badge Contract Functions

#### Minting

- `mintBadge(address ambassador, BadgeType badgeType, uint256 expiresAt)` - Mint badge (called by registry or ambassador, requires payment for elite badges)

#### Management

- `burnBadge(uint256 tokenId)` - Burn expired or revoked badge
- `updateExpiration(uint256 tokenId, uint256 newExpiresAt)` - Update badge expiration
- `checkAndBurnExpired(uint256[] calldata tokenIds)` - Batch check and burn expired badges

#### Configuration

- `setEliteBadgeFee(uint256 newFee)` - Set fee for elite badges
- `setImageBaseURI(string calldata newImageBaseURI)` - Set IPFS base URI for images
- `setBadgeTypeImageHash(BadgeType badgeType, string calldata ipfsHash)` - Set IPFS hash for specific badge type

#### Queries

- `getBadgeInfo(uint256 tokenId)` - Get badge details
- `getAmbassadorBadge(address ambassador)` - Get badge token ID for ambassador
- `isExpired(uint256 tokenId)` - Check if badge is expired
- `badgeTypeCounts(BadgeType badgeType)` - Get count of minted badges by type

## Constants

Defined in `lib/AmbassadorConstants.sol`:

- `DEFAULT_AMBASSADOR_DURATION`: 365 days
- `MIN_AMBASSADOR_DURATION`: 30 days
- `MAX_AMBASSADOR_DURATION`: 3650 days (10 years)
- `DEFAULT_SUBMISSION_FEE`: 0.007 ether
- `MIN_SUBMISSION_FEE`: 0.0001 ether
- `MAX_SUBMISSION_FEE`: 0.1 ether
- `MAX_BATCH_SIZE`: 50
- `MAX_PAGINATION_LIMIT`: 100

## Events

### Registry Events

- `ApplicationSubmitted(uint256 indexed applicationId, address indexed applicant, FormType formType)`
- `ApplicationApproved(uint256 indexed applicationId, address indexed applicant, address indexed reviewedBy, BadgeType badgeType)`
- `ApplicationRejected(uint256 indexed applicationId, address indexed applicant, address indexed reviewedBy)`
- `AmbassadorRevoked(address indexed ambassador, uint256 indexed badgeTokenId)`
- `AmbassadorExtended(address indexed ambassador, uint256 newExpiresAt)`
- `SubmissionFeeUpdated(uint256 newFee)`
- `AmbassadorDurationUpdated(uint256 newDuration)`

### Badge Events

- `BadgeMinted(uint256 indexed tokenId, address indexed ambassador, BadgeType badgeType, uint256 expiresAt)`
- `BadgeBurned(uint256 indexed tokenId, address indexed ambassador, BadgeType badgeType)`
- `BadgeExpirationUpdated(uint256 indexed tokenId, uint256 newExpiresAt)`
- `EliteBadgeFeeUpdated(uint256 newFee)`
- `BadgeTypeImageHashUpdated(BadgeType indexed badgeType, string ipfsHash)`

## Testing

### Run Tests

```bash
npm test
```

### Gas Reporting

```bash
npm run test:gas
```

### Coverage

```bash
npm run coverage
```

The test suite includes:

- Application submission and validation
- Admin approval/rejection workflows
- Badge minting (standard and elite)
- Fee payment validation
- Expiration and burning logic
- Batch operations
- Access control and permissions

## Scripts

### Development

```bash
npm run compile          # Compile contracts
npm run test             # Run tests
npm run test:gas         # Run tests with gas reporting
npm run coverage         # Generate coverage report
npm run node             # Start local Hardhat node
npm run clean            # Clean artifacts and cache
npm run typechain        # Generate TypeScript types
```

### Deployment

```bash
npm run deploy:local              # Deploy to local network
npm run deploy:testnet           # Deploy to Base Sepolia
npm run deploy:soneium           # Deploy to Sonneium Mainnet
npm run deploy-complete:testnet  # Complete deployment (testnet)
npm run deploy-complete:mainnet  # Complete deployment (mainnet)
npm run deploy-complete:interactive:testnet  # Interactive (testnet)
npm run deploy-complete:interactive:mainnet # Interactive (mainnet)
```

### Verification

```bash
npm run verify:testnet <contract-address> <constructor-args>
npm run verify:soneium <contract-address> <constructor-args>
```

### Utilities

```bash
npm run upload-images    # Upload badge images to IPFS (Pinata)
```

## Image Management

Badge images are stored on IPFS using Pinata. The system supports:

1. **Image Upload**: Upload all badge images to IPFS
2. **Base URI Configuration**: Set IPFS base URI in badge contract
3. **Per-Type Hashes**: Set individual IPFS hash for each badge type

### Upload Images

```bash
node scripts/upload-images-to-pinata.js
```

### Set Image Base URI

```bash
npx ts-node scripts/set-image-base-uri.ts <badge-address> <ipfs-base-uri>
```

### Set Badge Type Image Hash

```bash
npx ts-node scripts/set-image-hashes-from-pinata.ts
```

## Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **Pausable**: Emergency pause functionality
- **Access Control**: Owner and admin role separation
- **Input Validation**: Comprehensive validation of all inputs
- **Custom Errors**: Gas-efficient error handling
- **Safe Math**: Solidity 0.8.24 built-in overflow protection

## Network Configuration

### Base Sepolia (Testnet)

- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Explorer**: https://sepolia.basescan.org
- **API**: https://api-sepolia.basescan.org/api

### Sonneium Mainnet

- **Chain ID**: 1868
- **RPC URL**: https://rpc.soneium.org/
- **Explorer**: https://soneium.blockscout.com
- **API**: https://soneium.blockscout.com/api

## Architecture

### Contract Relationships

```
NekoAmbassadorRegistry (Main Contract)
    ├── Ownable (Owner controls admin and config)
    ├── ReentrancyGuard (Security)
    ├── Pausable (Emergency controls)
    └── NekoAmbassadorBadge (NFT Badge Contract)
            ├── ERC721 (NFT Standard)
            ├── ERC721Enumerable (Indexing)
            ├── Ownable (Owner controls config)
            ├── ReentrancyGuard (Security)
            └── Pausable (Emergency controls)
```

### Workflow

1. **Application Submission**: User submits application with form data or IPFS hash
2. **Admin Review**: Admin reviews pending applications
3. **Approval**: Admin approves application and selects badge type
4. **Badge Minting**: Registry calls badge contract to mint NFT
5. **Fee Payment**: Elite badges require payment during minting
6. **Status Tracking**: Ambassador status tracked with expiration dates
7. **Expiration**: Badges can be burned after expiration

## Integration

### Frontend Integration

The contracts emit comprehensive events for frontend integration:

- Listen to `ApplicationSubmitted` for new applications
- Listen to `ApplicationApproved` for approvals
- Listen to `BadgeMinted` for new badge mints
- Query `getPendingApplications` for pagination
- Query `isActiveAmbassador` for status checks

### API Integration

The badge contract supports standard ERC721 interfaces:

- `tokenURI(uint256 tokenId)` - Returns on-chain generated metadata
- `getImageURI(uint256 tokenId)` - Returns IPFS image URI
- `balanceOf(address owner)` - Check badge ownership
- `ownerOf(uint256 tokenId)` - Get badge owner

## License

MIT

## Links

- **Repository**: [https://github.com/nekocatworld/nekocat-ambassador](https://github.com/nekocatworld/nekocat-ambassador)
- **Website**: nekocat.world
- **Game**: play.nekocat.world
- **Project**: NekoCat World
