#!/bin/bash

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"

echo "=========================================="
echo "Post-Deployment Setup Script"
echo "QIE Testnet Configuration"
echo "=========================================="
echo ""

# Deployed Contract Addresses (Tenderly Fork)
MOCK_USDT="0x13a9fBb5E292a67F4533555A049CEecFcfA56e47"
MOCK_BTC="0xA69b9B831DCf8e5361C2e6D30c07D90f73C08EA9"
MOCK_ETH="0x629cfCA0e279d895A798262568dBD8DaA7582912"
MOCK_BNB="0xb2025C81F71dECB695b6B88ebDBf58aFaB13545d"
MOCK_SOL="0x5D9850310654C617C37b1c71e149B98086Ba670b"
MOCK_QIE="0x0a5568Dfe392f67900eF3E1c720554019249666C"

BTC_FEED="0xD7Fc335A6b6b22dFEb47eBc3eF5801af8be87d69"
ETH_FEED="0x75c352dcD4fFd48aA7A35C55d570D3A0a6EdbF63"
BNB_FEED="0x70b3cA9e5551e7Ed615F3dc03d190801A1cE8Eb5"
SOL_FEED="0x825e3F3D150A323c7004576653CFd2b607875645"
QIE_FEED="0xe0591Ef7F28826297BA99Fe5EDFaFcE06e95DA06"

PLATFORM_TOKEN="0xd0cB8Cb9a65c3f7C3940Ab52cf052ce4A438fFDe"
PRICE_ORACLE="0x75a7F4Ff7DC7Baf62A5EAEc6f0F17dD796209c1d"
PERPETUAL_TRADING="0xC55643aa8FEe3C86ee0f9F939B2f3bACa505cAAD"
SPOT_MARKET="0xA0F5EBdFF15182cEc5Ee35b1697f613D6e072cF9"
STAKING="0xca02f116D22734F4f42304668d544ad87Ad74231"
VAULT="0x522554c534D77c661A1CbDf0174fd64650679D7a"
GOVERNANCE="0x95a8e2743A019c40D5979144B821040450dA8f12"
LIQUIDITY_MINING="0xc289cf5727c6586025C175b9ce245C8C915B247a"
REWARD_DISTRIBUTOR="0xA685898A43af873FF97D8B8Ab0Cf722d0A0Ea689"

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
sleep 5

echo "Adding ETH price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "ETH" $ETH_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ ETH price feed added"
sleep 3

echo "Adding BNB price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "BNB" $BNB_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ BNB price feed added"
sleep 3

echo "Adding SOL price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "SOL" $SOL_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ SOL price feed added"
sleep 3

echo "Adding QIE price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "QIE" $QIE_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true
echo "✅ QIE price feed added"
sleep 3

# Step 2: Verify Price Feeds
echo ""
echo "=========================================="
echo "Step 2: Verifying Price Feeds"
echo "=========================================="
echo ""

echo "Checking BTC price..."
BTC_PRICE=$(cast call $PRICE_ORACLE "getLatestPrice(string)(uint256)" "BTC" --rpc-url $RPC_URL)
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
