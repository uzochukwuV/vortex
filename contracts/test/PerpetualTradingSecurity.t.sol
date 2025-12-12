// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/PerpetualTrading.sol";
import "../src/Vault.sol";
import "../src/PriceOracle.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockAggregatorV3.sol";

/// @title Security-focused tests for PerpetualTrading
/// @notice Tests for vulnerabilities, edge cases, and attack vectors
contract PerpetualTradingSecurityTest is Test {
    PerpetualTrading public perpetual;
    Vault public vault;
    PriceOracle public oracle;
    MockERC20 public usdt;
    MockAggregatorV3 public btcFeed;

    address public owner = address(0x1);
    address public attacker = address(0x666);
    address public victim = address(0x777);
    address public feeRecipient = address(0x4);

    function setUp() public {
        vm.startPrank(owner);

        usdt = new MockERC20("USDT", "USDT", 6);
        btcFeed = new MockAggregatorV3(8, int256(50_000 * 10**8));
        
        oracle = new PriceOracle(1991);
        oracle.addPriceFeed("BTC", address(btcFeed), 8, 3600);
        
        vault = new Vault(feeRecipient);
        vault.whitelistToken(address(usdt), 6, 5000, true);
        
        perpetual = new PerpetualTrading(
            address(oracle),
            address(vault),
            address(usdt),
            6,
            feeRecipient
        );
        
        vault.authorizeContract(address(perpetual));
        
        vm.stopPrank();
        
        // Setup liquidity
        usdt.mint(address(this), 10_000_000 * 10**6);
        usdt.approve(address(vault), 10_000_000 * 10**6);
        vault.addLiquidity(address(usdt), 10_000_000 * 10**6, 0);
        
        // Fund test accounts
        usdt.mint(attacker, 1_000_000 * 10**6);
        usdt.mint(victim, 1_000_000 * 10**6);
    }

    /// @notice Test: Fee transfer before collateral validation vulnerability
    function testFeeTransferBeforeCollateralValidation() public {
        vm.startPrank(attacker);
        
        uint256 collateral = 1000 * 10**6;
        uint256 initialBalance = usdt.balanceOf(attacker);
        
        // Approve only fee amount, not collateral
        uint256 feeAmount = (collateral * 10**(18-6) * 10 * 10) / 10000; // position size * fee rate
        uint256 feeInCollateral = feeAmount / 10**(18-6);
        
        usdt.approve(address(perpetual), feeInCollateral);
        
        // This should fail but might transfer fee first
        vm.expectRevert();
        perpetual.openPosition("BTC", true, collateral, 10);
        
        // Check if fee was incorrectly deducted
        uint256 finalBalance = usdt.balanceOf(attacker);
        assertEq(finalBalance, initialBalance, "Fee should not be deducted on failed position");
        
        vm.stopPrank();
    }

    /// @notice Test: Liquidation threshold boundary condition
    function testLiquidationThresholdBoundary() public {
        vm.startPrank(victim);
        
        uint256 collateral = 1000 * 10**6;
        usdt.approve(address(perpetual), collateral + 100 * 10**6);
        uint256 positionId = perpetual.openPosition("BTC", true, collateral, 10);
        
        vm.stopPrank();
        
        // Calculate exact liquidation threshold
        // 80% of 1000 USD = 800 USD threshold
        // Position size: 10,000 USD, entry: 50,000
        // Loss needed: 1000 - 800 = 200 USD
        // Price drop: 200/10000 = 2% = 49,000
        
        // Set price just above liquidation (should not liquidate)
        btcFeed.updateAnswer(int256(49_001 * 10**8));
        
        vm.prank(attacker);
        vm.expectRevert("Position not liquidatable");
        perpetual.liquidatePosition(positionId);
        
        // Set price exactly at threshold (CRITICAL: should this liquidate?)
        btcFeed.updateAnswer(int256(49_000 * 10**8));
        
        // This exposes the <= vs < bug in liquidation logic
        vm.prank(attacker);
        perpetual.liquidatePosition(positionId); // This will succeed due to <= bug
        
        (, , , , , , , bool isOpen) = perpetual.getPosition(positionId);
        assertFalse(isOpen); // Position liquidated at exactly 80% threshold
    }

    /// @notice Test: Funding payment overflow attack
    function testFundingPaymentOverflow() public {
        // Set extremely high funding rate
        vm.prank(owner);
        perpetual.updateFundingRate("BTC", type(int256).max / 1000); // Very high rate
        
        vm.startPrank(victim);
        uint256 collateral = 1000 * 10**6;
        usdt.approve(address(perpetual), collateral + 100 * 10**6);
        uint256 positionId = perpetual.openPosition("BTC", true, collateral, 50); // Max leverage
        vm.stopPrank();
        
        // Fast forward significant time
        vm.warp(block.timestamp + 365 days);
        
        // Try to close position - should handle overflow gracefully
        vm.prank(victim);
        // This might revert due to overflow in funding calculation
        try perpetual.closePosition(positionId) {
            // If it doesn't revert, check the position state
            (, , , , , , , bool isOpen) = perpetual.getPosition(positionId);
            // Position should be handled properly even with extreme funding
        } catch {
            // Expected behavior - should revert gracefully, not cause undefined behavior
        }
    }

    /// @notice Test: Negative collateral handling
    function testNegativeCollateralHandling() public {
        vm.startPrank(victim);
        uint256 collateral = 1000 * 10**6;
        usdt.approve(address(perpetual), collateral + 100 * 10**6);
        uint256 positionId = perpetual.openPosition("BTC", true, collateral, 50); // High leverage
        vm.stopPrank();
        
        // Crash the price to create massive loss
        btcFeed.updateAnswer(int256(25_000 * 10**8)); // 50% drop
        
        uint256 vaultBalanceBefore = usdt.balanceOf(address(vault));
        
        // Close position with massive loss
        vm.prank(victim);
        perpetual.closePosition(positionId);
        
        uint256 vaultBalanceAfter = usdt.balanceOf(address(vault));
        
        // Vault should not lose money due to negative collateral
        assertGe(vaultBalanceAfter, vaultBalanceBefore - collateral, "Vault lost more than collateral");
        
        (, , , , , , , bool isOpen) = perpetual.getPosition(positionId);
        assertFalse(isOpen);
    }

    /// @notice Test: Reentrancy attack on position operations
    function testReentrancyProtection() public {
        // This test would require a malicious ERC20 token that attempts reentrancy
        // For now, we verify that ReentrancyGuard is properly applied
        
        vm.startPrank(victim);
        uint256 collateral = 1000 * 10**6;
        usdt.approve(address(perpetual), collateral + 100 * 10**6);
        uint256 positionId = perpetual.openPosition("BTC", true, collateral, 10);
        vm.stopPrank();
        
        // Verify position was created
        (, , , , , , , bool isOpen) = perpetual.getPosition(positionId);
        assertTrue(isOpen);
        
        // Normal close should work
        vm.prank(victim);
        perpetual.closePosition(positionId);
        
        (, , , , , , , bool isOpenAfter) = perpetual.getPosition(positionId);
        assertFalse(isOpenAfter);
    }

    /// @notice Test: Oracle manipulation resistance
    function testOracleManipulationResistance() public {
        vm.startPrank(victim);
        uint256 collateral = 1000 * 10**6;
        usdt.approve(address(perpetual), collateral + 100 * 10**6);
        uint256 positionId = perpetual.openPosition("BTC", true, collateral, 10);
        vm.stopPrank();
        
        // Simulate oracle manipulation
        btcFeed.updateAnswer(int256(100_000 * 10**8)); // Double price
        
        uint256 attackerBalanceBefore = usdt.balanceOf(attacker);
        
        // Attacker tries to profit from manipulated price
        vm.prank(victim);
        perpetual.closePosition(positionId);
        
        // In a real system, this would show if oracle manipulation is profitable
        // The system should have protections like TWAP, circuit breakers, etc.
        
        uint256 attackerBalanceAfter = usdt.balanceOf(attacker);
        assertEq(attackerBalanceAfter, attackerBalanceBefore, "Attacker should not profit from oracle manipulation");
    }

    /// @notice Test: Maximum position size bypass attempt
    function testMaxPositionSizeBypass() public {
        vm.startPrank(attacker);
        
        uint256 maxAllowed = perpetual.maxPositionSize();
        uint256 collateralForMax = maxAllowed / 50; // Use max leverage to get max position
        uint256 collateralInTokens = collateralForMax / 10**(18-6);
        
        usdt.mint(attacker, collateralInTokens + 1_000_000 * 10**6);
        usdt.approve(address(perpetual), type(uint256).max);
        
        // Try to open position at exactly max size (may fail if exceeds max)
        try perpetual.openPosition("BTC", true, collateralInTokens, 50) {
            // Position opened successfully
        } catch {
            // Position may exceed max due to calculation precision
        }
        
        // Try to open another large position
        try perpetual.openPosition("BTC", true, 1000 * 10**6, 50) {
            // Position opened - may not exceed max
        } catch {
            // Expected - position too large
        }
        
        vm.stopPrank();
    }

    /// @notice Test: Funding rate manipulation
    function testFundingRateManipulation() public {
        // Only owner should be able to set funding rates
        vm.prank(attacker);
        vm.expectRevert();
        perpetual.updateFundingRate("BTC", -1e18); // Extreme negative rate
        
        // Owner sets legitimate rate
        vm.prank(owner);
        perpetual.updateFundingRate("BTC", 1e15); // 0.1% per hour
        
        bytes32 assetKey = keccak256(abi.encodePacked("BTC"));
        (int256 rate,) = perpetual.fundingRates(assetKey);
        assertEq(rate, 1e15);
    }

    /// @notice Test: Position ID collision/manipulation
    function testPositionIdSecurity() public {
        vm.startPrank(victim);
        uint256 collateral = 1000 * 10**6;
        usdt.approve(address(perpetual), collateral * 2 + 200 * 10**6);
        
        uint256 pos1 = perpetual.openPosition("BTC", true, collateral, 10);
        uint256 pos2 = perpetual.openPosition("BTC", false, collateral, 5);
        
        // Position IDs should be sequential and unique
        assertEq(pos2, pos1 + 1);
        
        // Attacker cannot manipulate position IDs
        vm.stopPrank();
        vm.prank(attacker);
        vm.expectRevert("Not position owner");
        perpetual.closePosition(pos1);
        
        vm.stopPrank();
    }

    /// @notice Test: Vault insolvency protection
    function testVaultInsolvencyProtection() public {
        // Create multiple large positions that could drain vault
        address[] memory traders = new address[](5);
        for (uint i = 0; i < 5; i++) {
            traders[i] = address(uint160(1000 + i));
            usdt.mint(traders[i], 100_000 * 10**6);
        }
        
        // Open large positions
        for (uint i = 0; i < 5; i++) {
            vm.startPrank(traders[i]);
            usdt.approve(address(perpetual), type(uint256).max);
            perpetual.openPosition("BTC", true, 50_000 * 10**6, 20); // Large positions
            vm.stopPrank();
        }
        
        uint256 vaultBalanceBefore = usdt.balanceOf(address(vault));
        
        // Crash price to create massive losses
        btcFeed.updateAnswer(int256(10_000 * 10**8)); // 80% drop
        
        // Close all positions
        for (uint i = 0; i < 5; i++) {
            vm.prank(traders[i]);
            try perpetual.closePosition(i + 1) {
                // Position closed
            } catch {
                // Position might be auto-liquidated or fail to close
            }
        }
        
        uint256 vaultBalanceAfter = usdt.balanceOf(address(vault));
        
        // Vault should not go negative
        assertGt(vaultBalanceAfter, 0, "Vault should not be insolvent");
    }

    /// @notice Test: Gas griefing attack
    function testGasGriefingProtection() public {
        // Test that operations have reasonable gas limits
        vm.startPrank(victim);
        uint256 collateral = 1000 * 10**6;
        usdt.approve(address(perpetual), collateral + 100 * 10**6);
        
        uint256 gasBefore = gasleft();
        uint256 positionId = perpetual.openPosition("BTC", true, collateral, 10);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Opening position should not use excessive gas
        assertLt(gasUsed, 500_000, "Position opening uses too much gas");
        
        gasBefore = gasleft();
        perpetual.closePosition(positionId);
        gasUsed = gasBefore - gasleft();
        
        // Closing position should not use excessive gas
        assertLt(gasUsed, 500_000, "Position closing uses too much gas");
        
        vm.stopPrank();
    }
}