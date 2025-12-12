#!/bin/bash

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"

echo "=========================================="
echo "Tenderly Fork Setup Script"
echo "=========================================="
echo ""

# Deployed Contract Addresses
MOCK_USDT="0x13a9fBb5E292a67F4533555A049CEecFcfA56e47"
BTC_FEED="0xD7Fc335A6b6b22dFEb47eBc3eF5801af8be87d69"
ETH_FEED="0x75c352dcD4fFd48aA7A35C55d570D3A0a6EdbF63"
BNB_FEED="0x70b3cA9e5551e7Ed615F3dc03d190801A1cE8Eb5"
SOL_FEED="0x825e3F3D150A323c7004576653CFd2b607875645"
QIE_FEED="0xe0591Ef7F28826297BA99Fe5EDFaFcE06e95DA06"

PLATFORM_TOKEN="0xd0cB8Cb9a65c3f7C3940Ab52cf052ce4A438fFDe"
PRICE_ORACLE="0x75a7F4Ff7DC7Baf62A5EAEc6f0F17dD796209c1d"
PERPETUAL_TRADING="0xC55643aa8FEe3C86ee0f9F939B2f3bACa505cAAD"
VAULT="0x522554c534D77c661A1CbDf0174fd64650679D7a"
STAKING="0xca02f116D22734F4f42304668d544ad87Ad74231"
REWARD_DISTRIBUTOR="0xA685898A43af873FF97D8B8Ab0Cf722d0A0Ea689"

echo "=========================================="
echo "Step 1: Add Price Feeds to Oracle"
echo "=========================================="
echo ""

echo "Adding BTC price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "BTC" $BTC_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ BTC price feed added"
sleep 2

echo "Adding ETH price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "ETH" $ETH_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ ETH price feed added"
sleep 2

echo "Adding BNB price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "BNB" $BNB_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ BNB price feed added"
sleep 2

echo "Adding SOL price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "SOL" $SOL_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ SOL price feed added"
sleep 2

echo "Adding QIE price feed..."
cast send $PRICE_ORACLE \
    "addPriceFeed(string,address,uint8,uint256)" \
    "QIE" $QIE_FEED 8 3600 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ QIE price feed added"
echo ""

echo "=========================================="
echo "Step 2: Configure Vault"
echo "=========================================="
echo ""

echo "Whitelisting USDT in Vault..."
cast send $VAULT \
    "whitelistToken(address,uint8,uint256,bool)" \
    $MOCK_USDT 6 5000 true \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ USDT whitelisted"
sleep 2

echo "Authorizing PerpetualTrading contract..."
cast send $VAULT \
    "authorizeContract(address)" \
    $PERPETUAL_TRADING \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ PerpetualTrading authorized"
echo ""

echo "=========================================="
echo "Step 3: Configure Staking & Rewards"
echo "=========================================="
echo ""

echo "Allocating tokens to Staking contract..."
cast send $PLATFORM_TOKEN \
    "transfer(address,uint256)" \
    $STAKING \
    "10000000000000000000000000" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ Tokens allocated to Staking"
sleep 2

echo "Adding USDT as reward token..."
cast send $REWARD_DISTRIBUTOR \
    "addRewardToken(address)" \
    $MOCK_USDT \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ USDT added as reward token"
echo ""

echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run: bash update-prices.sh  # To set current prices"
echo "2. Test the frontend - all should work now!"
