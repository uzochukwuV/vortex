# Chainlink Price Feed Integration on Base Chain

## Overview

This document provides comprehensive guidance for integrating Chainlink price feeds into a perpetual DEX on Base mainnet. Chainlink is the industry-standard decentralized oracle network, providing reliable and manipulation-resistant price data essential for perpetual trading platforms.

## Key Findings

### 1. Available Chainlink Price Feeds on Base Mainnet

#### Major Trading Pairs

**BTC/USD:**
- Standard Proxy Address: `0x64c9...848F`
- AAVE SVR Proxy: `0x3A93...d446`
- ENS: `btc-usd.data.eth`
- Decimals: 8
- Heartbeat: ~1 hour (3600 seconds)

**ETH/USD:**
- Standard Proxy Address: `0x7104...Bb70`
- AAVE SVR Proxy: `0x9dA0...fCc8`
- ENS: `eth-usd.data.eth`
- Decimals: 8
- Heartbeat: ~1 hour (3600 seconds)

**LINK/USD:**
- Standard Proxy Address: `0x17CA...9D65`
- ENS: `link-usd.data.eth`
- Decimals: 8
- Heartbeat: ~1 hour (3600 seconds)

**Additional Feeds:**
Base mainnet supports numerous other price feeds including:
- Stablecoins (USDC/USD, USDT/USD, DAI/USD)
- Major altcoins (UNI, AAVE, CRV, etc.)
- Commodity-backed tokens
- Cross-chain assets

**Finding More Feeds:**
- Visit: https://docs.chain.link/data-feeds/price-feeds/addresses
- Filter by "Base Mainnet"
- Check feed details including decimals, heartbeat, and deviation threshold

### 2. Contract Addresses and Implementation Patterns

#### AggregatorV3Interface

**Standard Interface:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Base Mainnet
     * Aggregator: ETH/USD
     * Address: 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /* uint startedAt */,
            /* uint timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return price;
    }
}
```

#### Multi-Feed Price Oracle

**Aggregating Multiple Feeds:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MultiAssetOracle {
    mapping(address => AggregatorV3Interface) public priceFeeds;
    mapping(address => uint256) public heartbeats;
    
    // Asset token address => Chainlink feed address
    constructor() {
        // ETH
        priceFeeds[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 
            AggregatorV3Interface(0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70);
        heartbeats[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 3600;
        
        // BTC (WBTC)
        priceFeeds[0x...] = 
            AggregatorV3Interface(0x64c9...848F);
        heartbeats[0x...] = 3600;
    }
    
    function getPrice(address asset) public view returns (
        int256 price,
        uint256 updatedAt,
        uint8 decimals
    ) {
        AggregatorV3Interface feed = priceFeeds[asset];
        require(address(feed) != address(0), "Feed not found");
        
        (
            /* uint80 roundID */,
            int256 answer,
            /* uint startedAt */,
            uint256 timestamp,
            /* uint80 answeredInRound */
        ) = feed.latestRoundData();
        
        return (answer, timestamp, feed.decimals());
    }
}
```

### 3. Fallback Mechanisms and Price Staleness Checks

#### Staleness Validation

**Implementation with Heartbeat Check:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceFeedWithStalenessCheck {
    AggregatorV3Interface public priceFeed;
    uint256 public immutable HEARTBEAT_INTERVAL;
    uint256 public immutable GRACE_PERIOD;
    
    error StalePrice(uint256 timeSinceUpdate);
    error InvalidPrice(int256 price);
    
    constructor(
        address _priceFeed,
        uint256 _heartbeatInterval,
        uint256 _gracePeriod
    ) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        HEARTBEAT_INTERVAL = _heartbeatInterval;
        GRACE_PERIOD = _gracePeriod; // Additional buffer beyond heartbeat
    }
    
    function getLatestPrice() public view returns (int256 price) {
        (
            uint80 roundID,
            int256 answer,
            /* uint256 startedAt */,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        // Check for stale price
        uint256 timeSinceUpdate = block.timestamp - updatedAt;
        if (timeSinceUpdate > HEARTBEAT_INTERVAL + GRACE_PERIOD) {
            revert StalePrice(timeSinceUpdate);
        }
        
        // Check for invalid price
        if (answer <= 0) {
            revert InvalidPrice(answer);
        }
        
        // Check for incomplete round
        require(answeredInRound >= roundID, "Stale round");
        
        return answer;
    }
    
    function getPriceWithTimestamp() public view returns (
        int256 price,
        uint256 timestamp
    ) {
        (
            uint80 roundID,
            int256 answer,
            /* uint256 startedAt */,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        uint256 timeSinceUpdate = block.timestamp - updatedAt;
        if (timeSinceUpdate > HEARTBEAT_INTERVAL + GRACE_PERIOD) {
            revert StalePrice(timeSinceUpdate);
        }
        
        if (answer <= 0) {
            revert InvalidPrice(answer);
        }
        
        require(answeredInRound >= roundID, "Stale round");
        
        return (answer, updatedAt);
    }
}
```

