// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/mocks/MockV3Aggregator.sol";
import "../src/PriceOracle.sol";

contract MockV3AggregatorTest is Test {
    MockV3Aggregator public aggregator;
    PriceOracle public oracle;
    
    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 50_000 * 10**8; // $50k
    
    function setUp() public {
        aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        oracle = new PriceOracle(1991); // QIE testnet
    }

    function testInitialState() public {
        assertEq(aggregator.decimals(), DECIMALS);
        assertEq(aggregator.version(), 1);
        assertEq(aggregator.description(), "Mock Chainlink Aggregator");
        
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = aggregator.latestRoundData();
        
        assertEq(answer, INITIAL_PRICE);
        assertEq(roundId, 1);
        assertEq(answeredInRound, 1);
        assertEq(startedAt, updatedAt);
        assertGt(updatedAt, 0);
    }

    function testUpdateAnswer() public {
        int256 newPrice = 55_000 * 10**8; // $55k
        
        aggregator.updateAnswer(newPrice);
        
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = aggregator.latestRoundData();
        
        assertEq(answer, newPrice);
        assertEq(roundId, 2); // Should increment
        assertEq(answeredInRound, 2);
        assertEq(updatedAt, block.timestamp);
    }

    function testUpdateRoundData() public {
        uint80 customRoundId = 100;
        int256 customPrice = 60_000 * 10**8;
        uint256 customTimestamp = block.timestamp - 1000;
        
        aggregator.updateRoundData(customRoundId, customPrice, customTimestamp, customTimestamp);
        
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = aggregator.latestRoundData();
        
        assertEq(roundId, customRoundId);
        assertEq(answer, customPrice);
        assertEq(updatedAt, customTimestamp);
        assertEq(startedAt, customTimestamp);
        assertEq(answeredInRound, customRoundId);
    }

    function testGetRoundData() public {
        // Update to create round 2
        int256 price2 = 52_000 * 10**8;
        aggregator.updateAnswer(price2);
        
        // Get round 1 data
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = aggregator.getRoundData(1);
        
        assertEq(roundId, 1);
        assertEq(answer, INITIAL_PRICE);
        assertEq(answeredInRound, 1);
        
        // Get round 2 data
        (roundId, answer, startedAt, updatedAt, answeredInRound) = aggregator.getRoundData(2);
        
        assertEq(roundId, 2);
        assertEq(answer, price2);
        assertEq(answeredInRound, 2);
    }

    function testMultipleUpdates() public {
        int256[] memory prices = new int256[](3);
        prices[0] = 51_000 * 10**8;
        prices[1] = 52_000 * 10**8;
        prices[2] = 53_000 * 10**8;
        
        for (uint i = 0; i < prices.length; i++) {
            aggregator.updateAnswer(prices[i]);
            
            (uint80 roundId, int256 answer, , , ) = aggregator.latestRoundData();
            assertEq(answer, prices[i]);
            assertEq(roundId, i + 2); // Starts from round 2
        }
    }

    function testPriceOracleIntegration() public {
        // Add aggregator to oracle
        oracle.addPriceFeed("BTC", address(aggregator), DECIMALS, 3600);
        
        // Test getting price through oracle
        uint256 price = oracle.getLatestPrice("BTC");
        uint256 expectedPrice = uint256(INITIAL_PRICE) * 10**(18 - DECIMALS);
        
        assertEq(price, expectedPrice);
    }

    function testPriceOracleWithUpdate() public {
        oracle.addPriceFeed("BTC", address(aggregator), DECIMALS, 3600);
        
        // Update price
        int256 newPrice = 45_000 * 10**8;
        aggregator.updateAnswer(newPrice);
        
        // Get updated price through oracle
        uint256 price = oracle.getLatestPrice("BTC");
        uint256 expectedPrice = uint256(newPrice) * 10**(18 - DECIMALS);
        
        assertEq(price, expectedPrice);
    }

    function testStalePrice() public {
        oracle.addPriceFeed("BTC", address(aggregator), DECIMALS, 3600);
        
        // Set old timestamp
        uint256 oldTimestamp = block.timestamp - 7200; // 2 hours ago
        aggregator.updateRoundData(10, INITIAL_PRICE, oldTimestamp, oldTimestamp);
        
        // Should revert with "Price too old"
        vm.expectRevert("Price too old");
        oracle.getLatestPrice("BTC");
    }

    function testInvalidPrice() public {
        oracle.addPriceFeed("BTC", address(aggregator), DECIMALS, 3600);
        
        // Set negative price
        aggregator.updateAnswer(-1000);
        
        vm.expectRevert("Invalid price");
        oracle.getLatestPrice("BTC");
    }

    function testFuzzUpdateAnswer(int256 price) public {
        vm.assume(price > 0);
        vm.assume(price < type(int256).max / 10**18); // Prevent overflow
        
        aggregator.updateAnswer(price);
        
        (, int256 answer, , , ) = aggregator.latestRoundData();
        assertEq(answer, price);
    }
}