# GMX-Style Perpetual DEX - QIE Blockchain Deployment Guide

## Overview

This guide covers deploying the GMX-style perpetual DEX on QIE Blockchain (Chain ID: 1990).

## QIE Network Details

- **Network Name**: QIE Mainnet
- **RPC URL**: `https://rpc5mainnet.qie.digital`
- **Chain ID**: `1990`
- **Currency Symbol**: QIE
- **Block Explorer**: `https://mainnet.qie.digital`

## Price Oracle Verification Results

✅ **All price feeds verified and operational!**

| Asset | Price Feed Address | Status | Latest Price |
|-------|-------------------|--------|--------------|
| BTC/USD | `0x9E596d809a20A272c788726f592c0d1629755440` | ✅ Fresh | ~$90,484 |
| ETH/USD | `0x4bb7012Fbc79fE4Ae9B664228977b442b385500d` | ✅ Fresh | ~$3,136 |
| XRP/USD | `0x804582B1f8Fea73919e7c737115009f668f97528` | ✅ Fresh | ~$2.08 |
| SOL/USD | `0xe86999c8e6C8eeF71bebd35286bCa674E0AD7b21` | ✅ Fresh | ~$133 |
| QIE/USD | `0x3Bc617cF3A4Bb77003e4c556B87b13D556903D17` | ⚠️ 2h old | ~$0.039 |
| BNB/USD | `0x775A56117Fdb8b31877E75Ceeb68C96765b031e6` | ⚠️ 12h old | ~$897 |
| XAUt/USD | `0x9aD0199a67588ee293187d26bA1BE61cb07A214c` | ⚠️ 4h old | ~$4,197 |

**Note**: BTC, ETH, XRP, and SOL have the freshest data (< 1 hour). Consider these for initial perpetual trading pairs.

## Prerequisites

1. **Foundry Installed**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Node.js & NPM** (v18+)

3. **QIE Wallet with Funds**
   - Get QIE tokens for gas
   - Get USDT or stablecoin for collateral

## Step 1: Environment Setup

Create `.env` file in `contracts` directory:

```bash
cd contracts
cp .env.example .env
```

Edit `.env`:

```env
# Your deployer private key (DO NOT COMMIT THIS!)
PRIVATE_KEY=your_private_key_here

# QIE Network RPC
QIE_RPC_URL=https://rpc5mainnet.qie.digital

# Collateral token on QIE (USDT or other stablecoin)
COLLATERAL_TOKEN_QIE=0xYourUSDTAddressOnQIE

# Fee and treasury addresses
FEE_RECIPIENT=your_fee_recipient_address
TREASURY=your_treasury_address
GUARDIAN=your_guardian_address
```

## Step 2: Verify Price Oracles

Before deployment, verify all price feeds are working:

```bash
cd scripts
npm install
node verifyPriceOracle.js
```

Expected output: All feeds should return prices successfully (some may show staleness warnings).

## Step 3: Build Contracts

```bash
cd contracts
forge build
```

Ensure all contracts compile without errors.

## Step 4: Deploy to QIE Mainnet

### Dry Run (Simulation)

```bash
forge script script/DeployQIE.s.sol --rpc-url qie --sender <your-address>
```

### Actual Deployment

```bash
forge script script/DeployQIE.s.sol \
  --rpc-url qie \
  --broadcast \
  --legacy \
  -vvvv
```

**Note**: Use `--legacy` flag if you encounter EIP-1559 issues.

### Expected Output

```
========================================
DEPLOYMENT SUMMARY - QIE BLOCKCHAIN
========================================
PlatformToken (PDX): 0x...
PriceOracle: 0x...
PerpetualTrading: 0x...
SpotMarket: 0x...
Staking: 0x...
Vault: 0x...
Governance: 0x...
LiquidityMining: 0x...
RewardDistributor: 0x...
========================================
```

Deployment addresses will be saved to `contracts/deployments/qie-1990.json`.

## Step 5: Verify Contracts on QIE Explorer

Manually verify each contract on https://mainnet.qie.digital

Example for PlatformToken:
1. Go to contract address on explorer
2. Click "Verify & Publish"
3. Upload flattened source code or use standard JSON input
4. Select compiler version: `0.8.29`
5. Enable optimization: `Yes` with `200` runs
6. Use `via-ir`: `Yes`

## Step 6: Configure Additional Price Feeds (Optional)

If you want to add more assets:

```bash
cast send <PRICE_ORACLE_ADDRESS> \
  "addPriceFeed(string,address,uint8,uint256)" \
  "ASSET" \
  0xOracleAddress \
  8 \
  3600 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

## Step 7: Create Trading Pools

### Create Spot Market Pools

Example: Create USDT/QIE pool

```bash
# Approve tokens
cast send <USDT_ADDRESS> \
  "approve(address,uint256)" \
  <SPOT_MARKET_ADDRESS> \
  $(cast to-wei 10000 ether) \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

cast send <QIE_TOKEN_ADDRESS> \
  "approve(address,uint256)" \
  <SPOT_MARKET_ADDRESS> \
  $(cast to-wei 1000000 ether) \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

# Create pool
cast send <SPOT_MARKET_ADDRESS> \
  "createPool(address,address,uint256,uint256)" \
  <USDT_ADDRESS> \
  <QIE_TOKEN_ADDRESS> \
  $(cast to-wei 10000 6) \
  $(cast to-wei 1000000 ether) \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

