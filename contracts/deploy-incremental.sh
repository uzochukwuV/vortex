#!/bin/bash

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    exit 1
fi

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
FEE_RECIPIENT=${FEE_RECIPIENT:-$DEPLOYER}
TREASURY=${TREASURY:-$DEPLOYER}
GUARDIAN=${GUARDIAN:-$DEPLOYER}

echo "=========================================="
echo "Tenderly Fork Deployment (QIE Testnet)"
echo "=========================================="
echo ""
echo "Deployer: $DEPLOYER"
echo "RPC: Tenderly Fork"
echo ""

# Check chain ID
CHAIN_ID=$(cast chain-id --rpc-url $RPC_URL)
echo "Chain ID: $CHAIN_ID (should be 23772913)"
echo ""

# Create deployments directory
mkdir -p deployments

# Step 1: Deploy Mock USDT
echo "=========================================="
echo "1. Deploying Mock USDT"
echo "=========================================="
MOCK_USDT=$(forge create src/mocks/MockERC20.sol:MockERC20 \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args "Mock USDT" "mUSDT" 6 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Mock USDT: $MOCK_USDT"
sleep 3

# Step 2: Deploy Mock BTC
echo "=========================================="
echo "2. Deploying Mock BTC"
echo "=========================================="
MOCK_BTC=$(forge create src/mocks/MockERC20.sol:MockERC20 \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args "Mock Bitcoin" "mBTC" 18 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Mock BTC: $MOCK_BTC"
sleep 3

# Step 3: Deploy Mock ETH
echo "=========================================="
echo "3. Deploying Mock ETH"
echo "=========================================="
MOCK_ETH=$(forge create src/mocks/MockERC20.sol:MockERC20 \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args "Mock Ethereum" "mETH" 18 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Mock ETH: $MOCK_ETH"
sleep 3

# Step 4: Deploy Mock BNB
echo "=========================================="
echo "4. Deploying Mock BNB"
echo "=========================================="
MOCK_BNB=$(forge create src/mocks/MockERC20.sol:MockERC20 \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args "Mock BNB" "mBNB" 18 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Mock BNB: $MOCK_BNB"
sleep 3

# Step 5: Deploy Mock SOL
echo "=========================================="
echo "5. Deploying Mock SOL"
echo "=========================================="
MOCK_SOL=$(forge create src/mocks/MockERC20.sol:MockERC20 \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args "Mock Solana" "mSOL" 18 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Mock SOL: $MOCK_SOL"
sleep 3

# Step 6: Deploy Mock QIE
echo "=========================================="
echo "6. Deploying Mock QIE"
echo "=========================================="
MOCK_QIE=$(forge create src/mocks/MockERC20.sol:MockERC20 \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args "Mock QIE" "mQIE" 18 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Mock QIE: $MOCK_QIE"
sleep 3

# Step 7-11: Deploy Price Feeds
echo "=========================================="
echo "7. Deploying BTC Price Feed"
echo "=========================================="
BTC_FEED=$(forge create src/mocks/MockV3Aggregator.sol:MockV3Aggregator \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args 8 4300000000000 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ BTC Feed: $BTC_FEED"
sleep 3

echo "=========================================="
echo "8. Deploying ETH Price Feed"
echo "=========================================="
ETH_FEED=$(forge create src/mocks/MockV3Aggregator.sol:MockV3Aggregator \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args 8 230000000000 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ ETH Feed: $ETH_FEED"
sleep 3

echo "=========================================="
echo "9. Deploying BNB Price Feed"
echo "=========================================="
BNB_FEED=$(forge create src/mocks/MockV3Aggregator.sol:MockV3Aggregator \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args 8 31000000000 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ BNB Feed: $BNB_FEED"
sleep 3

echo "=========================================="
echo "10. Deploying SOL Price Feed"
echo "=========================================="
SOL_FEED=$(forge create src/mocks/MockV3Aggregator.sol:MockV3Aggregator \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args 8 9500000000 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ SOL Feed: $SOL_FEED"
sleep 3

echo "=========================================="
echo "11. Deploying QIE Price Feed"
echo "=========================================="
QIE_FEED=$(forge create src/mocks/MockV3Aggregator.sol:MockV3Aggregator \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args 8 100000000 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ QIE Feed: $QIE_FEED"
sleep 3

# Step 12: Deploy Platform Token
echo "=========================================="
echo "12. Deploying Platform Token"
echo "=========================================="
PLATFORM_TOKEN=$(forge create src/PlatformToken.sol:PlatformToken \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args 100000000000000000000000000 \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Platform Token: $PLATFORM_TOKEN"
sleep 3

# Step 13: Deploy Price Oracle
echo "=========================================="
echo "13. Deploying Price Oracle"
echo "=========================================="
PRICE_ORACLE=$(forge create src/PriceOracle.sol:PriceOracle \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $CHAIN_ID \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Price Oracle: $PRICE_ORACLE"
sleep 3

# Add price feeds
echo "Adding price feeds to oracle..."
echo $PRICE_ORACLE $BTC_FEED $ETH_FEED $BNB_FEED $SOL_FEED $QIE_FEED
# cast send $PRICE_ORACLE "addPriceFeed(string,address,uint8,uint256)" "BTC" $BTC_FEED 8 3600 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy
# sleep 2
# cast send $PRICE_ORACLE "addPriceFeed(string,address,uint8,uint256)" "ETH" $ETH_FEED 8 3600 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy
# sleep 2
# cast send $PRICE_ORACLE "addPriceFeed(string,address,uint8,uint256)" "BNB" $BNB_FEED 8 3600 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy
# sleep 2
# cast send $PRICE_ORACLE "addPriceFeed(string,address,uint8,uint256)" "SOL" $SOL_FEED 8 3600 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy
# sleep 2
# cast send $PRICE_ORACLE "addPriceFeed(string,address,uint8,uint256)" "QIE" $QIE_FEED 8 3600 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy
# sleep 2

# Step 14: Deploy Vault
echo "=========================================="
echo "14. Deploying Vault"
echo "=========================================="
VAULT=$(forge create src/Vault.sol:Vault \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $FEE_RECIPIENT \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Vault: $VAULT"
sleep 3

# Whitelist USDT
echo "Whitelisting USDT..."
# cast send $VAULT "whitelistToken(address,uint8,uint256,bool)" $MOCK_USDT 6 5000 true --rpc-url $RPC_URL --private-key $PRIVATE_KEY --legacy > /dev/null 2>&1
# sleep 2

# Step 15: Deploy Perpetual Trading
echo "=========================================="
echo "15. Deploying Perpetual Trading"
echo "=========================================="
PERPETUAL_TRADING=$(forge create src/PerpetualTrading.sol:PerpetualTrading \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $PRICE_ORACLE $VAULT $MOCK_USDT 6 $FEE_RECIPIENT \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Perpetual Trading: $PERPETUAL_TRADING"
sleep 3

# Authorize PerpetualTrading
echo "Authorizing PerpetualTrading..."
# cast send $VAULT "authorizeContract(address)" $PERPETUAL_TRADING --rpc-url $RPC_URL --private-key $PRIVATE_KEY --legacy > /dev/null 2>&1
# sleep 2

# Step 16: Deploy Spot Market
echo "=========================================="
echo "16. Deploying Spot Market"
echo "=========================================="
SPOT_MARKET=$(forge create src/SpotMarket.sol:SpotMarket \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $FEE_RECIPIENT \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Spot Market: $SPOT_MARKET"
sleep 3

# Step 17: Deploy Staking
echo "=========================================="
echo "17. Deploying Staking"
echo "=========================================="
STAKING=$(forge create src/Staking.sol:Staking \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $PLATFORM_TOKEN $PLATFORM_TOKEN \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Staking: $STAKING"
sleep 3

# Step 18: Deploy Governance
echo "=========================================="
echo "18. Deploying Governance"
echo "=========================================="
GOVERNANCE=$(forge create src/Governance.sol:Governance \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $PLATFORM_TOKEN $GUARDIAN \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Governance: $GOVERNANCE"
sleep 3

# Step 19: Deploy Liquidity Mining
echo "=========================================="
echo "19. Deploying Liquidity Mining"
echo "=========================================="
LIQUIDITY_MINING=$(forge create src/LiquidityMining.sol:LiquidityMining \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $PLATFORM_TOKEN $SPOT_MARKET 1000000000000000000 $FEE_RECIPIENT \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Liquidity Mining: $LIQUIDITY_MINING"
sleep 3

# Step 20: Deploy Reward Distributor
echo "=========================================="
echo "20. Deploying Reward Distributor"
echo "=========================================="
REWARD_DISTRIBUTOR=$(forge create src/RewardDistributor.sol:RewardDistributor \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --constructor-args $VAULT $STAKING $TREASURY $FEE_RECIPIENT \
    2>&1 | grep "Deployed to:" | awk '{print $3}')
echo "✅ Reward Distributor: $REWARD_DISTRIBUTOR"
sleep 3

# Add reward token
echo "Adding reward token..."
# cast send $REWARD_DISTRIBUTOR "addRewardToken(address)" $MOCK_USDT --rpc-url $RPC_URL --private-key $PRIVATE_KEY --legacy > /dev/null 2>&1
# sleep 2

# Print summary
echo ""
echo "=========================================="
echo "DEPLOYMENT SUMMARY"
echo "=========================================="
echo ""
echo "Mock Tokens:"
echo "    Mock USDT: $MOCK_USDT"
echo "    Mock BTC: $MOCK_BTC"
echo "    Mock ETH: $MOCK_ETH"
echo "    Mock BNB: $MOCK_BNB"
echo "    Mock SOL: $MOCK_SOL"
echo "    Mock QIE: $MOCK_QIE"
echo ""
echo "Mock Price Feeds:"
echo "    BTC Feed: $BTC_FEED"
echo "    ETH Feed: $ETH_FEED"
echo "    BNB Feed: $BNB_FEED"
echo "    SOL Feed: $SOL_FEED"
echo "    QIE Feed: $QIE_FEED"
echo ""
echo "Protocol Contracts:"
echo "    PlatformToken (PDX): $PLATFORM_TOKEN"
echo "    PriceOracle: $PRICE_ORACLE"
echo "    PerpetualTrading: $PERPETUAL_TRADING"
echo "    SpotMarket: $SPOT_MARKET"
echo "    Staking: $STAKING"
echo "    Vault: $VAULT"
echo "    Governance: $GOVERNANCE"
echo "    LiquidityMining: $LIQUIDITY_MINING"
echo "    RewardDistributor: $REWARD_DISTRIBUTOR"
echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
