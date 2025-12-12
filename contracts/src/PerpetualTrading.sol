// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./PriceOracle.sol";
import "./Vault.sol";

/// @title Perpetual Trading Contract
/// @notice Manages perpetual futures positions with leverage
/// @dev Supports BTC/USD and ETH/USD perpetual positions with up to 50x leverage
contract PerpetualTrading is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    /// @notice Position structure
    struct Position {
        address trader;
        string asset; // "BTC" or "ETH"
        bool isLong;
        uint256 size; // Position size in USD (18 decimals)
        uint256 collateral; // Collateral in USD (18 decimals)
        uint256 leverage; // Leverage multiplier (e.g., 10 = 10x)
        uint256 entryPrice; // Entry price (18 decimals)
        uint256 lastFundingTime; // Last funding payment timestamp
        int256 accumulatedFunding; // Accumulated funding payments
        bool isOpen;
    }
    
    /// @notice Funding rate data
    struct FundingRate {
        int256 rate; // Funding rate per hour (18 decimals, can be negative)
        uint256 lastUpdateTime;
    }
    
    /// @notice Price oracle contract
    PriceOracle public immutable priceOracle;
    
    /// @notice Vault contract for liquidity
    Vault public immutable vault;
    
    /// @notice Collateral token (USDC or similar stablecoin)
    IERC20 public immutable collateralToken;
    
    /// @notice Collateral token decimals
    uint8 public immutable collateralDecimals;
    
    /// @notice Position counter
    uint256 public positionCounter;
    
    /// @notice Mapping of position ID to position data
    mapping(uint256 => Position) public positions;
    
    /// @notice Mapping of trader to their position IDs
    mapping(address => uint256[]) public traderPositions;
    
    /// @notice Funding rates for each asset
    mapping(bytes32 => FundingRate) public fundingRates;
    
    /// @notice Maximum leverage allowed
    uint256 public constant MAX_LEVERAGE = 50;
    
    /// @notice Minimum leverage allowed
    uint256 public constant MIN_LEVERAGE = 2;
    
    /// @notice Liquidation threshold (80% of collateral)
    uint256 public constant LIQUIDATION_THRESHOLD = 8000; // 80% in basis points
    
    /// @notice Liquidation fee (5% of position size)
    uint256 public constant LIQUIDATION_FEE = 500; // 5% in basis points
    
    /// @notice Trading fee (0.1% of position size)
    uint256 public tradingFee = 10; // 0.1% in basis points
    
    /// @notice Fee recipient
    address public feeRecipient;
    
    /// @notice Total open interest per asset
    mapping(bytes32 => uint256) public totalOpenInterestLong;
    mapping(bytes32 => uint256) public totalOpenInterestShort;
    
    /// @notice Maximum position size in USD
    uint256 public maxPositionSize = 10_000_000 * 10**18; // 10M USD
    
    /// @notice Events
    event PositionOpened(
        uint256 indexed positionId,
        address indexed trader,
        string asset,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 leverage,
        uint256 entryPrice
    );
    
    event PositionClosed(
        uint256 indexed positionId,
        address indexed trader,
        uint256 exitPrice,
        int256 pnl,
        uint256 collateralReturned
    );
    
    event PositionLiquidated(
        uint256 indexed positionId,
        address indexed trader,
        address indexed liquidator,
        uint256 liquidationPrice,
        uint256 liquidationFee
    );
    
    event FundingRateUpdated(string asset, int256 rate);
    
    event FundingPaid(uint256 indexed positionId, int256 amount);
    
    /// @param _priceOracle Price oracle contract address
    /// @param _vault Vault contract address
    /// @param _collateralToken Collateral token address
    /// @param _collateralDecimals Collateral token decimals
    /// @param _feeRecipient Fee recipient address
    constructor(
        address _priceOracle,
        address _vault,
        address _collateralToken,
        uint8 _collateralDecimals,
        address _feeRecipient
    ) Ownable(msg.sender) {
        require(_priceOracle != address(0), "Invalid oracle");
        require(_vault != address(0), "Invalid vault");
        require(_collateralToken != address(0), "Invalid collateral");
        require(_feeRecipient != address(0), "Invalid fee recipient");
        
        priceOracle = PriceOracle(_priceOracle);
        vault = Vault(_vault);
        collateralToken = IERC20(_collateralToken);
        collateralDecimals = _collateralDecimals;
        feeRecipient = _feeRecipient;
    }
    
    /// @notice Open a new perpetual position
    /// @param asset Asset symbol ("BTC" or "ETH")
    /// @param isLong True for long, false for short
    /// @param collateralAmount Collateral amount in collateral token units
    /// @param leverage Leverage multiplier
    function openPosition(
        string memory asset,
        bool isLong,
        uint256 collateralAmount,
        uint256 leverage
    ) external nonReentrant whenNotPaused returns (uint256 positionId) {
        require(leverage >= MIN_LEVERAGE && leverage <= MAX_LEVERAGE, "Invalid leverage");
        require(collateralAmount > 0, "Invalid collateral");
        
        // Get current price
        uint256 currentPrice = priceOracle.getLatestPrice(asset);
        
        // Convert collateral to USD (18 decimals)
        uint256 collateralUSD = collateralAmount * 10**(18 - collateralDecimals);
        
        // Calculate position size
        uint256 positionSize = collateralUSD * leverage;
        require(positionSize <= maxPositionSize, "Position too large");
        
        // Calculate and collect trading fee
        uint256 feeAmount = (positionSize * tradingFee) / 10000;
        uint256 feeInCollateral = feeAmount / 10**(18 - collateralDecimals);
        
        // Transfer collateral to vault, fee to recipient
        collateralToken.safeTransferFrom(msg.sender, address(vault), collateralAmount);
        collateralToken.safeTransferFrom(msg.sender, feeRecipient, feeInCollateral);
        
        // Notify vault of incoming collateral
        vault.transferIn(address(collateralToken), collateralAmount);
        
        // Reserve liquidity in vault for this position
        vault.increaseReservedAmount(address(collateralToken), positionSize / 10**(18 - collateralDecimals));
        
        // Create position
        positionId = ++positionCounter;
        positions[positionId] = Position({
            trader: msg.sender,
            asset: asset,
            isLong: isLong,
            size: positionSize,
            collateral: collateralUSD,
            leverage: leverage,
            entryPrice: currentPrice,
            lastFundingTime: block.timestamp,
            accumulatedFunding: 0,
            isOpen: true
        });
        
        traderPositions[msg.sender].push(positionId);
        
        // Update open interest
        bytes32 assetKey = keccak256(abi.encodePacked(asset));
        if (isLong) {
            totalOpenInterestLong[assetKey] += positionSize;
        } else {
            totalOpenInterestShort[assetKey] += positionSize;
        }
        
        emit PositionOpened(
            positionId,
            msg.sender,
            asset,
            isLong,
            positionSize,
            collateralUSD,
            leverage,
            currentPrice
        );
    }
    
    /// @notice Close an existing position
    /// @param positionId Position ID to close
    function closePosition(uint256 positionId) external nonReentrant whenNotPaused {
        Position storage position = positions[positionId];
        require(position.isOpen, "Position not open");
        require(position.trader == msg.sender, "Not position owner");
        
        // Get current price
        uint256 currentPrice = priceOracle.getLatestPrice(position.asset);
        
        // Calculate and apply funding payment
        int256 fundingPayment = _calculateFundingPayment(positionId);

        // Update accumulated funding and last funding time
        position.accumulatedFunding += fundingPayment;
        position.lastFundingTime = block.timestamp;

        // Calculate PnL
        int256 pnl = _calculatePnL(position, currentPrice);
        pnl -= position.accumulatedFunding; // Subtract total accumulated funding payments
        
        // Calculate final collateral
        int256 finalCollateral = int256(position.collateral) + pnl;
        
        // Calculate trading fee
        uint256 feeAmount = (position.size * tradingFee) / 10000;
        finalCollateral -= int256(feeAmount);
        
        // Mark position as closed
        position.isOpen = false;
        
        // Update open interest
        bytes32 assetKey = keccak256(abi.encodePacked(position.asset));
        if (position.isLong) {
            totalOpenInterestLong[assetKey] -= position.size;
        } else {
            totalOpenInterestShort[assetKey] -= position.size;
        }
        
        // Release reserved liquidity
        vault.decreaseReservedAmount(address(collateralToken), position.size / 10**(18 - collateralDecimals));
        
        // Transfer collateral back to trader from vault
        if (finalCollateral > 0) {
            uint256 returnAmount = uint256(finalCollateral) / 10**(18 - collateralDecimals);
            vault.transferOut(address(collateralToken), msg.sender, returnAmount);
        }
        
        // Transfer fee from vault to recipient
        uint256 feeInCollateral = feeAmount / 10**(18 - collateralDecimals);
        vault.transferOut(address(collateralToken), feeRecipient, feeInCollateral);
        
        emit PositionClosed(
            positionId,
            msg.sender,
            currentPrice,
            pnl,
            finalCollateral > 0 ? uint256(finalCollateral) : 0
        );
    }
    
    /// @notice Liquidate an undercollateralized position
    /// @param positionId Position ID to liquidate
    function liquidatePosition(uint256 positionId) external nonReentrant whenNotPaused {
        Position storage position = positions[positionId];
        require(position.isOpen, "Position not open");
        
        // Get current price
        uint256 currentPrice = priceOracle.getLatestPrice(position.asset);
        
        // Calculate and apply funding payment
        int256 fundingPayment = _calculateFundingPayment(positionId);

        // Update accumulated funding
        position.accumulatedFunding += fundingPayment;
        position.lastFundingTime = block.timestamp;

        // Calculate PnL
        int256 pnl = _calculatePnL(position, currentPrice);
        pnl -= position.accumulatedFunding;

        // Calculate current collateral value
        int256 currentCollateral = int256(position.collateral) + pnl;

        // Check if position is liquidatable (FIXED: use <= instead of <)
        uint256 liquidationThreshold = (position.collateral * LIQUIDATION_THRESHOLD) / 10000;
        require(currentCollateral <= int256(liquidationThreshold), "Position not liquidatable");
        
        // Calculate liquidation fee
        uint256 liquidationFeeAmount = (position.size * LIQUIDATION_FEE) / 10000;
        
        // Mark position as closed
        position.isOpen = false;
        
        // Update open interest
        bytes32 assetKey = keccak256(abi.encodePacked(position.asset));
        if (position.isLong) {
            totalOpenInterestLong[assetKey] -= position.size;
        } else {
            totalOpenInterestShort[assetKey] -= position.size;
        }
        
        // Release reserved liquidity
        vault.decreaseReservedAmount(address(collateralToken), position.size / 10**(18 - collateralDecimals));
        
        // Pay liquidation fee to liquidator from vault
        if (currentCollateral > int256(liquidationFeeAmount)) {
            uint256 feeInCollateral = liquidationFeeAmount / 10**(18 - collateralDecimals);
            vault.transferOut(address(collateralToken), msg.sender, feeInCollateral);
        }
        
        emit PositionLiquidated(
            positionId,
            position.trader,
            msg.sender,
            currentPrice,
            liquidationFeeAmount
        );
    }
    
    /// @notice Update funding rate for an asset
    /// @param asset Asset symbol
    /// @param rate New funding rate (18 decimals, can be negative)
    function updateFundingRate(string memory asset, int256 rate) external onlyOwner {
        bytes32 assetKey = keccak256(abi.encodePacked(asset));
        fundingRates[assetKey] = FundingRate({
            rate: rate,
            lastUpdateTime: block.timestamp
        });
        
        emit FundingRateUpdated(asset, rate);
    }
    
    /// @notice Calculate PnL for a position
    function _calculatePnL(Position memory position, uint256 currentPrice) 
        internal 
        pure 
        returns (int256 pnl) 
    {
        int256 priceDiff = int256(currentPrice) - int256(position.entryPrice);
        
        if (position.isLong) {
            // Long: profit when price increases
            pnl = (int256(position.size) * priceDiff) / int256(position.entryPrice);
        } else {
            // Short: profit when price decreases
            pnl = (int256(position.size) * (-priceDiff)) / int256(position.entryPrice);
        }
    }
    
    /// @notice Calculate funding payment for a position
    function _calculateFundingPayment(uint256 positionId) 
        internal 
        view 
        returns (int256 payment) 
    {
        Position memory position = positions[positionId];
        bytes32 assetKey = keccak256(abi.encodePacked(position.asset));
        FundingRate memory fundingRate = fundingRates[assetKey];
        
        uint256 timeElapsed = block.timestamp - position.lastFundingTime;
        uint256 hoursElapsed = timeElapsed / 3600;
        
        if (hoursElapsed > 0) {
            // Funding payment = position size * funding rate * hours
            payment = (int256(position.size) * fundingRate.rate * int256(hoursElapsed)) / 1e18;
            
            // Long positions pay funding when rate is positive
            // Short positions pay funding when rate is negative
            if (!position.isLong) {
                payment = -payment;
            }
        }
    }
    
    /// @notice Get position details
    function getPosition(uint256 positionId) 
        external 
        view 
        returns (
            address trader,
            string memory asset,
            bool isLong,
            uint256 size,
            uint256 collateral,
            uint256 leverage,
            uint256 entryPrice,
            bool isOpen
        ) 
    {
        Position memory position = positions[positionId];
        return (
            position.trader,
            position.asset,
            position.isLong,
            position.size,
            position.collateral,
            position.leverage,
            position.entryPrice,
            position.isOpen
        );
    }
    
    /// @notice Get trader's position IDs
    function getTraderPositions(address trader) external view returns (uint256[] memory) {
        return traderPositions[trader];
    }
    
    /// @notice Update trading fee
    function setTradingFee(uint256 newFee) external onlyOwner {
        require(newFee <= 100, "Fee too high"); // Max 1%
        tradingFee = newFee;
    }
    
    /// @notice Update fee recipient
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid recipient");
        feeRecipient = newRecipient;
    }
    
    /// @notice Update max position size
    function setMaxPositionSize(uint256 newMax) external onlyOwner {
        maxPositionSize = newMax;
    }
    
    /// @notice Pause contract
    function pause() external onlyOwner {
        _pause();
    }
    
    /// @notice Unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
