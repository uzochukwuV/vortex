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

/// @title QIE Blockchain Deployment Script
/// @notice Deploy all contracts for the GMX-style perpetual DEX on QIE Blockchain
contract DeployQIEScript is Script {
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

    // QIE Configuration
    uint256 public constant QIE_CHAIN_ID = 1990;
    uint256 public constant INITIAL_TOKEN_SUPPLY = 100_000_000 * 10**18; // 100M tokens
    uint8 public constant USDT_DECIMALS = 6; // Assuming USDT on QIE

    function run() external {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load configuration
        // Note: You need to provide USDT or stablecoin address on QIE
        address collateralToken = vm.envOr("COLLATERAL_TOKEN_QIE", address(0));
        require(collateralToken != address(0), "COLLATERAL_TOKEN_QIE not set in .env");

        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);
        address treasury = vm.envOr("TREASURY", deployer);
        address guardian = vm.envOr("GUARDIAN", deployer);

        console.log("========================================");
        console.log("Deploying to QIE Blockchain");
        console.log("========================================");
        console.log("Chain ID:", QIE_CHAIN_ID);
        console.log("Deployer:", deployer);
        console.log("Collateral Token:", collateralToken);
        console.log("Fee Recipient:", feeRecipient);
        console.log("Treasury:", treasury);
        console.log("Guardian:", guardian);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Platform Token
        console.log("\n1. Deploying Platform Token (PDX)...");
        platformToken = new PlatformToken(INITIAL_TOKEN_SUPPLY);
        console.log("   PlatformToken deployed at:", address(platformToken));

        // 2. Deploy Price Oracle with QIE chain ID
        console.log("\n2. Deploying Price Oracle...");
        priceOracle = new PriceOracle(QIE_CHAIN_ID);
        console.log("   PriceOracle deployed at:", address(priceOracle));
        console.log("   Initialized with BTC, ETH, BNB, SOL, and QIE price feeds");

        // 3. Deploy Vault first
        console.log("\n3. Deploying Vault...");
        vault = new Vault(feeRecipient);
        console.log("   Vault deployed at:", address(vault));

        // Whitelist collateral token in Vault
        console.log("   Whitelisting collateral token in Vault...");
        vault.whitelistToken(
            collateralToken,
            USDT_DECIMALS,
            5000, // 50% weight
            true  // is stable
        );

        // 4. Deploy Perpetual Trading
        console.log("\n4. Deploying Perpetual Trading...");
        perpetualTrading = new PerpetualTrading(
            address(priceOracle),
            address(vault),
            collateralToken,
            USDT_DECIMALS,
            feeRecipient
        );
        console.log("   PerpetualTrading deployed at:", address(perpetualTrading));
        
        // Authorize PerpetualTrading to use Vault
        console.log("   Authorizing PerpetualTrading in Vault...");
        vault.authorizeContract(address(perpetualTrading));

        // 5. Deploy Spot Market
        console.log("\n5. Deploying Spot Market...");
        spotMarket = new SpotMarket(feeRecipient);
        console.log("   SpotMarket deployed at:", address(spotMarket));

        // 6. Deploy Staking
        console.log("\n6. Deploying Staking...");
        staking = new Staking(
            address(platformToken),
            address(platformToken) // Reward token same as platform token
        );
        console.log("   Staking deployed at:", address(staking));

        // 7. Deploy Governance
        console.log("\n7. Deploying Governance...");
        governance = new Governance(
            address(platformToken),
            guardian
        );
        console.log("   Governance deployed at:", address(governance));

        // 8. Deploy Liquidity Mining
        console.log("\n8. Deploying Liquidity Mining...");
        uint256 rewardPerSecond = 1 * 10**18; // 1 token per second
        liquidityMining = new LiquidityMining(
            address(platformToken),
            address(spotMarket),
            rewardPerSecond,
            feeRecipient
        );
        console.log("   LiquidityMining deployed at:", address(liquidityMining));

        // 9. Deploy Reward Distributor
        console.log("\n9. Deploying Reward Distributor...");
        rewardDistributor = new RewardDistributor(
            address(vault),
            address(staking),
            treasury,
            feeRecipient // buyback contract placeholder
        );
        console.log("   RewardDistributor deployed at:", address(rewardDistributor));

        // Add collateral token as reward token
        rewardDistributor.addRewardToken(collateralToken);

        // 10. Allocate tokens for rewards
        console.log("\n10. Allocating tokens for rewards...");
        uint256 stakingRewards = 20_000_000 * 10**18; // 20M for staking
        uint256 liquidityMiningRewards = 30_000_000 * 10**18; // 30M for liquidity mining

        platformToken.transfer(address(staking), stakingRewards);
        platformToken.transfer(address(liquidityMining), liquidityMiningRewards);

        console.log("   Staking rewards:", stakingRewards / 10**18, "PDX");
        console.log("   Liquidity mining rewards:", liquidityMiningRewards / 10**18, "PDX");

        // 11. Set reward rates
        uint256 stakingRewardRate = stakingRewards / (365 days); // 1 year vesting
        staking.setRewardRate(stakingRewardRate);
        console.log("   Staking reward rate set:", stakingRewardRate);

        // Tokens already transferred in step 10, no need to deposit again

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
        console.log("DEPLOYMENT SUMMARY - QIE BLOCKCHAIN");
        console.log("========================================");
        console.log("PlatformToken (PDX):", address(platformToken));
        console.log("PriceOracle:", address(priceOracle));
        console.log("PerpetualTrading:", address(perpetualTrading));
        console.log("SpotMarket:", address(spotMarket));
        console.log("Staking:", address(staking));
        console.log("Vault:", address(vault));
        console.log("Governance:", address(governance));
        console.log("LiquidityMining:", address(liquidityMining));
        console.log("RewardDistributor:", address(rewardDistributor));
        console.log("========================================\n");
    }

    function _saveDeploymentAddresses() internal {
        string memory json = "deployments";

        vm.serializeAddress(json, "PlatformToken", address(platformToken));
        vm.serializeAddress(json, "PriceOracle", address(priceOracle));
        vm.serializeAddress(json, "PerpetualTrading", address(perpetualTrading));
        vm.serializeAddress(json, "SpotMarket", address(spotMarket));
        vm.serializeAddress(json, "Staking", address(staking));
        vm.serializeAddress(json, "Vault", address(vault));
        vm.serializeAddress(json, "Governance", address(governance));
        vm.serializeAddress(json, "LiquidityMining", address(liquidityMining));
        string memory finalJson = vm.serializeAddress(json, "RewardDistributor", address(rewardDistributor));

        string memory path = "./deployments/qie-1990.json";
        vm.writeJson(finalJson, path);
        console.log("Deployment addresses saved to:", path);
    }

    function _printNextSteps() internal pure {
        console.log("\n========================================");
        console.log("NEXT STEPS");
        console.log("========================================");
        console.log("1. Verify contracts on QIE Explorer:");
        console.log("   https://mainnet.qie.digital");
        console.log("");
        console.log("2. Run price oracle verification:");
        console.log("   cd scripts && node verifyPriceOracle.js");
        console.log("");
        console.log("3. Create spot market pools for trading pairs");
        console.log("");
        console.log("4. Add liquidity mining pools with allocation points");
        console.log("");
        console.log("5. Test perpetual trading:");
        console.log("   - Open BTC, ETH, BNB, SOL, or QIE positions");
        console.log("   - Test liquidations");
        console.log("   - Verify funding rates");
        console.log("");
        console.log("6. Set up frontend with deployed addresses");
        console.log("========================================\n");
    }
}
