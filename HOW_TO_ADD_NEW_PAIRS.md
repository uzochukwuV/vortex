# How to Add New Trading Pairs

## Overview

This guide explains how perpetual and spot markets work in our GMX-style DEX and how to add new trading pairs when price feeds become available.

## Understanding the Architecture

### 1. Perpetual Trading (Futures)

**Key Points:**
- Perpetual positions are **NOT pre-created** - they are dynamic
- Any asset with a price feed in the PriceOracle can be traded
- No pool creation required for perpetuals
- Uses a single collateral token (USDT/USDC) for all pairs

**How it Works:**
```solidity
// User opens BTC perpetual position
perpetualTrading.openPosition("BTC", true, 1000e6, 10);

// Behind the scenes:
// 1. Gets BTC price from PriceOracle.getLatestPrice("BTC")
// 2. Creates position with that price
// 3. Tracks open interest per asset
// 4. No liquidity pool needed!
```

### 2. Spot Market (AMM Pools)

**Key Points:**
- Each trading pair needs a **liquidity pool**
- Pools are created by users (permissionless)
- Uses constant product formula (Uniswap V2 style)
- Each pool has its own LP tokens

**How it Works:**
```solidity
// User creates WETH/USDT pool
spotMarket.createPool(weth, usdt, 10e18, 30000e6);

// Creates:
// - Pool ID: 1
// - LP tokens for liquidity providers
// - Enables WETH <-> USDT swaps
```

---

## How to Add New Perpetual Trading Pairs

### Step 1: Add Price Feed to Oracle

**Option A: Already in Constructor (QIE Blockchain)**

Our PriceOracle already supports:
- ✅ BTC/USD
- ✅ ETH/USD
- ✅ SOL/USD
- ✅ XRP/USD
- ✅ BNB/USD
- ✅ QIE/USD

**These work immediately after deployment!**

**Option B: Add New Price Feed Manually**

If you have a new Chainlink oracle address:

```bash
# Example: Add AVAX/USD price feed
cast send <PRICE_ORACLE_ADDRESS> \
  "addPriceFeed(string,address,uint8,uint256)" \
  "AVAX" \
  0xAVAXOracleAddressOnQIE \
  8 \
  3600 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

Parameters:
- `"AVAX"` - Asset symbol (used in trading)
- `0x...` - Chainlink price feed address
- `8` - Decimals (usually 8 for Chainlink)
- `3600` - Max price age in seconds (1 hour)

### Step 2: Open Positions (No Additional Setup Needed!)

Once the price feed is added, users can immediately trade:

```bash
# Open AVAX long position
cast send <PERPETUAL_TRADING_ADDRESS> \
  "openPosition(string,bool,uint256,uint256)" \
  "AVAX" \
  true \
  1000000000 \
  10 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

**That's it!** No pool creation, no liquidity needed.

### Step 3: (Optional) Set Funding Rate

Set funding rate for the new asset:

```bash
cast send <PERPETUAL_TRADING_ADDRESS> \
  "updateFundingRate(string,int256)" \
  "AVAX" \
  100000000000000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

---

## How to Add New Spot Market Pairs

### Step 1: Ensure Tokens Exist

Make sure both tokens are ERC20 contracts on QIE blockchain.

Example pairs:
- USDT/WETH
- WBTC/USDT
- QIE/USDT
- Any token pair!

### Step 2: Create Pool

Anyone can create a pool (permissionless):

```bash
# Approve both tokens
cast send <TOKEN_A> \
  "approve(address,uint256)" \
  <SPOT_MARKET_ADDRESS> \
  <AMOUNT_A> \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

cast send <TOKEN_B> \
  "approve(address,uint256)" \
  <SPOT_MARKET_ADDRESS> \
  <AMOUNT_B> \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

# Create pool
cast send <SPOT_MARKET_ADDRESS> \
  "createPool(address,address,uint256,uint256)" \
  <TOKEN_A> \
  <TOKEN_B> \
  <AMOUNT_A> \
  <AMOUNT_B> \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

**Example: Create WETH/USDT Pool**

```bash
# 10 WETH + 30,000 USDT
cast send 0xWETH \
  "approve(address,uint256)" \
  0xSpotMarket \
  10000000000000000000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

cast send 0xUSDT \
  "approve(address,uint256)" \
  0xSpotMarket \
  30000000000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

cast send 0xSpotMarket \
  "createPool(address,address,uint256,uint256)" \
  0xWETH \
  0xUSDT \
  10000000000000000000 \
  30000000000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

### Step 3: (Optional) Add Liquidity Mining Rewards

Incentivize liquidity providers:

```bash
# Get pool ID from createPool transaction logs
POOL_ID=1

# Add to liquidity mining with 1000 allocation points
cast send <LIQUIDITY_MINING_ADDRESS> \
  "addPool(uint256,uint256)" \
  $POOL_ID \
  1000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

---

## Comparison: Perpetuals vs Spot

| Feature | Perpetuals | Spot Markets |
|---------|-----------|--------------|
| **Setup Required** | Just add price feed | Create liquidity pool |
| **Liquidity** | Not needed (uses collateral) | Required (AMM pools) |
| **Leverage** | 2x - 50x | None (1x only) |
| **Collateral** | Single token (USDT) | Both tokens in pair |
| **Who Can Add** | Owner only (price feed) | Anyone (permissionless) |
| **Trading Fee** | 0.1% | 0.3% |
| **Price Source** | Chainlink oracle | AMM formula (x*y=k) |

---

## Complete Example: Adding SOL Trading

