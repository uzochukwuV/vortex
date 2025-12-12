#!/bin/bash

# Reset Nonce Fix for QIE Testnet
# This script clears forge cache and prepares for fresh deployment

set -e

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

RPC_URL="https://rpc1testnet.qie.digital"
ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)

echo "=========================================="
echo "QIE Testnet Nonce Reset Tool"
echo "=========================================="
echo ""
echo "Wallet Address: $ADDRESS"
echo ""

# Get current nonce from the network
echo "Fetching current nonce from network..."
NONCE=$(cast nonce $ADDRESS --rpc-url $RPC_URL)

echo "✅ Current nonce on network: $NONCE"
echo ""

# Clear forge broadcast and cache
echo "Clearing Forge broadcast and cache files..."
rm -rf broadcast/DeployQIETestnet.s.sol
rm -rf cache/DeployQIETestnet.s.sol
rm -rf broadcast/DeployQIE.s.sol
rm -rf cache/DeployQIE.s.sol

echo "✅ Cleared deployment cache"
echo ""

# Check balance
echo "Checking QIE balance..."
BALANCE=$(cast balance $ADDRESS --rpc-url $RPC_URL)
BALANCE_QIE=$(echo "scale=4; $BALANCE / 1000000000000000000" | bc)

echo "✅ Balance: $BALANCE_QIE QIE"
echo ""

echo "=========================================="
echo "Ready to Deploy"
echo "=========================================="
echo ""
echo "Your wallet is ready for deployment with nonce: $NONCE"
echo "Run: ./deploy-qie-testnet.sh"
echo ""
