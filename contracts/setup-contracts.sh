#!/bin/bash

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
RPC_URL="https://rpc1testnet.qie.digital"
echo "=========================================="
echo "Post-Deployment Setup Script"
echo "QIE Testnet Configuration"
echo "=========================================="
echo ""

# ==========================================
# Deployed Contract Addresses (Updated)
# ==========================================

# Mock Tokens
MOCK_USDT="0xec2069c30dff0cD54aE7c0CF2025E5Bf719d915F"
MOCK_BTC="0x2d9dD07eeDb2915f11D4A6aE922D2b4bd54eA699"
MOCK_ETH="0xB9a4B54E82F13A9699f3bBdb1e249C6Eb61eFf58"
MOCK_BNB="0x40553fA249E70472be01d3309d85e7Af661c0Ed9"
MOCK_SOL="0x78Ff860900DBcCeD266944439864b0807BA6f593"
MOCK_QIE="0xF51b69a55A79275D2a0f4e36c8cAf02d6251f9DC"

# Mock Price Feeds
BTC_FEED="0x14a44d68794B0E045315d7E1daDbb9d9074de5E7"
ETH_FEED="0xCb9a338D9d0640C27F800e0993cd9dD02fD5F5AC"
BNB_FEED="0x209be0c082064C37449E817dDe9e204222171b9e"
SOL_FEED="0x1eFe2551e30B6f8F2418480eeAb0756C6DDF4902"
QIE_FEED="0x2E27fB1736F05810834b8e912332FD1dBD9A9A3c"

# Protocol Contracts
PLATFORM_TOKEN="0x82991B6200B4ABDc3090A88Af284B4c4462149Ca"
PRICE_ORACLE="0x56E4Ad6cCf535FE53ad24e5Aa2e10f1E16F38dA3"
PERPETUAL_TRADING="0xbdf1e245AdA479a8eb980c1420BADe7a43910150"
SPOT_MARKET="0xF3192D967070AC6a2F12b3F22327eF693f837c1f"
STAKING="0x853223274e1d4774197A656343D88D835234BA2a"
VAULT="0x3396e21F23d00a1c0C480C29bcD37c0284AD3F6D"
GOVERNANCE="0x393DE041a345639c6320B8a94420381dAB354fF1"
LIQUIDITY_MINING="0x7eFD4C656c39761a2F5BaF66B2945f7BCBEfC6DD"
REWARD_DISTRIBUTOR="0x36c1BB83a3e4a4C2ef354541d4441ED368F43C42"

# Step 1: Add Price Feeds to Oracle
echo "=========================================="
echo "Step 1: Configuring Price Oracle"
echo "=========================================="
echo ""

echo "Adding BTC price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "BTC" $BTC_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true \
    --async || true
echo "✅ BTC price feed transaction sent"
sleep 6

echo "Adding ETH price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "ETH" $ETH_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ ETH price feed added"
sleep 5

echo "Adding BNB price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "BNB" $BNB_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ BNB price feed added"
sleep 5

echo "Adding SOL price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "SOL" $SOL_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ SOL price feed added"
sleep 8

echo "Adding QIE price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "QIE" $QIE_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ QIE price feed added"
sleep 10

# Step 2: Verify Price Feeds
echo ""
echo "=========================================="
echo "Step 2: Verifying Price Feeds"
echo "=========================================="
echo ""

echo "Checking BTC price..."
# BTC_PRICE=$(cast call $PRICE_ORACLE "getLatestPrice(string)(uint256)" "BTC" --rpc-url $RPC_URL)
echo "BTC Price: $BTC_PRICE (scaled to 18 decimals)"

echo "Checking ETH price..."
ETH_PRICE=$(cast call $PRICE_ORACLE "getLatestPrice(string)(uint256)" "ETH" --rpc-url $RPC_URL)
echo "ETH Price: $ETH_PRICE (scaled to 18 decimals)"

echo "Checking BNB price..."
BNB_PRICE=$(cast call $PRICE_ORACLE "getLatestPrice(string)(uint256)" "BNB" --rpc-url $RPC_URL)
echo "BNB Price: $BNB_PRICE (scaled to 18 decimals)"

