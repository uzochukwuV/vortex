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
echo "Test: Approve USDT & Open Position"
echo "QIE Testnet"
echo "=========================================="
echo ""

echo "Send 2eth to $USER_ADDRESS on Tenderly Fork if needed for gas fees."
cast send --value 2ether 0xa7793C5c4582C72B3aa5e78859d8Bd66998D43ce \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true

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

echo "User Address: $USER_ADDRESS"
echo "Mock USDT: $MOCK_USDT"
echo "PerpetualTrading: $PERPETUAL_TRADING"
echo ""

# Test Parameters
COLLATERAL_AMOUNT="10000000"  # 100 USDT (6 decimals)
LEVERAGE="10"                   # 10x leverage
ASSET="BTC"                     # Trading asset
IS_LONG="true"                  # true for Long, false for Short

echo "=========================================="
echo "Step 1: Checking USDT Balance"
echo "=========================================="
echo ""

USDT_BALANCE=$(cast call $MOCK_USDT "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $RPC_URL)
USDT_BALANCE_READABLE=$(echo "scale=2; $USDT_BALANCE / 1000000" )

echo "USDT Balance: $USDT_BALANCE_READABLE USDT"

if [ "$USDT_BALANCE" -lt "$COLLATERAL_AMOUNT" ]; then
    echo ""
    echo "❌ Insufficient USDT balance!"
    echo "Minting 10,000 USDT for testing..."

    cast send $MOCK_USDT \
        "mintTo(uint256)" \
        "10000000000000" \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY 

    echo "✅ Mint transaction sent. Waiting 5 seconds..."
    sleep 5

    # Check balance again
    USDT_BALANCE=$(cast call $MOCK_USDT "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $RPC_URL)
    USDT_BALANCE_READABLE=$(echo "scale=2; $USDT_BALANCE / 1000000")
    echo "New USDT Balance: $USDT_BALANCE_READABLE USDT"
fi

echo ""
echo "=========================================="
echo "Step 2: Checking Current Allowance"
echo "=========================================="
echo ""

CURRENT_ALLOWANCE=$(cast call $MOCK_USDT "allowance(address,address)(uint256)" $USER_ADDRESS $PERPETUAL_TRADING --rpc-url $RPC_URL)
ALLOWANCE_READABLE=$(echo "scale=2; $CURRENT_ALLOWANCE / 1000000")

echo "Current Allowance: $ALLOWANCE_READABLE USDT"

if [ "$CURRENT_ALLOWANCE" -lt "$COLLATERAL_AMOUNT" ]; then
    echo ""
    echo "=========================================="
    echo "Step 3: Approving USDT"
    echo "=========================================="
    echo ""

    # Approve maximum amount for convenience
    MAX_UINT256="115792089237316195423570985008687907853269984665640564039457584007913129639935"

    echo "Approving unlimited USDT for PerpetualTrading..."
    cast send $MOCK_USDT \
        "approve(address,uint256)" \
        $PERPETUAL_TRADING $MAX_UINT256 \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --legacy \
        --async || true

    echo "✅ Approval transaction sent. Waiting 5 seconds..."
    sleep 5

    # Verify approval
    CURRENT_ALLOWANCE=$(cast call $MOCK_USDT "allowance(address,address)(uint256)" $USER_ADDRESS $PERPETUAL_TRADING --rpc-url $RPC_URL)
    echo "New Allowance: $CURRENT_ALLOWANCE"
else
    echo "✅ Sufficient allowance already exists"
fi

echo ""
echo "=========================================="
echo "Step 4: Checking BTC Price"
echo "=========================================="
echo ""

# Update BTC price feed with current timestamp
CURRENT_TIME=$(date +%s)
BTC_PRICE_RAW="4900000000000"  # $49,000 in 8 decimals
ROUND_ID="$CURRENT_TIME"

echo "Updating BTC price feed with current timestamp..."
cast send $BTC_FEED \
    "updateRoundData(uint80,int256,uint256,uint256)" \
    $ROUND_ID $BTC_PRICE_RAW $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
     --async || true \
    --legacy || echo "⚠️ Failed to update price feed"

echo "✅ Waiting 3 seconds for update..."
sleep 3

# Now check the price
BTC_PRICE=$(cast call $PRICE_ORACLE "getLatestPrice(string)(uint256)" "BTC" --rpc-url $RPC_URL 2>/dev/null || echo "0")

if [ "$BTC_PRICE" = "0" ]; then
    echo "⚠️ Price feed still stale. Using default price..."
    BTC_PRICE="49000000000000000000000" # $49k in 18 decimals
fi

BTC_PRICE_READABLE=$(echo "scale=2; $BTC_PRICE / 1000000000000000000")
echo "BTC Price: \$$BTC_PRICE_READABLE"

echo ""
echo "=========================================="
echo "Step 5: Checking Vault Liquidity"
echo "=========================================="
echo ""

# Get vault address from perpetual contract
VAULT_ADDRESS=$(cast call $PERPETUAL_TRADING "vault()(address)" --rpc-url $RPC_URL)
echo "Vault Address: $VAULT_ADDRESS"

# Check vault liquidity
POOL_AMOUNT=$(cast call $VAULT_ADDRESS "poolAmounts(address)(uint256)" $MOCK_USDT --rpc-url $RPC_URL)
RESERVED_AMOUNT=$(cast call $VAULT_ADDRESS "reservedAmounts(address)(uint256)" $MOCK_USDT --rpc-url $RPC_URL)
AVAILABLE_LIQUIDITY=$((POOL_AMOUNT - RESERVED_AMOUNT))

POOL_READABLE=$(echo "scale=2; $POOL_AMOUNT / 1000000")
RESERVED_READABLE=$(echo "scale=2; $RESERVED_AMOUNT / 1000000")
AVAILABLE_READABLE=$(echo "scale=2; $AVAILABLE_LIQUIDITY / 1000000")

echo "Pool Amount: $POOL_READABLE USDT"
echo "Reserved: $RESERVED_READABLE USDT"
echo "Available: $AVAILABLE_READABLE USDT"



echo "update price feed before opening position..."
cast send $BTC_FEED \
    "updateRoundData(uint80, int256, uint256, uint256)" \
    $ROUND_ID $BTC_PRICE_RAW $CURRENT_TIME $CURRENT_TIME \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy --async || true

# Position needs 1000 USDT (100 * 10x leverage)
POSITION_LIQUIDITY_NEEDED=$((COLLATERAL_AMOUNT * LEVERAGE))
POSITION_NEEDED_READABLE=$(echo "scale=2; $POSITION_LIQUIDITY_NEEDED / 1000000")

echo "Position needs: $POSITION_NEEDED_READABLE USDT liquidity"

if [ "$AVAILABLE_LIQUIDITY" -lt "$POSITION_LIQUIDITY_NEEDED" ]; then
    echo ""
    echo "⚠️ Insufficient vault liquidity! Adding liquidity..."
    
    # Mint USDT for liquidity
    LIQUIDITY_TO_ADD="10000000000"  # 10k USDT
    cast send $MOCK_USDT \
        "mintTo(uint256)" \
        $LIQUIDITY_TO_ADD \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --legacy --async || true
    
    sleep 3
    
    # Approve vault
    cast send $MOCK_USDT \
        "approve(address,uint256)" \
        $VAULT_ADDRESS $LIQUIDITY_TO_ADD \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --legacy --async || true
    
    sleep 3
    
    # Add liquidity to vault
    cast send $VAULT_ADDRESS \
        "addLiquidity(address,uint256,uint256)" \
        $MOCK_USDT $LIQUIDITY_TO_ADD 0 \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --legacy --async || true
    
    echo "✅ Liquidity added. Waiting 5 seconds..."
    sleep 5
else
    echo "✅ Sufficient vault liquidity available"
fi

echo ""
echo "=========================================="
echo "Step 6: Opening Position"
echo "=========================================="
echo ""

echo "Position Details:"
echo "  Asset: $ASSET"
echo "  Direction: $([ "$IS_LONG" = "true" ] && echo "LONG" || echo "SHORT")"
echo "  Collateral: $(echo "scale=2; $COLLATERAL_AMOUNT / 1000000") USDT"
echo "  Leverage: ${LEVERAGE}x"
echo "  Position Size: $(echo "scale=2; ($COLLATERAL_AMOUNT / 1000000) * $LEVERAGE") USD"
echo ""

echo "Opening position..."
cast send $PERPETUAL_TRADING \
    "openPosition(string,bool,uint256,uint256)" \
    "$ASSET" $IS_LONG $COLLATERAL_AMOUNT $LEVERAGE \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy \
    --async || true

echo "✅ Position transaction sent. Waiting 5 seconds..."
sleep 5

echo ""
echo "=========================================="
echo "Step 7: Verifying Position"
echo "=========================================="
echo ""

# Get position ID (assuming it's the first position for this user)
echo "Checking user's positions..."

# Get user's position count
POSITIONS=$(cast call $PERPETUAL_TRADING "getTraderPositions(address)(uint256[])" $USER_ADDRESS --rpc-url $RPC_URL 2>/dev/null || echo "0")
echo "Positions: $POSITIONS"
POSITION_COUNT=$POSITIONS | jq 'length' 2>/dev/null || echo "0"

echo "Total positions: $POSITION_COUNT"

if [ "$POSITION_COUNT" -gt "0" ]; then
    echo ""
    echo "Fetching latest position details..."

    # Get the latest position ID
    POSITION_INDEX=$((POSITION_COUNT - 1))
    POSITION_ID=$(cast call $PERPETUAL_TRADING "userPositions(address,uint256)(uint256)" $USER_ADDRESS $POSITION_INDEX --rpc-url $RPC_URL 2>/dev/null || echo "")

    if [ -n "$POSITION_ID" ]; then
        echo "Position ID: $POSITION_ID"

        # Get position details
        POSITION_DATA=$(cast call $PERPETUAL_TRADING "positions(uint256)" $POSITION_ID --rpc-url $RPC_URL 2>/dev/null || echo "")

        if [ -n "$POSITION_DATA" ]; then
            echo ""
            echo "✅ Position opened successfully!"
            echo "Position Data: $POSITION_DATA"
        fi
    fi
else
    echo "⚠️  No positions found yet. Transaction may still be pending."
    echo "Check the explorer: https://testnet.qie.digital/address/$PERPETUAL_TRADING"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "✅ USDT Balance checked"
echo "✅ USDT Approved for PerpetualTrading"
echo "✅ Position opening transaction sent"
echo ""
echo "Monitor your transaction at:"
echo "https://testnet.qie.digital/address/$USER_ADDRESS"
echo ""
echo "To close the position, use:"
echo "cast send $PERPETUAL_TRADING 'closePosition(uint256)' <POSITION_ID> --rpc-url $RPC_URL --private-key \$PRIVATE_KEY --legacy --async"
echo ""