### Perpetual SOL/USD (Already Available!)

```bash
# 1. Verify price feed exists
cast call <PRICE_ORACLE_ADDRESS> \
  "getPriceFeedInfo(string)" \
  "SOL" \
  --rpc-url qie

# 2. Open SOL long position (10x leverage, 1000 USDT collateral)
cast send <PERPETUAL_TRADING_ADDRESS> \
  "openPosition(string,bool,uint256,uint256)" \
  "SOL" \
  true \
  1000000000 \
  10 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

### Spot SOL/USDT Pool

```bash
# 1. Deploy or get wrapped SOL token address
WSOL=0xWrappedSOLAddress
USDT=0xUSDTAddress

# 2. Create pool (100 SOL + 13,000 USDT)
# Approve tokens first
cast send $WSOL "approve(address,uint256)" <SPOT_MARKET> 100000000000000000000 --rpc-url qie --private-key $PRIVATE_KEY
cast send $USDT "approve(address,uint256)" <SPOT_MARKET> 13000000000 --rpc-url qie --private-key $PRIVATE_KEY

# Create pool
cast send <SPOT_MARKET_ADDRESS> \
  "createPool(address,address,uint256,uint256)" \
  $WSOL \
  $USDT \
  100000000000000000000 \
  13000000000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY

# 3. Add liquidity mining rewards
cast send <LIQUIDITY_MINING_ADDRESS> \
  "addPool(uint256,uint256)" \
  1 \
  2000 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

---

## Helper Scripts

### Check Available Perpetual Pairs

```bash
# scripts/listPerpetualAssets.js
const assets = ["BTC", "ETH", "SOL", "XRP", "BNB", "QIE"];

for (const asset of assets) {
  try {
    const feedInfo = await priceOracle.getPriceFeedInfo(asset);
    console.log(`✅ ${asset}: ${feedInfo.feedAddress}`);
  } catch {
    console.log(`❌ ${asset}: Not available`);
  }
}
```

### Check Available Spot Pools

```bash
# Get total pool count
cast call <SPOT_MARKET_ADDRESS> "poolCounter()" --rpc-url qie

# Get pool info
cast call <SPOT_MARKET_ADDRESS> \
  "getPoolInfo(uint256)" \
  1 \
  --rpc-url qie
```

---

## Important Notes

### Perpetual Trading

1. **No Pre-Configuration**: Assets don't need to be "whitelisted" - just add the price feed
2. **Instant Trading**: Once price feed is added, trading is immediately available
3. **Single Collateral**: All perpetuals use the same collateral token
4. **Dynamic Open Interest**: Tracked per asset automatically

### Spot Trading

1. **Permissionless**: Anyone can create any token pair pool
2. **Initial Liquidity**: Pool creator provides first liquidity
3. **LP Tokens**: Automatically minted for liquidity providers
4. **No Oracle Needed**: Prices determined by AMM formula

### Price Feed Requirements

For perpetual trading, you need:
- ✅ Chainlink-compatible price feed on QIE
- ✅ Regular updates (< 1 hour old recommended)
- ✅ 8 decimals (standard for Chainlink)
- ✅ Owner access to add feed

For spot trading, you need:
- ✅ ERC20 tokens on QIE blockchain
- ✅ Initial liquidity (both tokens)
- ✅ That's it!

---

## When New Oracle Feeds Become Available

### Scenario: QIE adds LINK/USD oracle

**Step 1**: Get oracle address from QIE documentation

**Step 2**: Add to PriceOracle

```bash
cast send <PRICE_ORACLE_ADDRESS> \
  "addPriceFeed(string,address,uint8,uint256)" \
  "LINK" \
  0xLINKOracleAddress \
  8 \
  3600 \
  --rpc-url qie \
  --private-key $PRIVATE_KEY
```

**Step 3**: Announce to community - LINK perpetuals now tradeable!

**Step 4**: (Optional) Create LINK/USDT spot pool for extra liquidity

---

## Frontend Integration

### Display Available Perpetual Pairs

```typescript
const SUPPORTED_ASSETS = ["BTC", "ETH", "SOL", "XRP", "BNB", "QIE"];

async function getActivePairs() {
  const active = [];

  for (const asset of SUPPORTED_ASSETS) {
    try {
      const info = await priceOracle.getPriceFeedInfo(asset);
      if (info.isActive) {
        const price = await priceOracle.getLatestPrice(asset);
        active.push({ asset, price, feed: info.feedAddress });
      }
    } catch (e) {
      console.log(`${asset} not available`);
    }
  }

  return active;
}
```

### Display Available Spot Pools

```typescript
async function getActivePools() {
  const poolCount = await spotMarket.poolCounter();
  const pools = [];

  for (let i = 1; i <= poolCount; i++) {
    const poolInfo = await spotMarket.getPoolInfo(i);
    if (poolInfo.isActive) {
      pools.push({
        poolId: i,
        tokenA: poolInfo.tokenA,
        tokenB: poolInfo.tokenB,
        reserveA: poolInfo.reserveA,
        reserveB: poolInfo.reserveB,
      });
    }
  }

  return pools;
}
```

---

## Summary

### Adding Perpetual Pairs (Futures)
1. ✅ Add price feed to PriceOracle (owner only)
2. ✅ That's it! Trading is immediately available

### Adding Spot Pairs (AMM)
1. ✅ Get both token addresses
2. ✅ Create pool with initial liquidity (anyone)
3. ✅ (Optional) Add liquidity mining rewards

**The key difference**: Perpetuals only need a price oracle, while spot markets need actual liquidity pools!
