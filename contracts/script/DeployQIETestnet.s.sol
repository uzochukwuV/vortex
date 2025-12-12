// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "lib/forge-std/src/console.sol";
import "../src/PlatformToken.sol";
import "../src/PriceOracle.sol";
import "../src/PerpetualTrading.sol";
import "../src/SpotMarket.sol";
import "../src/Staking.sol";
import "../src/Vault.sol";
import "../src/Governance.sol";
import "../src/LiquidityMining.sol";
import "../src/RewardDistributor.sol";
import "../src/mocks/MockERC20.sol";
import "../src/mocks/MockV3Aggregator.sol";

/// @title QIE Testnet Deployment Script
/// @notice Deploy all contracts with mock tokens and price feeds for QIE Testnet
contract DeployQIETestnetScript is Script {
    // Contract instances
    PlatformToken public platformToken;
    PriceOracle public priceOracle;
    PerpetualTrading public perpetualTrading;
    SpotMarket public spotMarket;
    Staking public staking;
    Vault public vault;
    Governance public governance;
    LiquidityMining public liquidityMining;
    RewardDistributor public rewardDistributor;

    // Mock tokens
    MockERC20 public mockUSDT;
    MockERC20 public mockBTC;
    MockERC20 public mockETH;
    MockERC20 public mockBNB;
    MockERC20 public mockSOL;
    MockERC20 public mockQIE;

    // Mock price feeds
    MockV3Aggregator public btcPriceFeed;
    MockV3Aggregator public ethPriceFeed;
    MockV3Aggregator public bnbPriceFeed;
    MockV3Aggregator public solPriceFeed;
    MockV3Aggregator public qiePriceFeed;

    // QIE Testnet Configuration
    uint256 public constant QIE_TESTNET_CHAIN_ID = 1991; // QIE testnet chain ID
    uint256 public constant INITIAL_TOKEN_SUPPLY = 100_000_000 * 10**18; // 100M tokens
    uint8 public constant USDT_DECIMALS = 6;

    // Initial mock prices (8 decimals)
    int256 public constant BTC_INITIAL_PRICE = 43000 * 10**8; // $43,000
    int256 public constant ETH_INITIAL_PRICE = 2300 * 10**8;  // $2,300
    int256 public constant BNB_INITIAL_PRICE = 310 * 10**8;   // $310
    int256 public constant SOL_INITIAL_PRICE = 95 * 10**8;    // $95
    int256 public constant QIE_INITIAL_PRICE = 1 * 10**8;     // $1

    function run() external {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);
        address treasury = vm.envOr("TREASURY", deployer);
        address guardian = vm.envOr("GUARDIAN", deployer);

        console.log("========================================");
        console.log("Deploying to QIE Testnet");
        console.log("========================================");
        console.log("Chain ID:", QIE_TESTNET_CHAIN_ID);
        console.log("Deployer:", deployer);
        console.log("Fee Recipient:", feeRecipient);
        console.log("Treasury:", treasury);
        console.log("Guardian:", guardian);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Mock Tokens
        console.log("\n========================================");
        console.log("DEPLOYING MOCK TOKENS");
        console.log("========================================");

        console.log("\n1. Deploying Mock USDT...");
        mockUSDT = new MockERC20("Mock USDT", "mUSDT", USDT_DECIMALS);
        console.log("   Mock USDT deployed at:", address(mockUSDT));

        console.log("\n2. Deploying Mock BTC...");
        mockBTC = new MockERC20("Mock Bitcoin", "mBTC", 18);
        console.log("   Mock BTC deployed at:", address(mockBTC));

        console.log("\n3. Deploying Mock ETH...");
        mockETH = new MockERC20("Mock Ethereum", "mETH", 18);
        console.log("   Mock ETH deployed at:", address(mockETH));

        console.log("\n4. Deploying Mock BNB...");
        mockBNB = new MockERC20("Mock BNB", "mBNB", 18);
        console.log("   Mock BNB deployed at:", address(mockBNB));

        console.log("\n5. Deploying Mock SOL...");
        mockSOL = new MockERC20("Mock Solana", "mSOL", 18);
        console.log("   Mock SOL deployed at:", address(mockSOL));

        console.log("\n6. Deploying Mock QIE...");
        mockQIE = new MockERC20("Mock QIE", "mQIE", 18);
        console.log("   Mock QIE deployed at:", address(mockQIE));

        // Mint some tokens to deployer for testing
        console.log("\n7. Minting initial tokens to deployer...");
        mockUSDT.mint(deployer, 1_000_000 * 10**USDT_DECIMALS); // 1M USDT
        mockBTC.mint(deployer, 10 * 10**18);  // 10 BTC
        mockETH.mint(deployer, 100 * 10**18); // 100 ETH
        mockBNB.mint(deployer, 1000 * 10**18); // 1000 BNB
        mockSOL.mint(deployer, 5000 * 10**18); // 5000 SOL
        mockQIE.mint(deployer, 10000 * 10**18); // 10000 QIE

        // 2. Deploy Mock Price Feeds
        console.log("\n========================================");
        console.log("DEPLOYING MOCK PRICE FEEDS");
        console.log("========================================");

        console.log("\n1. Deploying BTC Price Feed...");
        btcPriceFeed = new MockV3Aggregator(8, BTC_INITIAL_PRICE);
        console.log("   BTC Price Feed deployed at:", address(btcPriceFeed));
        console.log("   Initial price: $43,000");

        console.log("\n2. Deploying ETH Price Feed...");
        ethPriceFeed = new MockV3Aggregator(8, ETH_INITIAL_PRICE);
        console.log("   ETH Price Feed deployed at:", address(ethPriceFeed));
        console.log("   Initial price: $2,300");

        console.log("\n3. Deploying BNB Price Feed...");
        bnbPriceFeed = new MockV3Aggregator(8, BNB_INITIAL_PRICE);
        console.log("   BNB Price Feed deployed at:", address(bnbPriceFeed));
        console.log("   Initial price: $310");

        console.log("\n4. Deploying SOL Price Feed...");
        solPriceFeed = new MockV3Aggregator(8, SOL_INITIAL_PRICE);
        console.log("   SOL Price Feed deployed at:", address(solPriceFeed));
        console.log("   Initial price: $95");

        console.log("\n5. Deploying QIE Price Feed...");
        qiePriceFeed = new MockV3Aggregator(8, QIE_INITIAL_PRICE);
        console.log("   QIE Price Feed deployed at:", address(qiePriceFeed));
        console.log("   Initial price: $1");

        // 3. Deploy Platform Token
        console.log("\n========================================");
        console.log("DEPLOYING PROTOCOL CONTRACTS");
        console.log("========================================");

        console.log("\n1. Deploying Platform Token (PDX)...");
        platformToken = new PlatformToken(INITIAL_TOKEN_SUPPLY);
        console.log("   PlatformToken deployed at:", address(platformToken));

        // 4. Deploy Price Oracle (without initial feeds since it's testnet)
        console.log("\n2. Deploying Price Oracle...");
        priceOracle = new PriceOracle(QIE_TESTNET_CHAIN_ID);
        console.log("   PriceOracle deployed at:", address(priceOracle));

        // Add mock price feeds to oracle
        console.log("   Adding mock price feeds to oracle...");
        priceOracle.addPriceFeed("BTC", address(btcPriceFeed), 8, 3600);
        priceOracle.addPriceFeed("ETH", address(ethPriceFeed), 8, 3600);
        priceOracle.addPriceFeed("BNB", address(bnbPriceFeed), 8, 3600);
        priceOracle.addPriceFeed("SOL", address(solPriceFeed), 8, 3600);
        priceOracle.addPriceFeed("QIE", address(qiePriceFeed), 8, 3600);

        // 5. Deploy Vault
        console.log("\n3. Deploying Vault...");
        vault = new Vault(feeRecipient);
        console.log("   Vault deployed at:", address(vault));

        // Whitelist mock USDT as collateral
        console.log("   Whitelisting mock USDT in Vault...");
        vault.whitelistToken(
            address(mockUSDT),
            USDT_DECIMALS,
            5000, // 50% weight
            true  // is stable
        );

        // 6. Deploy Perpetual Trading
        console.log("\n4. Deploying Perpetual Trading...");
        perpetualTrading = new PerpetualTrading(
            address(priceOracle),
            address(vault),
            address(mockUSDT),
            USDT_DECIMALS,
            feeRecipient
        );
        console.log("   PerpetualTrading deployed at:", address(perpetualTrading));

        // Authorize PerpetualTrading to use Vault
        console.log("   Authorizing PerpetualTrading in Vault...");
        vault.authorizeContract(address(perpetualTrading));

        // 7. Deploy Spot Market
        console.log("\n5. Deploying Spot Market...");
        spotMarket = new SpotMarket(feeRecipient);
        console.log("   SpotMarket deployed at:", address(spotMarket));

        // 8. Deploy Staking
        console.log("\n6. Deploying Staking...");
        staking = new Staking(
            address(platformToken),
            address(platformToken)
        );
        console.log("   Staking deployed at:", address(staking));

        // 9. Deploy Governance
        console.log("\n7. Deploying Governance...");
        governance = new Governance(
            address(platformToken),
            guardian
        );
        console.log("   Governance deployed at:", address(governance));

        // 10. Deploy Liquidity Mining
        console.log("\n8. Deploying Liquidity Mining...");
        uint256 rewardPerSecond = 1 * 10**18; // 1 token per second
        liquidityMining = new LiquidityMining(
            address(platformToken),
            address(spotMarket),
            rewardPerSecond,
            feeRecipient
        );
        console.log("   LiquidityMining deployed at:", address(liquidityMining));

        // 11. Deploy Reward Distributor
        console.log("\n9. Deploying Reward Distributor...");
        rewardDistributor = new RewardDistributor(
            address(vault),
            address(staking),
            treasury,
            feeRecipient
        );
        console.log("   RewardDistributor deployed at:", address(rewardDistributor));

        // Add mock USDT as reward token
        rewardDistributor.addRewardToken(address(mockUSDT));

        // 12. Allocate tokens for rewards
        console.log("\n10. Allocating tokens for rewards...");
        uint256 stakingRewards = 20_000_000 * 10**18; // 20M for staking
        uint256 liquidityMiningRewards = 30_000_000 * 10**18; // 30M for liquidity mining

        platformToken.transfer(address(staking), stakingRewards);
        platformToken.transfer(address(liquidityMining), liquidityMiningRewards);

        console.log("   Staking rewards:", stakingRewards / 10**18, "PDX");
        console.log("   Liquidity mining rewards:", liquidityMiningRewards / 10**18, "PDX");

        // 13. Set reward rates
        uint256 stakingRewardRate = stakingRewards / (365 days);
        staking.setRewardRate(stakingRewardRate);
        console.log("   Staking reward rate set:", stakingRewardRate);

        vm.stopBroadcast();

        // Print deployment summary
        _printDeploymentSummary();

        // Save deployment addresses
        _saveDeploymentAddresses();

        // Print next steps
        _printNextSteps();
    }

    function _printDeploymentSummary() internal view {
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY - QIE TESTNET");
        console.log("========================================");
        console.log("\nMock Tokens:");
        console.log("  Mock USDT:", address(mockUSDT));
        console.log("  Mock BTC:", address(mockBTC));
        console.log("  Mock ETH:", address(mockETH));
        console.log("  Mock BNB:", address(mockBNB));
        console.log("  Mock SOL:", address(mockSOL));
        console.log("  Mock QIE:", address(mockQIE));
        console.log("\nMock Price Feeds:");
        console.log("  BTC Feed:", address(btcPriceFeed));
        console.log("  ETH Feed:", address(ethPriceFeed));
        console.log("  BNB Feed:", address(bnbPriceFeed));
        console.log("  SOL Feed:", address(solPriceFeed));
        console.log("  QIE Feed:", address(qiePriceFeed));
        console.log("\nProtocol Contracts:");
        console.log("  PlatformToken (PDX):", address(platformToken));
        console.log("  PriceOracle:", address(priceOracle));
        console.log("  PerpetualTrading:", address(perpetualTrading));
        console.log("  SpotMarket:", address(spotMarket));
        console.log("  Staking:", address(staking));
        console.log("  Vault:", address(vault));
        console.log("  Governance:", address(governance));
        console.log("  LiquidityMining:", address(liquidityMining));
        console.log("  RewardDistributor:", address(rewardDistributor));
        console.log("========================================\n");
    }

    function _saveDeploymentAddresses() internal {
        string memory json = "deployments";

        // Mock tokens
        vm.serializeAddress(json, "MockUSDT", address(mockUSDT));
        vm.serializeAddress(json, "MockBTC", address(mockBTC));
        vm.serializeAddress(json, "MockETH", address(mockETH));
        vm.serializeAddress(json, "MockBNB", address(mockBNB));
        vm.serializeAddress(json, "MockSOL", address(mockSOL));
        vm.serializeAddress(json, "MockQIE", address(mockQIE));

        // Mock price feeds
        vm.serializeAddress(json, "BTCPriceFeed", address(btcPriceFeed));
        vm.serializeAddress(json, "ETHPriceFeed", address(ethPriceFeed));
        vm.serializeAddress(json, "BNBPriceFeed", address(bnbPriceFeed));
        vm.serializeAddress(json, "SOLPriceFeed", address(solPriceFeed));
        vm.serializeAddress(json, "QIEPriceFeed", address(qiePriceFeed));

        // Protocol contracts
        vm.serializeAddress(json, "PlatformToken", address(platformToken));
        vm.serializeAddress(json, "PriceOracle", address(priceOracle));
        vm.serializeAddress(json, "PerpetualTrading", address(perpetualTrading));
        vm.serializeAddress(json, "SpotMarket", address(spotMarket));
        vm.serializeAddress(json, "Staking", address(staking));
        vm.serializeAddress(json, "Vault", address(vault));
        vm.serializeAddress(json, "Governance", address(governance));
        vm.serializeAddress(json, "LiquidityMining", address(liquidityMining));
        string memory finalJson = vm.serializeAddress(json, "RewardDistributor", address(rewardDistributor));

        string memory path = "./deployments/qie-testnet-1991.json";
        // vm.writeJson(finalJson, path);
        console.log("Deployment addresses saved to:", path);
    }

    function _printNextSteps() internal pure {
        console.log("\n========================================");
        console.log("NEXT STEPS - TESTNET");
        console.log("========================================");
        console.log("1. Mint mock tokens for testing:");
        console.log("   mockUSDT.mint(yourAddress, amount)");
        console.log("   mockBTC.mint(yourAddress, amount)");
        console.log("");
        console.log("2. Update mock price feeds:");
        console.log("   btcPriceFeed.updateAnswer(newPrice)");
        console.log("   ethPriceFeed.updateAnswer(newPrice)");
        console.log("");
        console.log("3. Test perpetual trading:");
        console.log("   - Approve mock USDT");
        console.log("   - Deposit collateral");
        console.log("   - Open positions (BTC, ETH, BNB, SOL, QIE)");
        console.log("");
        console.log("4. Create spot market pools");
        console.log("");
        console.log("5. Test staking and rewards");
        console.log("");
        console.log("6. Set up frontend with testnet addresses");
        console.log("========================================\n");
    }
}
