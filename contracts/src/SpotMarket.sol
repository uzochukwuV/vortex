// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title Spot Market Contract
/// @notice AMM-based spot trading with liquidity pools
/// @dev Implements constant product formula (x * y = k)
contract SpotMarket is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    /// @notice Liquidity pool structure
    struct Pool {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalLiquidity;
        bool isActive;
    }
    
    /// @notice Pool counter
    uint256 public poolCounter;
    
    /// @notice Mapping of pool ID to pool data
    mapping(uint256 => Pool) public pools;
    
    /// @notice Mapping of token pair to pool ID
    mapping(bytes32 => uint256) public pairToPool;
    
    /// @notice Mapping of pool ID to LP token balances
    mapping(uint256 => mapping(address => uint256)) public lpBalances;

    /// @notice Mapping of pool ID to LP token allowances (owner => spender => amount)
    mapping(uint256 => mapping(address => mapping(address => uint256))) public lpAllowances;

    /// @notice Trading fee (0.3%)
    uint256 public tradingFee = 30; // 0.3% in basis points
    
    /// @notice Fee recipient
    address public feeRecipient;
    
    /// @notice Minimum liquidity locked permanently
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    
    /// @notice Events
    event PoolCreated(
        uint256 indexed poolId,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    
    event LiquidityAdded(
        uint256 indexed poolId,
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    event LiquidityRemoved(
        uint256 indexed poolId,
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    event Swap(
        uint256 indexed poolId,
        address indexed trader,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    /// @param _feeRecipient Fee recipient address
    constructor(address _feeRecipient) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }
    
    /// @notice Create a new liquidity pool
    /// @param tokenA First token address
    /// @param tokenB Second token address
    /// @param amountA Amount of tokenA to add
    /// @param amountB Amount of tokenB to add
    function createPool(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external nonReentrant whenNotPaused returns (uint256 poolId) {
        require(tokenA != tokenB, "Identical tokens");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        
        // Order tokens
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (uint256 amount0, uint256 amount1) = tokenA < tokenB ? (amountA, amountB) : (amountB, amountA);
        
        // Check if pool exists
        bytes32 pairKey = keccak256(abi.encodePacked(token0, token1));
        require(pairToPool[pairKey] == 0, "Pool exists");
        
        // Transfer tokens
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        
        // Calculate initial liquidity
        uint256 liquidity = _sqrt(amount0 * amount1);
        require(liquidity > MINIMUM_LIQUIDITY, "Insufficient liquidity");
        
        // Create pool
        poolId = ++poolCounter;
        pools[poolId] = Pool({
            tokenA: token0,
            tokenB: token1,
            reserveA: amount0,
            reserveB: amount1,
            totalLiquidity: liquidity,
            isActive: true
        });
        
        pairToPool[pairKey] = poolId;
        
        // Mint LP tokens (lock minimum liquidity)
        lpBalances[poolId][msg.sender] = liquidity - MINIMUM_LIQUIDITY;
        lpBalances[poolId][address(0)] = MINIMUM_LIQUIDITY;
        
        emit PoolCreated(poolId, token0, token1, amount0, amount1);
        emit LiquidityAdded(poolId, msg.sender, amount0, amount1, liquidity - MINIMUM_LIQUIDITY);
    }
    
    /// @notice Add liquidity to an existing pool
    /// @param poolId Pool ID
    /// @param amountADesired Desired amount of tokenA
    /// @param amountBDesired Desired amount of tokenB
    /// @param amountAMin Minimum amount of tokenA
    /// @param amountBMin Minimum amount of tokenB
    function addLiquidity(
        uint256 poolId,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external nonReentrant whenNotPaused returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        Pool storage pool = pools[poolId];
        require(pool.isActive, "Pool not active");
        
        // Calculate optimal amounts
        uint256 amountBOptimal = (amountADesired * pool.reserveB) / pool.reserveA;
        
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "Insufficient B amount");
            amountA = amountADesired;
            amountB = amountBOptimal;
        } else {
            uint256 amountAOptimal = (amountBDesired * pool.reserveA) / pool.reserveB;
            require(amountAOptimal <= amountADesired && amountAOptimal >= amountAMin, "Insufficient A amount");
            amountA = amountAOptimal;
            amountB = amountBDesired;
        }
        
        // Transfer tokens
        IERC20(pool.tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(pool.tokenB).safeTransferFrom(msg.sender, address(this), amountB);
        
        // Calculate liquidity to mint
        liquidity = _min(
            (amountA * pool.totalLiquidity) / pool.reserveA,
            (amountB * pool.totalLiquidity) / pool.reserveB
        );
        
        require(liquidity > 0, "Insufficient liquidity minted");
        
        // Update pool
        pool.reserveA += amountA;
        pool.reserveB += amountB;
        pool.totalLiquidity += liquidity;
        
        // Mint LP tokens
        lpBalances[poolId][msg.sender] += liquidity;
        
        emit LiquidityAdded(poolId, msg.sender, amountA, amountB, liquidity);
    }
    
    /// @notice Remove liquidity from a pool
    /// @param poolId Pool ID
    /// @param liquidity Amount of LP tokens to burn
    /// @param amountAMin Minimum amount of tokenA to receive
    /// @param amountBMin Minimum amount of tokenB to receive
    function removeLiquidity(
        uint256 poolId,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        Pool storage pool = pools[poolId];
        require(pool.isActive, "Pool not active");
        require(lpBalances[poolId][msg.sender] >= liquidity, "Insufficient LP balance");
        
        // Calculate amounts to return
        amountA = (liquidity * pool.reserveA) / pool.totalLiquidity;
        amountB = (liquidity * pool.reserveB) / pool.totalLiquidity;
        
        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");
        
        // Burn LP tokens
        lpBalances[poolId][msg.sender] -= liquidity;
        
        // Update pool
        pool.reserveA -= amountA;
        pool.reserveB -= amountB;
        pool.totalLiquidity -= liquidity;
        
        // Transfer tokens
        IERC20(pool.tokenA).safeTransfer(msg.sender, amountA);
        IERC20(pool.tokenB).safeTransfer(msg.sender, amountB);
        
        emit LiquidityRemoved(poolId, msg.sender, amountA, amountB, liquidity);
    }
    
    /// @notice Swap tokens
    /// @param poolId Pool ID
    /// @param tokenIn Input token address
    /// @param amountIn Input amount
    /// @param amountOutMin Minimum output amount
    function swap(
        uint256 poolId,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin
    ) external nonReentrant whenNotPaused returns (uint256 amountOut) {
        Pool storage pool = pools[poolId];
        require(pool.isActive, "Pool not active");
        require(amountIn > 0, "Invalid input amount");
        
        bool isTokenA = tokenIn == pool.tokenA;
        require(isTokenA || tokenIn == pool.tokenB, "Invalid token");
        
        // Calculate output amount with fee
        uint256 amountInWithFee = amountIn * (10000 - tradingFee);
        
        if (isTokenA) {
            amountOut = (amountInWithFee * pool.reserveB) / (pool.reserveA * 10000 + amountInWithFee);
            require(amountOut >= amountOutMin, "Insufficient output amount");
            require(amountOut < pool.reserveB, "Insufficient liquidity");

            // Store old reserves for k invariant check
            uint256 oldReserveA = pool.reserveA;
            uint256 oldReserveB = pool.reserveB;

            // Update reserves (Effects before Interactions)
            pool.reserveA += amountIn;
            pool.reserveB -= amountOut;

            // Verify k invariant: (reserveA * reserveB) should not decrease
            // Account for fee: new k should be >= old k
            require(
                pool.reserveA * pool.reserveB >= oldReserveA * oldReserveB,
                "K invariant violated"
            );

            // Transfer tokens (Interactions last)
            IERC20(pool.tokenA).safeTransferFrom(msg.sender, address(this), amountIn);
            IERC20(pool.tokenB).safeTransfer(msg.sender, amountOut);

            emit Swap(poolId, msg.sender, pool.tokenA, pool.tokenB, amountIn, amountOut);
        } else {
            amountOut = (amountInWithFee * pool.reserveA) / (pool.reserveB * 10000 + amountInWithFee);
            require(amountOut >= amountOutMin, "Insufficient output amount");
            require(amountOut < pool.reserveA, "Insufficient liquidity");

            // Store old reserves for k invariant check
            uint256 oldReserveA = pool.reserveA;
            uint256 oldReserveB = pool.reserveB;

            // Update reserves (Effects before Interactions)
            pool.reserveB += amountIn;
            pool.reserveA -= amountOut;

            // Verify k invariant
            require(
                pool.reserveA * pool.reserveB >= oldReserveA * oldReserveB,
                "K invariant violated"
            );

            // Transfer tokens (Interactions last)
            IERC20(pool.tokenB).safeTransferFrom(msg.sender, address(this), amountIn);
            IERC20(pool.tokenA).safeTransfer(msg.sender, amountOut);

            emit Swap(poolId, msg.sender, pool.tokenB, pool.tokenA, amountIn, amountOut);
        }
    }
    
    /// @notice Get output amount for a swap
    /// @param poolId Pool ID
    /// @param tokenIn Input token address
    /// @param amountIn Input amount
    function getAmountOut(
        uint256 poolId,
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        Pool memory pool = pools[poolId];
        require(pool.isActive, "Pool not active");
        
        bool isTokenA = tokenIn == pool.tokenA;
        require(isTokenA || tokenIn == pool.tokenB, "Invalid token");
        
        uint256 amountInWithFee = amountIn * (10000 - tradingFee);
        
        if (isTokenA) {
            amountOut = (amountInWithFee * pool.reserveB) / (pool.reserveA * 10000 + amountInWithFee);
        } else {
            amountOut = (amountInWithFee * pool.reserveA) / (pool.reserveB * 10000 + amountInWithFee);
        }
    }
    
    /// @notice Get pool info
    function getPoolInfo(uint256 poolId) 
        external 
        view 
        returns (
            address tokenA,
            address tokenB,
            uint256 reserveA,
            uint256 reserveB,
            uint256 totalLiquidity,
            bool isActive
        ) 
    {
        Pool memory pool = pools[poolId];
        return (
            pool.tokenA,
            pool.tokenB,
            pool.reserveA,
            pool.reserveB,
            pool.totalLiquidity,
            pool.isActive
        );
    }
    
    /// @notice Get LP balance
    function getLPBalance(uint256 poolId, address provider) external view returns (uint256) {
        return lpBalances[poolId][provider];
    }

    /// @notice Transfer LP tokens
    /// @param poolId Pool ID
    /// @param to Recipient address
    /// @param amount Amount to transfer
    function transferLP(uint256 poolId, address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient");
        require(lpBalances[poolId][msg.sender] >= amount, "Insufficient balance");

        lpBalances[poolId][msg.sender] -= amount;
        lpBalances[poolId][to] += amount;
    }

    /// @notice Approve LP tokens for spending
    /// @param poolId Pool ID
    /// @param spender Spender address
    /// @param amount Amount to approve
    function approveLP(uint256 poolId, address spender, uint256 amount) external {
        lpAllowances[poolId][msg.sender][spender] = amount;
    }

    /// @notice Transfer LP tokens from an address (with allowance)
    /// @param poolId Pool ID
    /// @param from From address
    /// @param to To address
    /// @param amount Amount to transfer
    function transferLPFrom(uint256 poolId, address from, address to, uint256 amount) external {
        require(to != address(0), "Invalid recipient");
        require(lpBalances[poolId][from] >= amount, "Insufficient balance");
        require(lpAllowances[poolId][from][msg.sender] >= amount, "Insufficient allowance");

        lpBalances[poolId][from] -= amount;
        lpBalances[poolId][to] += amount;
        lpAllowances[poolId][from][msg.sender] -= amount;
    }

    /// @notice Get LP allowance
    function getLPAllowance(uint256 poolId, address owner, address spender) external view returns (uint256) {
        return lpAllowances[poolId][owner][spender];
    }

    /// @notice Set trading fee
    function setTradingFee(uint256 newFee) external onlyOwner {
        require(newFee <= 100, "Fee too high"); // Max 1%
        tradingFee = newFee;
    }
    
    /// @notice Set fee recipient
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid recipient");
        feeRecipient = newRecipient;
    }
    
    /// @notice Pause contract
    function pause() external onlyOwner {
        _pause();
    }
    
    /// @notice Unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /// @notice Square root function (Babylonian method)
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    /// @notice Minimum of two numbers
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