### Add Liquidity Mining Pool

```bash
cast send <LIQUIDITY_MINING_ADDRESS> \
  "addPool(uint256,uint256)" \
  1 \
  1000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

## Step 8: Test Perpetual Trading

### Open a BTC Long Position

```bash
# Approve collateral
cast send <COLLATERAL_TOKEN> \
  "approve(address,uint256)" \
  <PERPETUAL_TRADING_ADDRESS> \
  $(cast to-wei 1000 6) \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

# Open position
cast send <PERPETUAL_TRADING_ADDRESS> \
  "openPosition(string,bool,uint256,uint256)" \
  "BTC" \
  true \
  $(cast to-wei 1000 6) \
  10 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

## Step 9: Frontend Integration

Update frontend configuration with deployed addresses:

```typescript
// config/contracts.ts
export const contracts = {
  chainId: 1990,
  rpcUrl: 'https://rpc5mainnet.qie.digital',
  addresses: {
    platformToken: '0x...',
    priceOracle: '0x...',
    perpetualTrading: '0x...',
    spotMarket: '0x...',
    staking: '0x...',
    vault: '0x...',
    governance: '0x...',
    liquidityMining: '0x...',
    rewardDistributor: '0x...',
  }
};
```

## Supported Trading Pairs

Based on price feed freshness, recommended pairs:

### Perpetual Futures
- ✅ **BTC/USD** - Bitcoin (freshest feed)
- ✅ **ETH/USD** - Ethereum (freshest feed)
- ✅ **SOL/USD** - Solana (fresh feed)
- ✅ **XRP/USD** - Ripple (fresh feed)
- ⚠️ QIE/USD - Native token (2h update frequency)
- ⚠️ BNB/USD - Binance Coin (12h update frequency)

### Spot Markets
- Any ERC20 token pairs on QIE blockchain
- Recommended: USDT/QIE, WETH/USDT, WBTC/USDT

## Trading Features

### Perpetual Trading
- **Leverage**: 2x to 50x
- **Trading Fee**: 0.1% (10 basis points)
- **Liquidation Threshold**: 80%
- **Liquidation Fee**: 5%
- **Funding Rates**: Owner-controlled

### Spot Trading
- **Trading Fee**: 0.3% (30 basis points)
- **AMM Formula**: Constant product (x * y = k)
- **LP Tokens**: Transferable and stakeable

### Staking
- **Lock Periods**: None, 30, 90, 180 days
- **Multipliers**: 1x, 1.5x, 2x, 3x
- **Rewards**: Platform token (PDX)

### Governance
- **Proposal Threshold**: 100,000 PDX
- **Quorum**: 10,000,000 PDX
- **Voting Period**: ~7 days
- **Timelock**: 2 days

## Monitoring & Maintenance

### Check Price Feed Freshness

```bash
cd scripts
node verifyPriceOracle.js
```

Run this regularly to ensure price feeds are updating.

### Monitor Open Interest

```bash
cast call <PERPETUAL_TRADING_ADDRESS> \
  "totalOpenInterestLong(bytes32)" \
  $(cast keccak "BTC") \
  --rpc-url qie
```

### Update Funding Rates

```bash
cast send <PERPETUAL_TRADING_ADDRESS> \
  "updateFundingRate(string,int256)" \
  "BTC" \
  $(cast to-wei 0.0001 ether) \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

## Security Recommendations

1. **Transfer Ownership to Multisig**: After deployment, transfer contract ownership to a multisig wallet
2. **Guardian Setup**: Use a separate multisig for governance guardian
3. **Monitoring**: Set up alerts for:
   - Large liquidations
   - Stale price feeds
   - High open interest
   - Governance proposals
4. **Audits**: Complete professional smart contract audit before handling significant TVL
5. **Bug Bounty**: Implement bug bounty program

## Troubleshooting

### Price Feed Issues

**Problem**: Price feed returns stale data

**Solution**:
- Check QIE oracle documentation for feed update frequency
- Consider using alternative oracles
- Adjust `maxPriceAge` parameter

### Transaction Failures

**Problem**: Transactions revert

**Solutions**:
- Use `--legacy` flag for legacy transaction format
- Increase gas limit: `--gas-limit 5000000`
- Check collateral token approval
- Verify sufficient balance

### Deployment Failures

**Problem**: Deployment script fails

**Solutions**:
- Ensure `COLLATERAL_TOKEN_QIE` is set correctly
- Check deployer has sufficient QIE for gas
- Verify RPC URL is accessible
- Use `-vvvv` flag for detailed logs

## Support & Resources

- **QIE Documentation**: Check QIE blockchain official docs
- **Explorer**: https://mainnet.qie.digital
- **RPC Status**: Monitor RPC uptime
- **Community**: Join QIE blockchain community channels

## Next Steps

1. ✅ Deploy contracts (completed)
2. ✅ Verify price oracles (completed)
3. 📋 Create spot market pools
4. 📋 Add liquidity mining incentives
5. 📋 Test perpetual trading
6. 📋 Deploy frontend
7. 📋 Security audit
8. 📋 Launch!

---

**Deployment Date**: [Your deployment date]
**Chain**: QIE Mainnet (1990)
**Version**: 1.0.0
