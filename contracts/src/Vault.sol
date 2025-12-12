// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Vault Contract
/// @notice Central vault for managing protocol liquidity and collateral
/// @dev Issues VLP (Vault LP) tokens to liquidity providers
contract Vault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Whitelisted token info
    struct TokenInfo {
        uint8 decimals;
        uint256 weight; // Weight in the pool (basis points)
        uint256 minProfitBps; // Minimum profit basis points
        uint256 maxUsdgAmount; // Maximum USDG amount
        bool isWhitelisted;
        bool isStable;
    }

    /// @notice VLP token balances
    mapping(address => uint256) public vlpBalances;

    /// @notice Total VLP supply
    uint256 public totalVlpSupply;

    /// @notice Whitelisted tokens
    mapping(address => TokenInfo) public tokenInfo;
    address[] public whitelistedTokens;

    /// @notice Token balances in vault
    mapping(address => uint256) public tokenBalances;

    /// @notice Reserved amounts (for open positions)
    mapping(address => uint256) public reservedAmounts;

    /// @notice Guaranteed USD values (for shorts)
    mapping(address => uint256) public guaranteedUsd;

    /// @notice Pool amounts available for trading
    mapping(address => uint256) public poolAmounts;

    /// @notice Maximum USDG amounts per token
    mapping(address => uint256) public maxUsdgAmounts;

    /// @notice Fees collected
    mapping(address => uint256) public feeReserves;

    /// @notice Fee recipient
    address public feeRecipient;

    /// @notice Mint/burn fees (30 basis points = 0.3%)
    uint256 public mintBurnFee = 30;

    /// @notice Swap fees (30 basis points = 0.3%)
    uint256 public swapFee = 30;

    /// @notice Minimum VLP amount to prevent attacks
    uint256 public constant MIN_VLP_AMOUNT = 1000;

    /// @notice Events
    event AddLiquidity(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 vlpAmount,
        uint256 fee
    );

    event RemoveLiquidity(
        address indexed account,
        address indexed token,
        uint256 vlpAmount,
        uint256 amountOut,
        uint256 fee
    );

    event Swap(
        address indexed account,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee
    );

    event TokenWhitelisted(address indexed token, uint8 decimals, uint256 weight);
    event IncreasePoolAmount(address indexed token, uint256 amount);
    event DecreasePoolAmount(address indexed token, uint256 amount);

    constructor(address _feeRecipient) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    /// @notice Add liquidity to vault
    /// @param token Token address
    /// @param amount Amount to add
    /// @param minVlp Minimum VLP tokens to receive
    function addLiquidity(
        address token,
        uint256 amount,
        uint256 minVlp
    ) external nonReentrant returns (uint256) {
        require(tokenInfo[token].isWhitelisted, "Token not whitelisted");
        require(amount > 0, "Invalid amount");

        // Transfer tokens to vault
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Calculate VLP amount
        uint256 vlpAmount = _calculateVlpAmount(token, amount, true);
        require(vlpAmount >= minVlp, "Insufficient VLP output");

        // Calculate and deduct fee
        uint256 feeAmount = (amount * mintBurnFee) / 10000;
        uint256 amountAfterFee = amount - feeAmount;

        // Update state
        feeReserves[token] += feeAmount;
        poolAmounts[token] += amountAfterFee;
        tokenBalances[token] += amount;

        // Mint VLP
        vlpBalances[msg.sender] += vlpAmount;
        totalVlpSupply += vlpAmount;

        emit AddLiquidity(msg.sender, token, amount, vlpAmount, feeAmount);
        emit IncreasePoolAmount(token, amountAfterFee);

        return vlpAmount;
    }

    /// @notice Remove liquidity from vault
    /// @param token Token to receive
    /// @param vlpAmount VLP tokens to burn
    /// @param minOut Minimum token amount to receive
    function removeLiquidity(
        address token,
        uint256 vlpAmount,
        uint256 minOut
    ) external nonReentrant returns (uint256) {
        require(tokenInfo[token].isWhitelisted, "Token not whitelisted");
        require(vlpAmount > 0, "Invalid VLP amount");
        require(vlpBalances[msg.sender] >= vlpAmount, "Insufficient VLP balance");

        // Calculate token amount
        uint256 tokenAmount = _calculateTokenAmount(token, vlpAmount);
        require(tokenAmount >= minOut, "Insufficient token output");

        // Calculate and deduct fee
        uint256 feeAmount = (tokenAmount * mintBurnFee) / 10000;
        uint256 amountOut = tokenAmount - feeAmount;

        require(
            poolAmounts[token] >= tokenAmount,
            "Insufficient pool amount"
        );

        // Update state
        vlpBalances[msg.sender] -= vlpAmount;
        totalVlpSupply -= vlpAmount;
        poolAmounts[token] -= tokenAmount;
        tokenBalances[token] -= amountOut;
        feeReserves[token] += feeAmount;

        // Transfer tokens
        IERC20(token).safeTransfer(msg.sender, amountOut);

        emit RemoveLiquidity(msg.sender, token, vlpAmount, amountOut, feeAmount);
        emit DecreasePoolAmount(token, tokenAmount);

        return amountOut;
    }

    /// @notice Swap tokens in the vault
    /// @param tokenIn Input token
    /// @param tokenOut Output token
    /// @param amountIn Input amount
    /// @param minAmountOut Minimum output amount
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external nonReentrant returns (uint256) {
        require(tokenInfo[tokenIn].isWhitelisted, "TokenIn not whitelisted");
        require(tokenInfo[tokenOut].isWhitelisted, "TokenOut not whitelisted");
        require(tokenIn != tokenOut, "Same token");
        require(amountIn > 0, "Invalid amount");

        // Transfer input tokens
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Calculate output amount
        uint256 amountOut = _calculateSwapAmount(tokenIn, tokenOut, amountIn);
        require(amountOut >= minAmountOut, "Insufficient output");

        // Calculate fee
        uint256 feeAmount = (amountOut * swapFee) / 10000;
        uint256 amountOutAfterFee = amountOut - feeAmount;

        require(
            poolAmounts[tokenOut] >= amountOut,
            "Insufficient liquidity"
        );

        // Update state
        tokenBalances[tokenIn] += amountIn;
        poolAmounts[tokenIn] += amountIn;
        poolAmounts[tokenOut] -= amountOut;
        tokenBalances[tokenOut] -= amountOutAfterFee;
        feeReserves[tokenOut] += feeAmount;

        // Transfer output tokens
        IERC20(tokenOut).safeTransfer(msg.sender, amountOutAfterFee);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOutAfterFee, feeAmount);

        return amountOutAfterFee;
    }

    /// @notice Calculate VLP amount for token deposit
    function _calculateVlpAmount(
        address token,
        uint256 amount,
        bool /* isDeposit */
    ) internal view returns (uint256) {
        TokenInfo memory info = tokenInfo[token];

        // Convert to 18 decimals
        uint256 amountIn18 = amount * 10**(18 - info.decimals);

        if (totalVlpSupply == 0) {
            return amountIn18;
        }

        // Calculate based on pool value
        uint256 totalValue = _getTotalVaultValue();
        return (amountIn18 * totalVlpSupply) / totalValue;
    }

    /// @notice Calculate token amount for VLP redemption
    function _calculateTokenAmount(
        address token,
        uint256 vlpAmount
    ) internal view returns (uint256) {
        TokenInfo memory info = tokenInfo[token];

        uint256 totalValue = _getTotalVaultValue();
        uint256 valueOut = (vlpAmount * totalValue) / totalVlpSupply;

        // Convert from 18 decimals
        return valueOut / 10**(18 - info.decimals);
    }

    /// @notice Calculate swap output amount
    function _calculateSwapAmount(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256) {
        TokenInfo memory inInfo = tokenInfo[tokenIn];
        TokenInfo memory outInfo = tokenInfo[tokenOut];

        // Convert to 18 decimals
        uint256 amountIn18 = amountIn * 10**(18 - inInfo.decimals);

        // Simple 1:1 swap for now (in production, use oracle prices)
        uint256 amountOut18 = amountIn18;

        // Convert to output token decimals
        return amountOut18 / 10**(18 - outInfo.decimals);
    }

    /// @notice Get total vault value in 18 decimals
    function _getTotalVaultValue() internal view returns (uint256) {
        uint256 totalValue = 0;

        for (uint256 i = 0; i < whitelistedTokens.length; i++) {
            address token = whitelistedTokens[i];
            TokenInfo memory info = tokenInfo[token];

            if (info.isWhitelisted) {
                uint256 balance = poolAmounts[token];
                uint256 value = balance * 10**(18 - info.decimals);
                totalValue += value;
            }
        }

        return totalValue > 0 ? totalValue : 1;
    }

    /// @notice Whitelist a token
    /// @param token Token address
    /// @param decimals Token decimals
    /// @param weight Weight in pool
    /// @param isStable Is stablecoin
    function whitelistToken(
        address token,
        uint8 decimals,
        uint256 weight,
        bool isStable
    ) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(!tokenInfo[token].isWhitelisted, "Already whitelisted");

        tokenInfo[token] = TokenInfo({
            decimals: decimals,
            weight: weight,
            minProfitBps: 150, // 1.5%
            maxUsdgAmount: 0, // No limit initially
            isWhitelisted: true,
            isStable: isStable
        });

        whitelistedTokens.push(token);

        emit TokenWhitelisted(token, decimals, weight);
    }

    /// @notice Authorized contracts (PerpetualTrading, etc)
    mapping(address => bool) public isAuthorized;

    /// @notice Authorize contract to interact with vault
    function authorizeContract(address _contract) external onlyOwner {
        isAuthorized[_contract] = true;
    }

    /// @notice Increase reserved amount for open positions
    function increaseReservedAmount(address token, uint256 amount) external {
        require(isAuthorized[msg.sender], "Not authorized");
        require(poolAmounts[token] >= reservedAmounts[token] + amount, "Insufficient liquidity");
        reservedAmounts[token] += amount;
    }

    /// @notice Decrease reserved amount when positions close
    function decreaseReservedAmount(address token, uint256 amount) external {
        require(isAuthorized[msg.sender], "Not authorized");
        require(reservedAmounts[token] >= amount, "Insufficient reserve");
        reservedAmounts[token] -= amount;
    }

    /// @notice Transfer tokens from vault (for position payouts)
    function transferOut(address token, address to, uint256 amount) external {
        require(isAuthorized[msg.sender], "Not authorized");
        require(poolAmounts[token] >= amount, "Insufficient pool");
        
        poolAmounts[token] -= amount;
        tokenBalances[token] -= amount;
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Receive tokens into vault (for position collateral)
    function transferIn(address token, uint256 amount) external {
        require(isAuthorized[msg.sender], "Not authorized");
        
        poolAmounts[token] += amount;
        tokenBalances[token] += amount;
    }

    /// @notice Get VLP balance
    function balanceOf(address account) external view returns (uint256) {
        return vlpBalances[account];
    }

    /// @notice Get whitelisted tokens
    function getWhitelistedTokens() external view returns (address[] memory) {
        return whitelistedTokens;
    }

    /// @notice Withdraw fees
    function withdrawFees(address token, address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        uint256 amount = feeReserves[token];
        require(amount > 0, "No fees");

        feeReserves[token] = 0;
        IERC20(token).safeTransfer(recipient, amount);
    }

    /// @notice Set mint/burn fee
    function setMintBurnFee(uint256 newFee) external onlyOwner {
        require(newFee <= 200, "Fee too high"); // Max 2%
        mintBurnFee = newFee;
    }

    /// @notice Set swap fee
    function setSwapFee(uint256 newFee) external onlyOwner {
        require(newFee <= 200, "Fee too high"); // Max 2%
        swapFee = newFee;
    }
}
