#!/bin/bash

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"

# Deployed Price Feed Addresses (Tenderly Fork)
BTC_FEED="0xD7Fc335A6b6b22dFEb47eBc3eF5801af8be87d69"
ETH_FEED="0x75c352dcD4fFd48aA7A35C55d570D3A0a6EdbF63"
BNB_FEED="0x70b3cA9e5551e7Ed615F3dc03d190801A1cE8Eb5"
SOL_FEED="0x825e3F3D150A323c7004576653CFd2b607875645"
QIE_FEED="0xe0591Ef7F28826297BA99Fe5EDFaFcE06e95DA06"

# Get current timestamp
CURRENT_TIME=$(cast block latest --rpc-url $RPC_URL --field timestamp)
ROUND_ID=$((CURRENT_TIME))

echo "=========================================="
echo "Updating Price Feeds on Tenderly Fork"
echo "=========================================="
echo "Current Timestamp: $CURRENT_TIME"
echo "Round ID: $ROUND_ID"
echo ""

# BTC Price: $43,000 (8 decimals)
echo "Updating BTC price feed..."
BTC_PRICE="4300000000000"
cast send $BTC_FEED \
    "updateRoundData(uint80,int256,uint256,uint256)" \
    $ROUND_ID $BTC_PRICE $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ BTC price updated to $43,000"
sleep 2

# ETH Price: $2,300 (8 decimals)
echo "Updating ETH price feed..."
ETH_PRICE="230000000000"
cast send $ETH_FEED \
    "updateRoundData(uint80,int256,uint256,uint256)" \
    $ROUND_ID $ETH_PRICE $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ ETH price updated to $2,300"
sleep 2

# BNB Price: $310 (8 decimals)
echo "Updating BNB price feed..."
BNB_PRICE="31000000000"
cast send $BNB_FEED \
    "updateRoundData(uint80,int256,uint256,uint256)" \
    $ROUND_ID $BNB_PRICE $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ BNB price updated to $310"
sleep 2

# SOL Price: $95 (8 decimals)
echo "Updating SOL price feed..."
SOL_PRICE="9500000000"
cast send $SOL_FEED \
    "updateRoundData(uint80,int256,uint256,uint256)" \
    $ROUND_ID $SOL_PRICE $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ SOL price updated to $95"
sleep 2

# QIE Price: $1 (8 decimals)
echo "Updating QIE price feed..."
QIE_PRICE="100000000"
cast send $QIE_FEED \
    "updateRoundData(uint80,int256,uint256,uint256)" \
    $ROUND_ID $QIE_PRICE $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
echo "✅ QIE price updated to $1"

echo ""
echo "=========================================="
echo "✅ All price feeds updated successfully!"
echo "=========================================="