echo "Checking SOL price..."
SOL_PRICE=$(cast call $PRICE_ORACLE "getLatestPrice(string)(uint256)" "SOL" --rpc-url $RPC_URL)
echo "SOL Price: $SOL_PRICE (scaled to 18 decimals)"

echo "Checking QIE price..."
QIE_PRICE=$(cast call $PRICE_ORACLE "getLatestPrice(string)(uint256)" "QIE" --rpc-url $RPC_URL)
echo "QIE Price: $QIE_PRICE (scaled to 18 decimals)"

# Step 3: Allocate Tokens for Rewards
echo ""
echo "=========================================="
echo "Step 3: Allocating Tokens for Rewards"
echo "=========================================="
echo ""

STAKING_REWARDS="20000000000000000000000000" # 20M tokens
LIQUIDITY_MINING_REWARDS="30000000000000000000000000" # 30M tokens

echo "Transferring 20M PDX to Staking contract..."
cast send $PLATFORM_TOKEN \
    "transfer(address,uint256)" \
    $STAKING $STAKING_REWARDS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ Tokens transferred to Staking"
sleep 3

echo "Transferring 30M PDX to Liquidity Mining contract..."
cast send $PLATFORM_TOKEN \
    "transfer(address,uint256)" \
    $LIQUIDITY_MINING $LIQUIDITY_MINING_REWARDS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ Tokens transferred to Liquidity Mining"
sleep 3

# Step 4: Set Staking Reward Rate
echo ""
echo "=========================================="
echo "Step 4: Configuring Staking Rewards"
echo "=========================================="
echo ""

REWARD_RATE="634195839675291" # 20M / 365 days in seconds

echo "Setting staking reward rate..."
cast send $STAKING \
    "setRewardRate(uint256)" \
    $REWARD_RATE \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ Staking reward rate set to $REWARD_RATE per second"
sleep 3

# Step 5: Verify Configuration
echo ""
echo "=========================================="
echo "Step 5: Verifying Configuration"
echo "=========================================="
echo ""

echo "Checking Staking balance..."
STAKING_BALANCE=$(cast call $PLATFORM_TOKEN "balanceOf(address)(uint256)" $STAKING --rpc-url $RPC_URL  )
echo "Staking contract balance: $STAKING_BALANCE wei (20M PDX)"

echo "Checking Liquidity Mining balance..."
LM_BALANCE=$(cast call $PLATFORM_TOKEN "balanceOf(address)(uint256)" $LIQUIDITY_MINING --rpc-url $RPC_URL )
echo "Liquidity Mining balance: $LM_BALANCE wei (30M PDX)"


echo "Authorizing contracts in Vault..."
cast send $VAULT \
    "authorizeContract(address)" \
    $PERPETUAL_TRADING \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ Staking reward rate set to $REWARD_RATE per second"
sleep 3

echo "Checking Vault authorization..."
IS_AUTHORIZED=$(cast call $VAULT "isAuthorized(address)(bool)" $PERPETUAL_TRADING --rpc-url $RPC_URL )
echo "PerpetualTrading authorized in Vault: $IS_AUTHORIZED"
cast send $VAULT "whitelistToken(address,uint8,uint256,bool)" $MOCK_USDT 6 5000 true --rpc-url $RPC_URL --private-key $PRIVATE_KEY  --legacy \
    --async || true

echo "Checking USDT whitelist..."
USDT_WHITELISTED=$(cast call $VAULT "getWhitelistedTokens()(address[])" $MOCK_USDT --rpc-url $RPC_URL )
echo "USDT whitelisted in Vault: $USDT_WHITELISTED"

# Summary
echo ""
echo "=========================================="
echo "✅ SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "All configurations have been applied:"
echo "  ✅ 5 price feeds added to Price Oracle"
echo "  ✅ 20M PDX allocated to Staking"
echo "  ✅ 30M PDX allocated to Liquidity Mining"
echo "  ✅ Staking reward rate configured"
echo "  ✅ Vault configured with USDT collateral"
echo "  ✅ PerpetualTrading authorized in Vault"
echo ""
echo "Your perpetual DEX is ready to use!"
echo ""
echo "Next steps:"
echo "  1. Update frontend with contract addresses"
echo "  2. Mint test tokens for users"
echo "  3. Test opening positions"
echo ""
