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

/// @title Deployment Script
/// @notice Deploy all contracts for the GMX-style perpetual DEX on Base
contract DeployScript is Script {
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

    // Configuration
    uint256 public constant INITIAL_TOKEN_SUPPLY = 100_000_000 * 10**18; // 100M tokens
    uint8 public constant USDC_DECIMALS = 6;

    function run() external {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load configuration
        address collateralToken = vm.envAddress("COLLATERAL_TOKEN"); // USDC on Base
        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);
        address treasury = vm.envOr("TREASURY", deployer);
        address guardian = vm.envOr("GUARDIAN", deployer);

        console.log("Deploying contracts to Base chain...");
        console.log("Deployer:", deployer);
        console.log("Collateral Token (USDC):", collateralToken);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Platform Token
        console.log("\n1. Deploying Platform Token...");
        platformToken = new PlatformToken(INITIAL_TOKEN_SUPPLY);
        console.log("PlatformToken deployed at:", address(platformToken));

        // 2. Deploy Price Oracle
        console.log("\n2. Deploying Price Oracle...");
        priceOracle = new PriceOracle(block.chainid);
        console.log("PriceOracle deployed at:", address(priceOracle));

        // 3. Deploy Perpetual Trading
        console.log("\n3. Deploying Perpetual Trading...");
        perpetualTrading = new PerpetualTrading(
            address(priceOracle),
            address(0),
            collateralToken,
            USDC_DECIMALS,
            feeRecipient
        );
        console.log("PerpetualTrading deployed at:", address(perpetualTrading));

        // 4. Deploy Spot Market
        console.log("\n4. Deploying Spot Market...");
        spotMarket = new SpotMarket(feeRecipient);
        console.log("SpotMarket deployed at:", address(spotMarket));

        // 5. Deploy Staking
        console.log("\n5. Deploying Staking...");
        staking = new Staking(
            address(platformToken),
            address(platformToken) // Reward token same as platform token
        );
        console.log("Staking deployed at:", address(staking));

        // 6. Deploy Vault
        console.log("\n6. Deploying Vault...");
        vault = new Vault(feeRecipient);
        console.log("Vault deployed at:", address(vault));

        // Whitelist USDC in Vault
        vault.whitelistToken(
            collateralToken,
            USDC_DECIMALS,
            5000, // 50% weight
            true // is stable
        );

        // 7. Deploy Governance
        console.log("\n7. Deploying Governance...");
        governance = new Governance(
            address(platformToken),
            guardian
        );
        console.log("Governance deployed at:", address(governance));

        // 8. Deploy Liquidity Mining
        console.log("\n8. Deploying Liquidity Mining...");
        uint256 rewardPerSecond = 1 * 10**18; // 1 token per second
        liquidityMining = new LiquidityMining(
            address(platformToken),
            address(spotMarket),
            rewardPerSecond,
            feeRecipient
        );
        console.log("LiquidityMining deployed at:", address(liquidityMining));

        // 9. Deploy Reward Distributor
        console.log("\n9. Deploying Reward Distributor...");
        rewardDistributor = new RewardDistributor(
            address(vault),
            address(staking),
            treasury,
            feeRecipient // buyback contract placeholder
        );
        console.log("RewardDistributor deployed at:", address(rewardDistributor));

        // Add USDC as reward token
        rewardDistributor.addRewardToken(collateralToken);

        // 10. Transfer tokens for rewards
        console.log("\n10. Setting up token allocations...");
        uint256 stakingRewards = 20_000_000 * 10**18; // 20M for staking
        uint256 liquidityMiningRewards = 30_000_000 * 10**18; // 30M for liquidity mining

        platformToken.transfer(address(staking), stakingRewards);
        platformToken.transfer(address(liquidityMining), liquidityMiningRewards);

        console.log("Staking rewards allocated:", stakingRewards / 10**18);
        console.log("Liquidity mining rewards allocated:", liquidityMiningRewards / 10**18);

        // 11. Set reward rates
        uint256 stakingRewardRate = stakingRewards / (365 days); // 1 year vesting
        staking.setRewardRate(stakingRewardRate);
        console.log("Staking reward rate set:", stakingRewardRate);

        vm.stopBroadcast();

        // Print deployment summary
        _printDeploymentSummary();

        // Save deployment addresses
        _saveDeploymentAddresses();
    }

    function _printDeploymentSummary() internal view {
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("PlatformToken:", address(platformToken));
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

        string memory chainId = vm.toString(block.chainid);
        string memory path = string.concat("./deployments/", chainId, ".json");

        vm.writeJson(finalJson, path);
        console.log("Deployment addresses saved to:", path);
    }
}
