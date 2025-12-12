// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./SpotMarket.sol";

/// @title Liquidity Mining Contract
/// @notice Incentivizes liquidity provision with platform token rewards
/// @dev Rewards LP token holders proportionally to their stake
contract LiquidityMining is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Pool info for liquidity mining
    struct PoolInfo {
        uint256 spotPoolId; // Reference to SpotMarket pool
        uint256 allocPoint; // Allocation points for this pool
        uint256 lastRewardTime; // Last time rewards were distributed
        uint256 accRewardPerShare; // Accumulated rewards per share (scaled by 1e18)
        uint256 totalStaked; // Total LP tokens staked
        bool isActive;
    }

    /// @notice User info for each pool
    struct UserInfo {
        uint256 amount; // LP tokens staked
        uint256 rewardDebt; // Reward debt for accurate calculation
        uint256 pendingReward; // Pending rewards to claim
        uint256 lastDepositTime; // For early withdrawal penalty
    }

    /// @notice Platform token for rewards
    IERC20 public immutable rewardToken;

    /// @notice Spot market contract
    SpotMarket public immutable spotMarket;

    /// @notice Pool info array
    PoolInfo[] public poolInfo;

    /// @notice User info mapping (poolId => user => info)
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice Total allocation points
    uint256 public totalAllocPoint;

    /// @notice Reward per second
    uint256 public rewardPerSecond;

    /// @notice Early withdrawal penalty (2%)
    uint256 public constant EARLY_WITHDRAWAL_PENALTY = 200; // 2% in basis points

    /// @notice Early withdrawal period (7 days)
    uint256 public constant EARLY_WITHDRAWAL_PERIOD = 7 days;

    /// @notice Penalty recipient
    address public penaltyRecipient;

    /// @notice Events
    event PoolAdded(uint256 indexed pid, uint256 spotPoolId, uint256 allocPoint);
    event PoolUpdated(uint256 indexed pid, uint256 allocPoint);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPerSecondUpdated(uint256 newRate);

    /// @param _rewardToken Platform token address
    /// @param _spotMarket SpotMarket contract address
    /// @param _rewardPerSecond Initial reward rate
    /// @param _penaltyRecipient Penalty recipient address
    constructor(
        address _rewardToken,
        address _spotMarket,
        uint256 _rewardPerSecond,
        address _penaltyRecipient
    ) Ownable(msg.sender) {
        require(_rewardToken != address(0), "Invalid reward token");
        require(_spotMarket != address(0), "Invalid spot market");
        require(_penaltyRecipient != address(0), "Invalid penalty recipient");

        rewardToken = IERC20(_rewardToken);
        spotMarket = SpotMarket(_spotMarket);
        rewardPerSecond = _rewardPerSecond;
        penaltyRecipient = _penaltyRecipient;
    }

    /// @notice Add a new pool for liquidity mining
    /// @param spotPoolId SpotMarket pool ID
    /// @param allocPoint Allocation points
    function addPool(uint256 spotPoolId, uint256 allocPoint) external onlyOwner {
        // Verify pool exists in SpotMarket
        (address tokenA, , , , , bool isActive) = spotMarket.getPoolInfo(spotPoolId);
        require(tokenA != address(0) && isActive, "Invalid spot pool");

        // Update all pools before adding new one
        massUpdatePools();

        totalAllocPoint += allocPoint;

        poolInfo.push(PoolInfo({
            spotPoolId: spotPoolId,
            allocPoint: allocPoint,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0,
            totalStaked: 0,
            isActive: true
        }));

        emit PoolAdded(poolInfo.length - 1, spotPoolId, allocPoint);
    }

    /// @notice Update allocation points for a pool
    /// @param pid Pool ID
    /// @param allocPoint New allocation points
    function updatePool(uint256 pid, uint256 allocPoint) external onlyOwner {
        massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[pid].allocPoint + allocPoint;
        poolInfo[pid].allocPoint = allocPoint;

        emit PoolUpdated(pid, allocPoint);
    }

    /// @notice Deposit LP tokens for reward mining
    /// @param pid Pool ID
    /// @param amount Amount of LP tokens to deposit
    function deposit(uint256 pid, uint256 amount) external nonReentrant {
        require(pid < poolInfo.length, "Invalid pool");
        PoolInfo storage pool = poolInfo[pid];
        require(pool.isActive, "Pool not active");
        UserInfo storage user = userInfo[pid][msg.sender];

        updatePoolRewards(pid);

        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accRewardPerShare / 1e18) - user.rewardDebt;
            if (pending > 0) {
                user.pendingReward += pending;
            }
        }

        if (amount > 0) {
            // Get LP tokens from SpotMarket
            uint256 lpBalance = spotMarket.getLPBalance(pool.spotPoolId, msg.sender);
            require(lpBalance >= amount, "Insufficient LP balance");

            // Transfer LP tokens to this contract
            spotMarket.transferLPFrom(pool.spotPoolId, msg.sender, address(this), amount);

            user.amount += amount;
            user.lastDepositTime = block.timestamp;
            pool.totalStaked += amount;
        }

        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;

        emit Deposit(msg.sender, pid, amount);
    }

    /// @notice Withdraw LP tokens and claim rewards
    /// @param pid Pool ID
    /// @param amount Amount to withdraw
    function withdraw(uint256 pid, uint256 amount) external nonReentrant {
        require(pid < poolInfo.length, "Invalid pool");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amount, "Insufficient balance");

        updatePoolRewards(pid);

        uint256 pending = (user.amount * pool.accRewardPerShare / 1e18) - user.rewardDebt;
        if (pending > 0) {
            user.pendingReward += pending;
        }

        if (amount > 0) {
            user.amount -= amount;
            pool.totalStaked -= amount;

            // Check for early withdrawal penalty
            if (block.timestamp < user.lastDepositTime + EARLY_WITHDRAWAL_PERIOD) {
                uint256 penalty = (amount * EARLY_WITHDRAWAL_PENALTY) / 10000;
                uint256 amountAfterPenalty = amount - penalty;

                // Transfer LP tokens back (minus penalty)
                spotMarket.transferLP(pool.spotPoolId, msg.sender, amountAfterPenalty);

                // Transfer penalty to recipient
                spotMarket.transferLP(pool.spotPoolId, penaltyRecipient, penalty);
            } else {
                // Transfer LP tokens back
                spotMarket.transferLP(pool.spotPoolId, msg.sender, amount);
            }
        }

        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;

        emit Withdraw(msg.sender, pid, amount);
    }

    /// @notice Claim pending rewards
    /// @param pid Pool ID
    function claimRewards(uint256 pid) external nonReentrant {
        require(pid < poolInfo.length, "Invalid pool");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        updatePoolRewards(pid);

        uint256 pending = (user.amount * pool.accRewardPerShare / 1e18) - user.rewardDebt;
        if (pending > 0) {
            user.pendingReward += pending;
        }

        uint256 totalReward = user.pendingReward;
        if (totalReward > 0) {
            user.pendingReward = 0;
            rewardToken.safeTransfer(msg.sender, totalReward);
            emit RewardClaimed(msg.sender, pid, totalReward);
        }

        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;
    }

    /// @notice Emergency withdraw without caring about rewards
    /// @param pid Pool ID
    function emergencyWithdraw(uint256 pid) external nonReentrant {
        require(pid < poolInfo.length, "Invalid pool");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.pendingReward = 0;
        pool.totalStaked -= amount;

        // Transfer LP tokens back (no penalty in emergency)
        if (amount > 0) {
            spotMarket.transferLP(pool.spotPoolId, msg.sender, amount);
        }

        emit EmergencyWithdraw(msg.sender, pid, amount);
    }

    /// @notice Update reward variables for a pool
    /// @param pid Pool ID
    function updatePoolRewards(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];

        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.totalStaked == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - pool.lastRewardTime;
        uint256 reward = timeElapsed * rewardPerSecond * pool.allocPoint / totalAllocPoint;

        pool.accRewardPerShare += (reward * 1e18) / pool.totalStaked;
        pool.lastRewardTime = block.timestamp;
    }

    /// @notice Update reward variables for all pools
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePoolRewards(pid);
        }
    }

    /// @notice Get pending rewards for a user
    /// @param pid Pool ID
    /// @param user User address
    function pendingRewards(uint256 pid, address user) external view returns (uint256) {
        require(pid < poolInfo.length, "Invalid pool");
        PoolInfo memory pool = poolInfo[pid];
        UserInfo memory userStake = userInfo[pid][user];

        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.timestamp > pool.lastRewardTime && pool.totalStaked > 0 && totalAllocPoint > 0) {
            uint256 timeElapsed = block.timestamp - pool.lastRewardTime;
            uint256 reward = timeElapsed * rewardPerSecond * pool.allocPoint / totalAllocPoint;
            accRewardPerShare += (reward * 1e18) / pool.totalStaked;
        }

        uint256 pending = (userStake.amount * accRewardPerShare / 1e18) - userStake.rewardDebt;
        return userStake.pendingReward + pending;
    }

    /// @notice Get number of pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Set reward per second
    /// @param newRate New reward rate
    function setRewardPerSecond(uint256 newRate) external onlyOwner {
        massUpdatePools();
        rewardPerSecond = newRate;
        emit RewardPerSecondUpdated(newRate);
    }

    /// @notice Set penalty recipient
    /// @param newRecipient New penalty recipient
    function setPenaltyRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid recipient");
        penaltyRecipient = newRecipient;
    }

    /// @notice Deposit reward tokens
    /// @param amount Amount to deposit
    function depositRewards(uint256 amount) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Deactivate a pool
    /// @param pid Pool ID
    function deactivatePool(uint256 pid) external onlyOwner {
        require(pid < poolInfo.length, "Invalid pool");
        poolInfo[pid].isActive = false;
    }
}
