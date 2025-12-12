# GMX-Style Perpetual DEX - Deployment Guide

## Overview

This is a comprehensive GMX-style perpetual DEX built on Base chain with:
- Perpetual futures trading (BTC, ETH) with up to 50x leverage
- Spot market AMM with liquidity pools
- Platform token (PDX) with governance and staking
- Liquidity mining incentives
- Chainlink price feeds for reliable oracle data

## Smart Contracts

### Core Contracts

1. **PlatformToken.sol** - ERC20 governance token
   - Symbol: PDX
   - Max Supply: 1 billion tokens
   - Mintable (owner only)
   - Burnable

2. **PriceOracle.sol** - Chainlink price feed integration
   - BTC/USD feed: `0x64c911848F3f3681CEDF1C79c3A2e9255a7E5F1A`
   - ETH/USD feed: `0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70`
   - Staleness checks
   - Supports multiple assets

3. **PerpetualTrading.sol** - Perpetual futures
   - Long/Short positions
   - 2x to 50x leverage
   - Funding rates
   - Liquidation mechanism (80% threshold)
   - 0.1% trading fee

4. **SpotMarket.sol** - AMM-based spot trading
   - Constant product formula (x * y = k)
   - LP tokens with transfer support
   - 0.3% trading fee
   - Pool creation and liquidity management

5. **Vault.sol** - Central liquidity vault
   - VLP tokens for liquidity providers
   - Multi-token support
   - Fee collection and distribution
   - Position collateral management

6. **Staking.sol** - Token staking with rewards
   - Multiple lock periods (0, 30, 90, 180 days)
   - Reward multipliers (1x - 3x)
   - Time-weighted rewards

7. **Governance.sol** - On-chain governance
   - Token-weighted voting
   - 2-day timelock
   - Proposal threshold: 100k tokens
   - Quorum: 10M tokens
   - Guardian emergency controls

8. **LiquidityMining.sol** - LP incentives
   - Multiple pool support
   - Flexible allocation points
   - Early withdrawal penalty (2%)
   - Platform token rewards

9. **RewardDistributor.sol** - Fee distribution
   - 60% to VLP holders
   - 20% to stakers
   - 10% to treasury
   - 10% to buyback

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js v18+
- Git

## Installation

```bash
# Clone repository
git clone <your-repo-url>
cd perp

# Install contract dependencies
cd contracts
forge install

# Build contracts
forge build

# Run tests
forge test
```

## Configuration

1. Copy the environment template:
```bash
cd contracts
cp .env.example .env
```

2. Fill in your `.env` file:
```env
PRIVATE_KEY=your_private_key_here
BASE_RPC_URL=https://mainnet.base.org
BASESCAN_API_KEY=your_basescan_api_key
COLLATERAL_TOKEN=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913  # USDC on Base
FEE_RECIPIENT=your_address
TREASURY=your_treasury_address
GUARDIAN=your_guardian_address
```

## Deployment

### Base Mainnet Deployment

```bash
# Dry run (simulation)
forge script script/DeployQIETestnet.s.sol --rpc-url qie_tesnet --sender <your-address>

# Actual deployment
forge script script/Deploy.s.sol --rpc-url base --broadcast --verify --sender <your-address>
```

### Base Sepolia Testnet Deployment

```bash
# Deploy to testnet
forge script script/Deploy.s.sol --rpc-url qie --broadcast --verify

# Note: You'll need to deploy or get testnet USDC first
```

### Deployment Output

After deployment, contract addresses will be saved to:
```
contracts/deployments/8453.json  # Base Mainnet
contracts/deployments/84532.json # Base Sepolia
```

## Post-Deployment Setup

### 1. Create Spot Market Pools

```solidity
// Example: Create USDC/WETH pool
SpotMarket spotMarket = SpotMarket(<deployed_address>);

// Users need to approve tokens first
IERC20(usdc).approve(address(spotMarket), amount);
IERC20(weth).approve(address(spotMarket), amount);

// Create pool
spotMarket.createPool(usdc, weth, usdcAmount, wethAmount);
```

### 2. Add Liquidity Mining Pools

```solidity
LiquidityMining liquidityMining = LiquidityMining(<deployed_address>);

// Add pool with allocation points
liquidityMining.addPool(spotPoolId, 1000); // 1000 allocation points
```

### 3. Fund Reward Contracts

```solidity
// Transfer tokens for staking rewards
PlatformToken token = PlatformToken(<deployed_address>);
token.transfer(address(staking), 20_000_000 * 1e18);

// Transfer tokens for liquidity mining
token.transfer(address(liquidityMining), 30_000_000 * 1e18);

// Approve reward distributor
token.approve(address(rewardDistributor), type(uint256).max);
```

### 4. Whitelist Additional Tokens in Vault

```solidity
Vault vault = Vault(<deployed_address>);

// Whitelist WETH
vault.whitelistToken(
    wethAddress,
    18,           // decimals
    5000,         // 50% weight
    false         // not stablecoin
);
```

## Usage Examples

