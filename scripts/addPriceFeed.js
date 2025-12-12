const { ethers } = require("ethers");

// Configuration
const config = {
  rpcUrl: process.env.QIE_RPC_URL || "https://rpc5mainnet.qie.digital",
  privateKey: process.env.PRIVATE_KEY,
  priceOracleAddress: process.env.PRICE_ORACLE_ADDRESS || "",
};

// PriceOracle ABI (only functions we need)
const priceOracleABI = [
  {
    inputs: [
      { internalType: "string", name: "asset", type: "string" },
      { internalType: "address", name: "feedAddress", type: "address" },
      { internalType: "uint8", name: "decimals", type: "uint8" },
      { internalType: "uint256", name: "maxPriceAge", type: "uint256" }
    ],
    name: "addPriceFeed",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [{ internalType: "string", name: "asset", type: "string" }],
    name: "getPriceFeedInfo",
    outputs: [
      { internalType: "address", name: "feedAddress", type: "address" },
      { internalType: "uint8", name: "decimals", type: "uint8" },
      { internalType: "bool", name: "isActive", type: "bool" }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "string", name: "asset", type: "string" }],
    name: "getLatestPrice",
    outputs: [{ internalType: "uint256", name: "price", type: "uint256" }],
    stateMutability: "view",
    type: "function"
  }
];

async function addPriceFeed(asset, feedAddress, decimals, maxPriceAge) {
  console.log("\n" + "=".repeat(60));
  console.log("Adding Price Feed to Oracle");
  console.log("=".repeat(60));

  if (!config.privateKey) {
    console.error("❌ Error: PRIVATE_KEY not set in environment");
    process.exit(1);
  }

  if (!config.priceOracleAddress) {
    console.error("❌ Error: PRICE_ORACLE_ADDRESS not set in environment");
    process.exit(1);
  }

  const provider = new ethers.JsonRpcProvider(config.rpcUrl);
  const wallet = new ethers.Wallet(config.privateKey, provider);
  const priceOracle = new ethers.Contract(config.priceOracleAddress, priceOracleABI, wallet);

  console.log(`\nParameters:`);
  console.log(`  Asset: ${asset}`);
  console.log(`  Feed Address: ${feedAddress}`);
  console.log(`  Decimals: ${decimals}`);
  console.log(`  Max Price Age: ${maxPriceAge} seconds`);
  console.log(`  Price Oracle: ${config.priceOracleAddress}`);
  console.log(`  Sender: ${wallet.address}`);

  // Check if feed already exists
  try {
    const existingFeed = await priceOracle.getPriceFeedInfo(asset);
    if (existingFeed.isActive) {
      console.log(`\n⚠️  Warning: ${asset} price feed already exists!`);
      console.log(`  Current Feed: ${existingFeed.feedAddress}`);
      console.log(`  Current Decimals: ${existingFeed.decimals}`);

      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });

      const answer = await new Promise(resolve => {
        readline.question('\nDo you want to update it? (yes/no): ', resolve);
      });
      readline.close();

      if (answer.toLowerCase() !== 'yes') {
        console.log("❌ Cancelled");
        process.exit(0);
      }
    }
  } catch (e) {
    // Feed doesn't exist, which is fine
    console.log(`\n✅ ${asset} is a new price feed`);
  }

  // Add the price feed
  console.log(`\n📝 Sending transaction...`);

  try {
    const tx = await priceOracle.addPriceFeed(asset, feedAddress, decimals, maxPriceAge);
    console.log(`  Transaction Hash: ${tx.hash}`);
    console.log(`  Waiting for confirmation...`);

    const receipt = await tx.wait();
    console.log(`✅ Transaction confirmed in block ${receipt.blockNumber}`);
    console.log(`  Gas Used: ${receipt.gasUsed.toString()}`);

    // Verify the feed was added
    console.log(`\n🔍 Verifying price feed...`);
    const feedInfo = await priceOracle.getPriceFeedInfo(asset);
    console.log(`  Feed Address: ${feedInfo.feedAddress}`);
    console.log(`  Decimals: ${feedInfo.decimals}`);
    console.log(`  Is Active: ${feedInfo.isActive}`);

    // Try to get a price
    try {
      const price = await priceOracle.getLatestPrice(asset);
      const normalizedPrice = Number(price.toString()) / Math.pow(10, 18);
      console.log(`  Latest Price: $${normalizedPrice.toLocaleString()}`);
      console.log(`\n✅ ${asset} price feed is working correctly!`);
    } catch (e) {
      console.log(`\n⚠️  Warning: Could not fetch price: ${e.message}`);
      console.log(`  The feed might be stale or have issues.`);
    }

  } catch (error) {
    console.error(`\n❌ Error adding price feed:`, error.message);

    if (error.message.includes("Ownable")) {
      console.error(`\n⚠️  You are not the owner of the PriceOracle contract!`);
      console.error(`  Only the owner can add price feeds.`);
    }

    process.exit(1);
  }

  console.log("\n" + "=".repeat(60));
  console.log(`${asset}/USD is now available for perpetual trading!`);
  console.log("=".repeat(60));
}

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length === 0) {
  console.log("\nUsage: node addPriceFeed.js <asset> <feedAddress> [decimals] [maxPriceAge]");
  console.log("\nExamples:");
  console.log("  node addPriceFeed.js AVAX 0x123...abc");
  console.log("  node addPriceFeed.js LINK 0x456...def 8 3600");
  console.log("\nEnvironment variables required:");
  console.log("  PRIVATE_KEY - Your private key");
  console.log("  PRICE_ORACLE_ADDRESS - Deployed PriceOracle address");
  console.log("  QIE_RPC_URL - QIE blockchain RPC (optional, defaults to mainnet)");
  console.log("\nAvailable on QIE Mainnet:");
  console.log("  BTC/USD: 0x9E596d809a20A272c788726f592c0d1629755440");
  console.log("  ETH/USD: 0x4bb7012Fbc79fE4Ae9B664228977b442b385500d");
  console.log("  SOL/USD: 0xe86999c8e6C8eeF71bebd35286bCa674E0AD7b21");
  console.log("  XRP/USD: 0x804582B1f8Fea73919e7c737115009f668f97528");
  console.log("  BNB/USD: 0x775A56117Fdb8b31877E75Ceeb68C96765b031e6");
  console.log("  QIE/USD: 0x3Bc617cF3A4Bb77003e4c556B87b13D556903D17");
  console.log();
  process.exit(0);
}

const asset = args[0];
const feedAddress = args[1];
const decimals = args[2] ? parseInt(args[2]) : 8;
const maxPriceAge = args[3] ? parseInt(args[3]) : 3600;

if (!ethers.isAddress(feedAddress)) {
  console.error(`❌ Error: Invalid feed address: ${feedAddress}`);
  process.exit(1);
}

addPriceFeed(asset, feedAddress, decimals, maxPriceAge)
  .then(() => {
    console.log("\n✅ Price feed added successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Failed to add price feed:", error);
    process.exit(1);
  });
