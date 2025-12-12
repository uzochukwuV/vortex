const { ethers } = require("ethers");

// Configuration
const config = {
  rpcUrl: process.env.QIE_RPC_URL || "https://rpc5mainnet.qie.digital",
  chainId: 1990,
  explorerUrl: "https://mainnet.qie.digital",
  priceFeeds: {
    // QIE Mainnet Oracle Addresses
    "BTC/USD": "0x9E596d809a20A272c788726f592c0d1629755440",
    "ETH/USD": "0x4bb7012Fbc79fE4Ae9B664228977b442b385500d",
    "XRP/USD": "0x804582B1f8Fea73919e7c737115009f668f97528",
    "SOL/USD": "0xe86999c8e6C8eeF71bebd35286bCa674E0AD7b21",
    "QIE/USD": "0x3Bc617cF3A4Bb77003e4c556B87b13D556903D17",
    "XAUt/USD": "0x9aD0199a67588ee293187d26bA1BE61cb07A214c", // Tether Gold
    "BNB/USD": "0x775A56117Fdb8b31877E75Ceeb68C96765b031e6",
  }
};

// ABI fragment to read latestRoundData
const aggregatorV3InterfaceABI = [
  {
    inputs: [],
    name: "decimals",
    outputs: [{ internalType: "uint8", name: "", type: "uint8" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "description",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "latestRoundData",
    outputs: [
      { internalType: "uint80", name: "roundId", type: "uint80" },
      { internalType: "int256", name: "answer", type: "int256" },
      { internalType: "uint256", name: "startedAt", type: "uint256" },
      { internalType: "uint256", name: "updatedAt", type: "uint256" },
      { internalType: "uint80", name: "answeredInRound", type: "uint80" }
    ],
    stateMutability: "view",
    type: "function"
  }
];

async function verifyPriceFeed(provider, feedAddress, feedName) {
  console.log(`\n${"=".repeat(60)}`);
  console.log(`Verifying ${feedName}`);
  console.log(`Address: ${feedAddress}`);
  console.log(`${"=".repeat(60)}`);

  try {
    const priceFeed = new ethers.Contract(feedAddress, aggregatorV3InterfaceABI, provider);

    // Get feed description
    let description;
    try {
      description = await priceFeed.description();
      console.log(`Description: ${description}`);
    } catch (e) {
      console.log(`Description: Not available`);
    }

    // Get decimals
    const decimals = await priceFeed.decimals();
    console.log(`Decimals: ${decimals}`);

    // Get latest round data
    const roundData = await priceFeed.latestRoundData();
    const price = roundData.answer;
    const updatedAt = roundData.updatedAt;
    const answeredInRound = roundData.answeredInRound;
    const roundId = roundData.roundId;

    // Normalize price based on decimals (handle BigInt)
    const decimalsNum = Number(decimals);
    const priceStr = price.toString();
    const normalizedPrice = Number(priceStr) / Math.pow(10, decimalsNum);

    console.log(`\nLatest Price Data:`);
    console.log(`  Round ID: ${roundId.toString()}`);
    console.log(`  Raw Price: ${priceStr}`);
    console.log(`  Normalized Price: $${normalizedPrice.toLocaleString()}`);
    console.log(`  Updated At: ${new Date(Number(updatedAt) * 1000).toISOString()}`);
    console.log(`  Answered In Round: ${answeredInRound.toString()}`);

    // Check data freshness (warning if older than 1 hour)
    const now = Math.floor(Date.now() / 1000);
    const updatedAtNum = Number(updatedAt);
    const age = now - updatedAtNum;
    const ageMinutes = Math.floor(age / 60);
    const ageHours = Math.floor(age / 3600);

    console.log(`\nData Age: ${ageMinutes} minutes (${ageHours} hours)`);

    if (age > 3600) {
      console.log(`⚠️  WARNING: Price data is older than 1 hour!`);
    } else {
      console.log(`✅ Price data is fresh`);
    }

    // Verify round consistency
    if (answeredInRound >= roundId) {
      console.log(`✅ Round data is consistent`);
    } else {
      console.log(`⚠️  WARNING: Stale round data detected!`);
    }

    return {
      success: true,
      feedName,
      address: feedAddress,
      decimals: decimalsNum,
      price: normalizedPrice,
      updatedAt: updatedAtNum,
      age,
      isFresh: age <= 3600
    };

  } catch (error) {
    console.error(`❌ Error verifying ${feedName}:`, error.message);
    return {
      success: false,
      feedName,
      address: feedAddress,
      error: error.message
    };
  }
}

async function main() {
  console.log("\n" + "=".repeat(60));
  console.log("QIE Blockchain - Price Oracle Verification");
  console.log("=".repeat(60));
  console.log(`RPC URL: ${config.rpcUrl}`);

  const provider = new ethers.JsonRpcProvider(config.rpcUrl);

  // Test connection
  try {
    const network = await provider.getNetwork();
    console.log(`Connected to Chain ID: ${network.chainId}`);

    const blockNumber = await provider.getBlockNumber();
    console.log(`Latest Block: ${blockNumber}`);
  } catch (error) {
    console.error("❌ Failed to connect to RPC:", error.message);
    process.exit(1);
  }

  // Verify all price feeds
  const results = [];
  for (const [feedName, feedAddress] of Object.entries(config.priceFeeds)) {
    if (feedAddress.startsWith("0xYour")) {
      console.log(`\n⚠️  Skipping ${feedName}: Address not configured`);
      continue;
    }

    const result = await verifyPriceFeed(provider, feedAddress, feedName);
    results.push(result);

    // Wait a bit between requests
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  // Summary
  console.log("\n" + "=".repeat(60));
  console.log("VERIFICATION SUMMARY");
  console.log("=".repeat(60));

  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);

  console.log(`Total Feeds Checked: ${results.length}`);
  console.log(`✅ Successful: ${successful.length}`);
  console.log(`❌ Failed: ${failed.length}`);

  if (successful.length > 0) {
    console.log("\nSuccessful Feeds:");
    successful.forEach(r => {
      const freshIcon = r.isFresh ? "✅" : "⚠️";
      console.log(`  ${freshIcon} ${r.feedName}: $${r.price.toLocaleString()} (${r.decimals} decimals)`);
    });
  }

  if (failed.length > 0) {
    console.log("\nFailed Feeds:");
    failed.forEach(r => {
      console.log(`  ❌ ${r.feedName}: ${r.error}`);
    });
  }

  // Export results
  const outputPath = "./price-feed-verification.json";
  const fs = require("fs");
  fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));
  console.log(`\n📝 Results saved to: ${outputPath}`);
}

// Run the script
main()
  .then(() => {
    console.log("\n✅ Verification complete!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Verification failed:", error);
    process.exit(1);
  });