### Opening a Perpetual Position

```solidity
PerpetualTrading perp = PerpetualTrading(<deployed_address>);

// Approve collateral (USDC)
IERC20(usdc).approve(address(perp), collateralAmount);

// Open 10x long BTC position with 1000 USDC collateral
perp.openPosition("BTC", true, 1000 * 1e6, 10);
```

### Adding Liquidity to Spot Market

```solidity
SpotMarket spotMarket = SpotMarket(<deployed_address>);

// Approve tokens
IERC20(tokenA).approve(address(spotMarket), amountA);
IERC20(tokenB).approve(address(spotMarket), amountB);

// Add liquidity
spotMarket.addLiquidity(
    poolId,
    amountADesired,
    amountBDesired,
    amountAMin,
    amountBMin
);
```

### Staking Platform Tokens

```solidity
Staking staking = Staking(<deployed_address>);

// Approve platform token
PlatformToken(pdx).approve(address(staking), amount);

// Stake with 90-day lock (2x multiplier)
staking.stake(amount, 2); // lockConfigId = 2
```

### Depositing LP Tokens for Mining

```solidity
LiquidityMining mining = LiquidityMining(<deployed_address>);

// Approve LP tokens
spotMarket.approveLP(poolId, address(mining), lpAmount);

// Deposit to mining pool
mining.deposit(miningPoolId, lpAmount);
```

## Contract Verification

Contracts are automatically verified during deployment if `BASESCAN_API_KEY` is set. To verify manually:

```bash
forge verify-contract <contract_address> <contract_name> --chain base --watch
```

## Security Considerations

1. **Guardian Role**: The guardian can cancel governance proposals. Use a multisig.
2. **Owner Permissions**: Contract owners have significant privileges. Transfer to multisig after deployment.
3. **Price Feeds**: Monitor Chainlink oracles for freshness and accuracy.
4. **Liquidations**: Ensure liquidation bots are running to maintain system health.
5. **Testing**: Thoroughly test on testnet before mainnet deployment.

## Auditing

Before mainnet deployment:
1. Complete internal code review
2. Run static analysis tools (Slither, Mythril)
3. Conduct professional smart contract audit
4. Implement bug bounty program

## Monitoring

Monitor these key metrics:
- Total Value Locked (TVL)
- Open interest per asset
- Liquidation events
- Fee generation
- Oracle price updates
- Governance proposals

## Support & Resources

- Base Documentation: https://docs.base.org
- Chainlink Feeds: https://docs.chain.link/data-feeds/price-feeds/addresses/?network=base
- Foundry Book: https://book.getfoundry.sh/

## License

MIT License - See LICENSE file for details



Mock Tokens:
    Mock USDT: 0xEEccAA0ED2Bde4D9489f5caa0B4022FE7cF964d1
    Mock BTC: 0x9FD52e95D6da493aBd8c60ff0D9915cAe62D97D7
    Mock ETH: 0x3eCA665997892aAe512A2e38a1F924a9991c678B
    Mock BNB: 0x1F3Efc60eFB204945Ed3d0D07B4058923577Fbed
    Mock SOL: 0xF78cbd33716c65544E3f1f100D5ecBE9843bdB0b
    Mock QIE: 0x15C89Ef2e96C43b0b450E4C9834Fe661CaC5d84C

Mock Price Feeds:
    BTC Feed: 0x63F143de8B970B50002f114bc30de525AdA076b0
    ETH Feed: 0x9eE3DE542E32ee05499dde037DE329F7fEd106cE
    BNB Feed: 0x4D918D30722C5ee4F47696f636065358bf9F01D8
    SOL Feed: 0x8062202Dcea277cd354cf99043b761113192eF33
    QIE Feed: 0x452Fc86D91620F1D23e07F02220ac2014B3d7ca7

Protocol Contracts:
    PlatformToken (PDX): 0x9D2bb4e81dEf80164C5DBAdd59D5c2E658791d4C
    PriceOracle: 0x5a03E0b3F14feF38C86acA2Af381a717ffAcd005
    PerpetualTrading: 0xf071e080dc3A91FD9720Fe8B0E65BeA605F83499
    SpotMarket: 0x2afF5e7dEFd620570a7AA7eB588DBc1149B0c94E
    Staking: 0xA683144f52Cffb171962E2E04fF8C55CfA73C567
    Vault: 0xA2139eDE2DBBC5Ae592D99724C4Fe5ed1e44BCDC
    Governance: 0x27aCE3BC6E548b0b5e0e566971f41a91bb202E2E
    LiquidityMining: 0x61F5d89830e5100eE2FD5D7A78E13B0e8f2F2cdA
    RewardDistributor: 0xB625236A5ED7098a467F0676650038FaDFf22076
  ========================================

  Deployment addresses saved to: ./deployments/qie-testnet-1991.json

========================================
  NEXT STEPS - TESTNET
  ========================================
  1. Mint mock tokens for testing:
     mockUSDT.mint(yourAddress, amount)
     mockBTC.mint(you