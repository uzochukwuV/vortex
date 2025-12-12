#!/bin/bash

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
USER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)

echo "=========================================="
echo "Test: Open Position on Tenderly Fork"
echo "=========================================="
echo ""

# Deployed Contract Addresses (Tenderly Fork)
MOCK_USDT="0x13a9fBb5E292a67F4533555A049CEecFcfA56e47"
BTC_FEED="0xD7Fc335A6b6b22dFEb47eBc3eF5801af8be87d69"
PRICE_ORACLE="0x75a7F4Ff7DC7Baf62A5EAEc6f0F17dD796209c1d"
PERPETUAL_TRADING="0xC55643aa8FEe3C86ee0f9F939B2f3bACa505cAAD"
VAULT="0x522554c534D77c661A1CbDf0174fd64650679D7a"

echo "User: $USER_ADDRESS"
echo ""

# Test Parameters
COLLATERAL_AMOUNT="10000000"  # 10 USDT (6 decimals)
LEVERAGE="10"
ASSET="BTC"

echo "=========================================="
echo "Step 1: Mint USDT Tokens"
echo "=========================================="
echo ""

echo "Minting 10,000 USDT..."
cast send $MOCK_USDT \
    "mintTo(uint256)" \
    "10000000000" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

echo "✅ USDT minted"
echo ""

echo "=========================================="
echo "Step 2: Approve USDT for Trading"
echo "=========================================="
echo ""

echo "Approving USDT..."
cast send $MOCK_USDT \
    "approve(address,uint256)" \
    $PERPETUAL_TRADING \
    "115792089237316195423570985008687907853269984665640564039457584007913129639935" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

echo "✅ USDT approved"
echo ""

echo "=========================================="
echo "Step 3: Update BTC Price Feed"
echo "=========================================="
echo ""

CURRENT_TIME=$(cast block latest --rpc-url $RPC_URL --field timestamp)
BTC_PRICE="4900000000000"  # $49,000
ROUND_ID=$CURRENT_TIME

echo "Updating BTC price to \$49,000..."
cast send $BTC_FEED \
    "updateRoundData(uint80,int256,uint256,uint256)" \
    $ROUND_ID $BTC_PRICE $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

echo "✅ Price updated"
sleep 2
echo ""

echo "=========================================="
echo "Step 4: Add Liquidity to Vault"
echo "=========================================="
echo ""

echo "Adding 5,000 USDT liquidity to vault..."
cast send $VAULT \
    "addLiquidity(address,uint256)" \
    $MOCK_USDT \
    "5000000000" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

echo "✅ Liquidity added"
echo ""

echo "=========================================="
echo "Step 5: Open Position"
echo "=========================================="
echo ""

echo "Opening BTC LONG position:"
echo "  Collateral: 10 USDT"
echo "  Leverage: 10x"
echo "  Position Size: 100 USD"
echo ""

cast send $PERPETUAL_TRADING \
    "openPosition(string,bool,uint256,uint256)" \
    "$ASSET" \
    true \
    $COLLATERAL_AMOUNT \
    $LEVERAGE \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

echo "✅ Position opened!"
echo ""

echo "=========================================="
echo "Step 6: Check Positions"
echo "=========================================="
echo ""

echo "Fetching user positions..."
POSITIONS=$(cast call $PERPETUAL_TRADING \
    "getUserPositions(address)(uint256[])" \
    $USER_ADDRESS \
    --rpc-url $RPC_URL)

echo "Position IDs: $POSITIONS"
echo ""

echo "=========================================="
echo "✅ Test Complete!"
echo "=========================================="
echo ""
echo "Monitor on Tenderly:"
echo "https://dashboard.tenderly.co/explorer/vnet/23772913/tx"