#### Multi-Source Fallback System

**Redundant Oracle Architecture:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RedundantOracle {
    struct PriceFeed {
        AggregatorV3Interface feed;
        uint256 heartbeat;
        uint8 priority; // Lower = higher priority
        bool active;
    }
    
    mapping(address => PriceFeed[]) public assetFeeds;
    uint256 public constant MAX_PRICE_DEVIATION = 200; // 2% in basis points
    
    error AllFeedsStale();
    error PriceDeviationTooHigh();
    
    function addFeed(
        address asset,
        address feedAddress,
        uint256 heartbeat,
        uint8 priority
    ) external {
        assetFeeds[asset].push(PriceFeed({
            feed: AggregatorV3Interface(feedAddress),
            heartbeat: heartbeat,
            priority: priority,
            active: true
        }));
    }
    
    function getPrice(address asset) public view returns (int256) {
        PriceFeed[] memory feeds = assetFeeds[asset];
        require(feeds.length > 0, "No feeds configured");
        
        int256[] memory prices = new int256[](feeds.length);
        uint256[] memory timestamps = new uint256[](feeds.length);
        uint256 validPrices = 0;
        
        // Collect prices from all active feeds
        for (uint256 i = 0; i < feeds.length; i++) {
            if (!feeds[i].active) continue;
            
            try feeds[i].feed.latestRoundData() returns (
                uint80,
                int256 price,
                uint256,
                uint256 updatedAt,
                uint80
            ) {
                // Check staleness
                if (block.timestamp - updatedAt <= feeds[i].heartbeat + 300) {
                    if (price > 0) {
                        prices[validPrices] = price;
                        timestamps[validPrices] = updatedAt;
                        validPrices++;
                    }
                }
            } catch {
                // Feed failed, continue to next
                continue;
            }
        }
        
        if (validPrices == 0) {
            revert AllFeedsStale();
        }
        
        // Use median price if multiple feeds available
        if (validPrices > 1) {
            return _median(prices, validPrices);
        }
        
        return prices[0];
    }
    
    function _median(
        int256[] memory prices,
        uint256 length
    ) internal pure returns (int256) {
        // Simple bubble sort for small arrays
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    int256 temp = prices[j];
                    prices[j] = prices[j + 1];
                    prices[j + 1] = temp;
                }
            }
        }
        
        if (length % 2 == 0) {
            return (prices[length / 2 - 1] + prices[length / 2]) / 2;
        } else {
            return prices[length / 2];
        }
    }
}
```

### 4. Best Practices for Oracle Integration

#### Circuit Breakers

**Price Deviation Limits:**
```solidity
contract OracleWithCircuitBreaker {
    int256 public lastValidPrice;
    uint256 public lastUpdateTime;
    uint256 public constant MAX_DEVIATION = 1000; // 10% in basis points
    
    error PriceDeviationExceeded(int256 oldPrice, int256 newPrice);
    
    function updatePrice(int256 newPrice) internal {
        if (lastValidPrice != 0) {
            int256 deviation = ((newPrice - lastValidPrice) * 10000) / lastValidPrice;
            if (deviation < 0) deviation = -deviation;
            
            if (uint256(deviation) > MAX_DEVIATION) {
                revert PriceDeviationExceeded(lastValidPrice, newPrice);
            }
        }
        
        lastValidPrice = newPrice;
        lastUpdateTime = block.timestamp;
    }
}
```

#### Time-Weighted Average Price (TWAP)

**TWAP Implementation:**
```solidity
contract TWAPOracle {
    struct PriceObservation {
        uint256 timestamp;
        int256 price;
    }
    
    PriceObservation[] public observations;
    uint256 public constant TWAP_PERIOD = 1 hours;
    uint256 public constant MIN_OBSERVATIONS = 3;
    
    AggregatorV3Interface public priceFeed;
    
    function recordPrice() external {
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            uint256 updatedAt,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        
        observations.push(PriceObservation({
            timestamp: updatedAt,
            price: price
        }));
        
        // Clean old observations
        _cleanOldObservations();
    }
    
    function getTWAP() public view returns (int256) {
        require(observations.length >= MIN_OBSERVATIONS, "Insufficient data");
        
        uint256 cutoffTime = block.timestamp - TWAP_PERIOD;
        int256 sum = 0;
        uint256 count = 0;
        
        for (uint256 i = observations.length; i > 0; i--) {
            if (observations[i - 1].timestamp < cutoffTime) break;
            sum += observations[i - 1].price;
            count++;
        }
        
        require(count >= MIN_OBSERVATIONS, "Insufficient recent data");
        return sum / int256(count);
    }
    
    function _cleanOldObservations() internal {
        uint256 cutoffTime = block.timestamp - TWAP_PERIOD - 1 hours;
        uint256 keepFrom = 0;
        
        for (uint256 i = 0; i < observations.length; i++) {
            if (observations[i].timestamp >= cutoffTime) {
                keepFrom = i;
                break;
            }
        }
        
        if (keepFrom > 0) {
            for (uint256 i = keepFrom; i < observations.length; i++) {
                observations[i - keepFrom] = observations[i];
            }
            for (uint256 i = 0; i < keepFrom; i++) {
                observations.pop();
            }
        }
    }
}
```

#### Price Normalization

**Handling Different Decimals:**
```solidity
contract PriceNormalizer {
    uint8 public constant TARGET_DECIMALS = 18;
    
    function normalizePrice(
        int256 price,
        uint8 feedDecimals
    ) public pure returns (uint256) {
        require(price > 0, "Invalid price");
        
        if (feedDecimals < TARGET_DECIMALS) {
            return uint256(price) * 10 ** (TARGET_DECIMALS - feedDecimals);
        } else if (feedDecimals > TARGET_DECIMALS) {
            return uint256(price) / 10 ** (feedDecimals - TARGET_DECIMALS);
        }
        
        return uint256(price);
    }
    
    function denormalizePrice(
        uint256 normalizedPrice,
        uint8 targetDecimals
    ) public pure returns (uint256) {
        if (TARGET_DECIMALS < targetDecimals) {
            return normalizedPrice * 10 ** (targetDecimals - TARGET_DECIMALS);
        } else if (TARGET_DECIMALS > targetDecimals) {
            return normalizedPrice / 10 ** (TARGET_DECIMALS - targetDecimals);
        }
        
        return normalizedPrice;
    }
}
```

## Recommendations

### 1. Multi-Layer Oracle Strategy

**Primary Layer:**
- Use Chainlink as primary oracle source
- Implement staleness checks with appropriate heartbeat intervals
- Add grace period for network congestion

**Secondary Layer:**
- Integrate backup oracle sources (Pyth, API3, etc.)
- Use median pricing when multiple sources available
- Automatic fallback on primary failure

**Tertiary Layer:**
- TWAP from on-chain DEX prices (Uniswap V3)
- Only for emergency scenarios
- Require governance approval to activate

### 2. Monitoring and Alerting

**Real-time Monitoring:**
- Track oracle update frequency
- Monitor price deviations
- Alert on staleness or failures
- Dashboard for oracle health metrics

**Automated Responses:**
- Pause trading on oracle failures
- Reduce position limits during degraded oracle performance
- Automatic fallback activation

### 3. Gas Optimization

**Efficient Price Fetching:**
- Cache prices when appropriate
- Batch oracle calls
- Use view functions for read-only operations
- Minimize storage writes

### 4. Security Considerations

**Oracle Manipulation Prevention:**
- Never use single-block prices for critical operations
- Implement TWAP for liquidations
- Use multiple oracle sources
- Add circuit breakers for extreme price movements

**Access Control:**
- Restrict oracle configuration to governance
- Timelock for oracle changes
- Multi-sig for emergency oracle updates

## Implementation Notes

### Dependencies

```json
{
  "dependencies": {
    "@chainlink/contracts": "^0.8.0",
    "@openzeppelin/contracts": "^5.0.0"
  }
}
```

### Installation

```bash
npm install @chainlink/contracts
```

### Testing

**Mock Oracle for Testing:**
```solidity
contract MockChainlinkOracle is AggregatorV3Interface {
    int256 private _price;
    uint256 private _updatedAt;
    uint8 private _decimals;
    
    constructor(int256 initialPrice, uint8 decimals_) {
        _price = initialPrice;
        _decimals = decimals_;
        _updatedAt = block.timestamp;
    }
    
    function setPrice(int256 newPrice) external {
        _price = newPrice;
        _updatedAt = block.timestamp;
    }
    
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, _price, _updatedAt, _updatedAt, 1);
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }
}
```

## Sources

- [Chainlink Data Feeds Documentation](https://docs.chain.link/data-feeds/price-feeds/addresses)
- [Chainlink Base Mainnet Feeds](https://data.chain.link/feeds/base/mainnet)
- [AggregatorV3Interface Reference](https://docs.chain.link/data-feeds/api-reference)
- [Chainlink ENS Integration](https://docs.chain.link/data-feeds/ens)

## Next Steps

1. Deploy oracle contracts to Base testnet
2. Test staleness checks and fallback mechanisms
3. Integrate with position management system
4. Set up monitoring and alerting infrastructure
5. Conduct oracle manipulation attack simulations
