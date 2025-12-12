// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAggregatorV3.sol";

/// @title Price Oracle
/// @notice Manages Chainlink price feeds for different trading pairs
/// @dev Supports BTC/USD and ETH/USD on Base chain
contract PriceOracle is Ownable {
    /// @notice Price feed data structure
    struct PriceFeed {
        IAggregatorV3 feed;
        uint8 decimals;
        uint256 maxPriceAge; // Maximum age of price data in seconds
        bool isActive;
    }
    
    /// @notice Mapping of asset symbol to price feed
    mapping(bytes32 => PriceFeed) public priceFeeds;
    
    /// @notice Default maximum price age (1 hour)
    uint256 public constant DEFAULT_MAX_PRICE_AGE = 3600;
    
    /// @notice Emitted when a price feed is added or updated
    event PriceFeedUpdated(bytes32 indexed asset, address indexed feed, uint8 decimals);
    
    /// @notice Emitted when a price feed is deactivated
    event PriceFeedDeactivated(bytes32 indexed asset);
    
    /// @param chainId Current chain ID for multi-chain support
    constructor(uint256 chainId) Ownable(msg.sender) {
        // Initialize price feeds for Base chain (chainId 8453)
        if (chainId == 8453) {
            // BTC/USD on Base Mainnet
            _addPriceFeed(
                "BTC",
                0x64c911848f3f3681cEDf1C79C3a2E9255A7E5F1a,
                8,
                DEFAULT_MAX_PRICE_AGE
            );

            // ETH/USD on Base Mainnet
            _addPriceFeed(
                "ETH",
                0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70,
                8,
                DEFAULT_MAX_PRICE_AGE
            );
        }
        // QIE Blockchain (chainId 1990)
        else if (chainId == 1990) {
            // BTC/USD on QIE Mainnet
            _addPriceFeed(
                "BTC",
                0x9E596d809a20A272c788726f592c0d1629755440,
                8,
                DEFAULT_MAX_PRICE_AGE
            );

            // ETH/USD on QIE Mainnet
            _addPriceFeed(
                "ETH",
                0x4bb7012Fbc79fE4Ae9B664228977b442b385500d,
                8,
                DEFAULT_MAX_PRICE_AGE
            );

            // BNB/USD on QIE Mainnet
            _addPriceFeed(
                "BNB",
                0x775A56117Fdb8b31877E75Ceeb68C96765b031e6,
                8,
                DEFAULT_MAX_PRICE_AGE
            );

            // SOL/USD on QIE Mainnet
            _addPriceFeed(
                "SOL",
                0xe86999c8e6C8eeF71bebd35286bCa674E0AD7b21,
                8,
                DEFAULT_MAX_PRICE_AGE
            );

            // QIE/USD on QIE Mainnet
            _addPriceFeed(
                "QIE",
                0x3Bc617cF3A4Bb77003e4c556B87b13D556903D17,
                8,
                DEFAULT_MAX_PRICE_AGE
            );
        }
        // QIE Testnet (chainId 1991)
        // Price feeds will be added manually via deployment script with mock aggregators
    }
    
    /// @notice Add or update a price feed
    /// @param asset Asset symbol (e.g., "BTC", "ETH")
    /// @param feedAddress Chainlink price feed address
    /// @param decimals Number of decimals in the price feed
    /// @param maxPriceAge Maximum acceptable age of price data
    function addPriceFeed(
        string memory asset,
        address feedAddress,
        uint8 decimals,
        uint256 maxPriceAge
    ) external onlyOwner {
        _addPriceFeed(asset, feedAddress, decimals, maxPriceAge);
    }
    
    /// @notice Internal function to add price feed
    function _addPriceFeed(
        string memory asset,
        address feedAddress,
        uint8 decimals,
        uint256 maxPriceAge
    ) internal {
        require(feedAddress != address(0), "Invalid feed address");
        require(decimals > 0, "Invalid decimals");
        require(maxPriceAge > 0, "Invalid max price age");
        
        bytes32 assetKey = keccak256(abi.encodePacked(asset));
        
        priceFeeds[assetKey] = PriceFeed({
            feed: IAggregatorV3(feedAddress),
            decimals: decimals,
            maxPriceAge: maxPriceAge,
            isActive: true
        });
        
        emit PriceFeedUpdated(assetKey, feedAddress, decimals);
    }
    
    /// @notice Deactivate a price feed
    /// @param asset Asset symbol to deactivate
    function deactivatePriceFeed(string memory asset) external onlyOwner {
        bytes32 assetKey = keccak256(abi.encodePacked(asset));
        require(priceFeeds[assetKey].isActive, "Feed not active");
        
        priceFeeds[assetKey].isActive = false;
        emit PriceFeedDeactivated(assetKey);
    }
    
    /// @notice Get latest price for an asset
    /// @param asset Asset symbol (e.g., "BTC", "ETH")
    /// @return price Latest price scaled to 18 decimals
    function getLatestPrice(string memory asset) external view returns (uint256 price) {
        bytes32 assetKey = keccak256(abi.encodePacked(asset));
        PriceFeed memory priceFeed = priceFeeds[assetKey];
        
        require(priceFeed.isActive, "Price feed not active");
        
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.feed.latestRoundData();
        
        require(answer > 0, "Invalid price");
        require(updatedAt > 0, "Invalid timestamp");
        require(answeredInRound >= roundId, "Stale price");
        require(block.timestamp - updatedAt <= priceFeed.maxPriceAge, "Price too old");
        
        // Scale price to 18 decimals
        price = uint256(answer) * 10**(18 - priceFeed.decimals);
    }
    
    /// @notice Get price feed info
    /// @param asset Asset symbol
    /// @return feedAddress Address of the price feed
    /// @return decimals Decimals of the price feed
    /// @return isActive Whether the feed is active
    function getPriceFeedInfo(string memory asset) 
        external 
        view 
        returns (
            address feedAddress,
            uint8 decimals,
            bool isActive
        ) 
    {
        bytes32 assetKey = keccak256(abi.encodePacked(asset));
        PriceFeed memory priceFeed = priceFeeds[assetKey];
        
        return (
            address(priceFeed.feed),
            priceFeed.decimals,
            priceFeed.isActive
        );
    }
}
