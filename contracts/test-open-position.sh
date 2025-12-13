#!/bin/bash

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
RPC_URL="https://rpc1testnet.qie.digital"
USER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)

echo "=========================================="
echo "Test: Approve USDT & Open Position"
echo "QIE Testnet"
echo "=========================================="
echo ""

echo "Send 2eth to $USER_ADDRESS on Tenderly Fork if needed for gas fees."
# cast send --value 2ether 0xa7793C5c4582C72B3aa5e78859d8Bd66998D43ce \
#     --rpc-url $RPC_URL \
#     --private-key $PRIVATE_KEY \
#     --legacy \
#     --async || true

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
