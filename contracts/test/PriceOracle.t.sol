// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/PriceOracle.sol";
import "../src/mocks/MockV3Aggregator.sol";
import "../src/interfaces/IAggregatorV3.sol";

// Mock aggregator that returns stale data
contract MockV3AggregatorStale is IAggregatorV3 {
    uint8 public override decimals;
    string public override description = "Stale Mock";
    uint256 public override version = 1;
    int256 private storedAnswer;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        storedAnswer = _initialAnswer > 0 ? _initialAnswer : int256(50000 * 10**8); // Ensure positive
    }
    
    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (10, storedAnswer, block.timestamp, block.timestamp, 5); // answeredInRound < roundId
    }

    function getRoundData(uint80) external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (10, storedAnswer, block.timestamp, block.timestamp, 5);
    }
}

contract PriceOracleTest is Test {
    PriceOracle public oracle;
    MockV3Aggregator public btcFeed;
    MockV3Aggregator public ethFeed;
    
    address public owner = address(0x1);
    address public user = address(0x2);
    
    uint8 constant DECIMALS = 8;
    int256 constant BTC_PRICE = 50_000 * 10**8;
    int256 constant ETH_PRICE = 3_000 * 10**8;
    
    function setUp() public {
        vm.startPrank(owner);
        
        oracle = new PriceOracle(1991); // QIE testnet
        btcFeed = new MockV3Aggregator(DECIMALS, BTC_PRICE);
        ethFeed = new MockV3Aggregator(DECIMALS, ETH_PRICE);
        
        vm.stopPrank();
    }

    function testAddPriceFeed() public {
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        
        (address feedAddress, uint8 decimals, bool isActive) = oracle.getPriceFeedInfo("BTC");
        
        assertEq(feedAddress, address(btcFeed));
        assertEq(decimals, DECIMALS);
        assertTrue(isActive);
    }

    function testAddPriceFeedUnauthorized() public {
        vm.prank(user);
        vm.expectRevert();
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
    }

    function testGetLatestPrice() public {
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        
        uint256 price = oracle.getLatestPrice("BTC");
        uint256 expectedPrice = uint256(BTC_PRICE) * 10**(18 - DECIMALS);
        
        assertEq(price, expectedPrice);
    }

    function testGetLatestPriceInactiveFeed() public {
        vm.startPrank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        oracle.deactivatePriceFeed("BTC");
        vm.stopPrank();
        
        vm.expectRevert("Price feed not active");
        oracle.getLatestPrice("BTC");
    }

    function testGetLatestPriceNonexistentFeed() public {
        vm.expectRevert("Price feed not active");
        oracle.getLatestPrice("NONEXISTENT");
    }

    function testDeactivatePriceFeed() public {
        vm.startPrank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        oracle.deactivatePriceFeed("BTC");
        vm.stopPrank();
        
        (, , bool isActive) = oracle.getPriceFeedInfo("BTC");
        assertFalse(isActive);
    }

    function testDeactivateNonexistentFeed() public {
        vm.prank(owner);
        vm.expectRevert("Feed not active");
        oracle.deactivatePriceFeed("NONEXISTENT");
    }

    function testMultipleAssets() public {
        vm.startPrank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        oracle.addPriceFeed("ETH", address(ethFeed), DECIMALS, 3600);
        vm.stopPrank();
        
        uint256 btcPrice = oracle.getLatestPrice("BTC");
        uint256 ethPrice = oracle.getLatestPrice("ETH");
        
        uint256 expectedBtcPrice = uint256(BTC_PRICE) * 10**(18 - DECIMALS);
        uint256 expectedEthPrice = uint256(ETH_PRICE) * 10**(18 - DECIMALS);
        
        assertEq(btcPrice, expectedBtcPrice);
        assertEq(ethPrice, expectedEthPrice);
    }

    function testPriceUpdate() public {
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        
        // Update price
        int256 newPrice = 55_000 * 10**8;
        btcFeed.updateAnswer(newPrice);
        
        uint256 price = oracle.getLatestPrice("BTC");
        uint256 expectedPrice = uint256(newPrice) * 10**(18 - DECIMALS);
        
        assertEq(price, expectedPrice);
    }

    function testStalePrice() public {
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 1); // 1 second max age
        
        // Wait 2 seconds
        vm.warp(block.timestamp + 2);
        
        vm.expectRevert("Price too old");
        oracle.getLatestPrice("BTC");
    }

    function testInvalidPrice() public {
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        
        // Set negative price
        btcFeed.updateAnswer(-1000);
        
        vm.expectRevert("Invalid price");
        oracle.getLatestPrice("BTC");
    }

    function testZeroPrice() public {
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        
        btcFeed.updateAnswer(0);
        
        vm.expectRevert("Invalid price");
        oracle.getLatestPrice("BTC");
    }

    function testInvalidTimestamp() public {
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        
        // Set invalid timestamp
        btcFeed.updateRoundData(1, BTC_PRICE, 0, 0);
        
        vm.expectRevert("Invalid timestamp");
        oracle.getLatestPrice("BTC");
    }

    function testStaleRound() public {
        // Create a custom mock that returns stale data with positive price
        MockV3AggregatorStale staleFeed = new MockV3AggregatorStale(DECIMALS, 50000 * 10**8);
        
        vm.prank(owner);
        oracle.addPriceFeed("BTC", address(staleFeed), DECIMALS, 3600);
        
        vm.expectRevert("Stale price");
        oracle.getLatestPrice("BTC");
    }

    function testDifferentDecimals() public {
        MockV3Aggregator feed18 = new MockV3Aggregator(18, 1000 * 10**18);
        MockV3Aggregator feed6 = new MockV3Aggregator(6, 1000 * 10**6);
        
        vm.startPrank(owner);
        oracle.addPriceFeed("TOKEN18", address(feed18), 18, 3600);
        oracle.addPriceFeed("TOKEN6", address(feed6), 6, 3600);
        vm.stopPrank();
        
        uint256 price18 = oracle.getLatestPrice("TOKEN18");
        uint256 price6 = oracle.getLatestPrice("TOKEN6");
        
        // Both should be scaled to 18 decimals
        assertEq(price18, 1000 * 10**18);
        assertEq(price6, 1000 * 10**18);
    }

    function testAddPriceFeedValidation() public {
        vm.startPrank(owner);
        
        // Invalid feed address
        vm.expectRevert("Invalid feed address");
        oracle.addPriceFeed("BTC", address(0), DECIMALS, 3600);
        
        // Invalid decimals
        vm.expectRevert("Invalid decimals");
        oracle.addPriceFeed("BTC", address(btcFeed), 0, 3600);
        
        // Invalid max price age
        vm.expectRevert("Invalid max price age");
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 0);
        
        vm.stopPrank();
    }

    function testUpdateExistingFeed() public {
        vm.startPrank(owner);
        
        // Add initial feed
        oracle.addPriceFeed("BTC", address(btcFeed), DECIMALS, 3600);
        
        // Update with new feed
        MockV3Aggregator newFeed = new MockV3Aggregator(DECIMALS, 60_000 * 10**8);
        oracle.addPriceFeed("BTC", address(newFeed), DECIMALS, 7200);
        
        vm.stopPrank();
        
        (address feedAddress, , ) = oracle.getPriceFeedInfo("BTC");
        assertEq(feedAddress, address(newFeed));
        
        uint256 price = oracle.getLatestPrice("BTC");
        uint256 expectedPrice = uint256(60_000 * 10**8) * 10**(18 - DECIMALS);
        assertEq(price, expectedPrice);
    }

    function testFuzzPriceScaling(uint8 feedDecimals, int256 rawPrice) public {
        vm.assume(feedDecimals > 0 && feedDecimals <= 18);
        vm.assume(rawPrice > 0);
        vm.assume(rawPrice < type(int256).max / 10**18);
        
        MockV3Aggregator testFeed = new MockV3Aggregator(feedDecimals, rawPrice);
        
        vm.prank(owner);
        oracle.addPriceFeed("TEST", address(testFeed), feedDecimals, 3600);
        
        uint256 price = oracle.getLatestPrice("TEST");
        uint256 expectedPrice = uint256(rawPrice) * 10**(18 - feedDecimals);
        
        assertEq(price, expectedPrice);
    }
}