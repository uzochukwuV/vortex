// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title Staking Contract
/// @notice Stake platform tokens to earn rewards from trading fees
/// @dev Supports lock periods with reward multipliers
contract Staking is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    /// @notice Stake structure
    struct Stake {
        uint256 amount;
        uint256 lockPeriod; // Lock period in seconds
        uint256 startTime;
        uint256 lastClaimTime;
        uint256 multiplier; // Reward multiplier (100 = 1x, 200 = 2x)
        uint256 rewardDebt; // Reward debt for proper accounting
        bool isActive;
    }
    
    /// @notice Lock period configuration
    struct LockConfig {
        uint256 duration; // Lock duration in seconds
        uint256 multiplier; // Reward multiplier (100 = 1x)
        bool isActive;
    }
    
    /// @notice Platform token
    IERC20 public immutable platformToken;
    
    /// @notice Reward token (can be same as platform token)
    IERC20 public immutable rewardToken;
    
    /// @notice Stake counter
    uint256 public stakeCounter;
    
    /// @notice Mapping of stake ID to stake data
    mapping(uint256 => Stake) public stakes;
    
    /// @notice Mapping of user to their stake IDs
    mapping(address => uint256[]) public userStakes;

    /// @notice Mapping of stake ID to owner
    mapping(uint256 => address) public stakeIdToOwner;

    /// @notice Lock period configurations
    mapping(uint256 => LockConfig) public lockConfigs;
    
    /// @notice Total staked amount
    uint256 public totalStaked;
    
    /// @notice Total weighted stake (considering multipliers)
    uint256 public totalWeightedStake;
    
    /// @notice Reward rate per second per weighted stake unit
    uint256 public rewardRate;
    
    /// @notice Accumulated rewards per weighted stake
    uint256 public accRewardPerWeightedStake;
    
    /// @notice Last reward update time
    uint256 public lastRewardUpdateTime;
    
    /// @notice Minimum stake amount
    uint256 public minStakeAmount = 100 * 10**18; // 100 tokens
    
    /// @notice Events
    event Staked(
        uint256 indexed stakeId,
        address indexed user,
        uint256 amount,
        uint256 lockPeriod,
        uint256 multiplier
    );
    
    event Unstaked(
        uint256 indexed stakeId,
        address indexed user,
        uint256 amount
    );
    
    event RewardClaimed(
        uint256 indexed stakeId,
        address indexed user,
        uint256 reward
    );
    
    event RewardRateUpdated(uint256 newRate);
    
    event LockConfigUpdated(uint256 indexed lockId, uint256 duration, uint256 multiplier);
    
    /// @param _platformToken Platform token address
    /// @param _rewardToken Reward token address
    constructor(address _platformToken, address _rewardToken) Ownable(msg.sender) {
        require(_platformToken != address(0), "Invalid platform token");
        require(_rewardToken != address(0), "Invalid reward token");
        
        platformToken = IERC20(_platformToken);
        rewardToken = IERC20(_rewardToken);
        lastRewardUpdateTime = block.timestamp;
        
        // Initialize default lock configurations
        // No lock: 1x multiplier
        lockConfigs[0] = LockConfig({
            duration: 0,
            multiplier: 100,
            isActive: true
        });
        
        // 30 days: 1.5x multiplier
        lockConfigs[1] = LockConfig({
            duration: 30 days,
            multiplier: 150,
            isActive: true
        });
        
        // 90 days: 2x multiplier
        lockConfigs[2] = LockConfig({
            duration: 90 days,
            multiplier: 200,
            isActive: true
        });
        
        // 180 days: 3x multiplier
        lockConfigs[3] = LockConfig({
            duration: 180 days,
            multiplier: 300,
            isActive: true
        });
    }
    
    /// @notice Stake tokens
    /// @param amount Amount to stake
    /// @param lockConfigId Lock configuration ID
    function stake(uint256 amount, uint256 lockConfigId) 
        external 
        nonReentrant 
        whenNotPaused 
        returns (uint256 stakeId) 
    {
        require(amount >= minStakeAmount, "Amount below minimum");
        
        LockConfig memory config = lockConfigs[lockConfigId];
        require(config.isActive, "Invalid lock config");
        
        // Update global rewards
        _updateRewards();
        
        // Transfer tokens
        platformToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // Calculate weighted amount
        uint256 weightedAmount = (amount * config.multiplier) / 100;
        
        // Create stake
        stakeId = ++stakeCounter;
        stakes[stakeId] = Stake({
            amount: amount,
            lockPeriod: config.duration,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            multiplier: config.multiplier,
            rewardDebt: (weightedAmount * accRewardPerWeightedStake) / 1e18, // Initialize reward debt
            isActive: true
        });
        
        userStakes[msg.sender].push(stakeId);
        stakeIdToOwner[stakeId] = msg.sender;

        // Update totals
        totalStaked += amount;
        totalWeightedStake += weightedAmount;
        
        emit Staked(stakeId, msg.sender, amount, config.duration, config.multiplier);
    }
    
    /// @notice Unstake tokens
    /// @param stakeId Stake ID to unstake
    function unstake(uint256 stakeId) external nonReentrant {
        Stake storage stakeData = stakes[stakeId];
        require(stakeData.isActive, "Stake not active");
        
        // Find stake owner
        address owner = _findStakeOwner(stakeId);
        require(owner == msg.sender, "Not stake owner");
        
        // Check lock period
        require(
            block.timestamp >= stakeData.startTime + stakeData.lockPeriod,
            "Lock period not ended"
        );
        
        // Update global rewards
        _updateRewards();
        
        // Claim pending rewards
        _claimRewards(stakeId, owner);
        
        // Calculate weighted amount
        uint256 weightedAmount = (stakeData.amount * stakeData.multiplier) / 100;
        
        // Mark as inactive
        stakeData.isActive = false;
        
        // Update totals
        totalStaked -= stakeData.amount;
        totalWeightedStake -= weightedAmount;
        
        // Transfer tokens back
        platformToken.safeTransfer(msg.sender, stakeData.amount);
        
        emit Unstaked(stakeId, msg.sender, stakeData.amount);
    }
    
    /// @notice Claim rewards for a stake
    /// @param stakeId Stake ID
    function claimRewards(uint256 stakeId) external nonReentrant {
        Stake storage stakeData = stakes[stakeId];
        require(stakeData.isActive, "Stake not active");
        
        address owner = _findStakeOwner(stakeId);
        require(owner == msg.sender, "Not stake owner");
        
        // Update global rewards
        _updateRewards();
        
        // Claim rewards
        _claimRewards(stakeId, owner);
    }
    
    /// @notice Internal function to claim rewards
    function _claimRewards(uint256 stakeId, address owner) internal {
        Stake storage stakeData = stakes[stakeId];

        uint256 weightedAmount = (stakeData.amount * stakeData.multiplier) / 100;

        // Calculate total accrued rewards
        uint256 accruedRewards = (weightedAmount * accRewardPerWeightedStake) / 1e18;

        // Calculate pending (not yet claimed) rewards
        uint256 pending = accruedRewards - stakeData.rewardDebt;

        if (pending > 0) {
            // Update reward debt to current accrued amount
            stakeData.rewardDebt = accruedRewards;
            stakeData.lastClaimTime = block.timestamp;

            // Transfer pending rewards
            rewardToken.safeTransfer(owner, pending);
            emit RewardClaimed(stakeId, owner, pending);
        }
    }
    
    /// @notice Update global reward accumulation
    function _updateRewards() internal {
        if (block.timestamp <= lastRewardUpdateTime) {
            return;
        }
        
        if (totalWeightedStake == 0) {
            lastRewardUpdateTime = block.timestamp;
            return;
        }
        
        uint256 timeElapsed = block.timestamp - lastRewardUpdateTime;
        uint256 reward = timeElapsed * rewardRate;
        
        accRewardPerWeightedStake += (reward * 1e18) / totalWeightedStake;
        lastRewardUpdateTime = block.timestamp;
    }
    
    /// @notice Calculate pending rewards for a stake
    /// @param stakeId Stake ID
    function pendingRewards(uint256 stakeId) external view returns (uint256) {
        Stake memory stakeData = stakes[stakeId];
        if (!stakeData.isActive) {
            return 0;
        }
        
        uint256 weightedAmount = (stakeData.amount * stakeData.multiplier) / 100;
        uint256 timeElapsed = block.timestamp - stakeData.lastClaimTime;
        
        if (timeElapsed == 0 || totalWeightedStake == 0) {
            return 0;
        }
        
        uint256 accReward = accRewardPerWeightedStake;
        uint256 additionalReward = (timeElapsed * rewardRate * 1e18) / totalWeightedStake;
        accReward += additionalReward;
        
        return (weightedAmount * accReward) / 1e18;
    }
    
    /// @notice Get user's stake IDs
    function getUserStakes(address user) external view returns (uint256[] memory) {
        return userStakes[user];
    }
    
    /// @notice Find stake owner
    function _findStakeOwner(uint256 stakeId) internal view returns (address) {
        address owner = stakeIdToOwner[stakeId];
        require(owner != address(0), "Stake does not exist");
        return owner;
    }
    
    /// @notice Set reward rate
    /// @param newRate New reward rate per second
    function setRewardRate(uint256 newRate) external onlyOwner {
        _updateRewards();
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    /// @notice Add or update lock configuration
    /// @param lockId Lock configuration ID
    /// @param duration Lock duration in seconds
    /// @param multiplier Reward multiplier (100 = 1x)
    function setLockConfig(
        uint256 lockId,
        uint256 duration,
        uint256 multiplier
    ) external onlyOwner {
        require(multiplier >= 100, "Multiplier too low");
        
        lockConfigs[lockId] = LockConfig({
            duration: duration,
            multiplier: multiplier,
            isActive: true
        });
        
        emit LockConfigUpdated(lockId, duration, multiplier);
    }
    
    /// @notice Set minimum stake amount
    function setMinStakeAmount(uint256 newMin) external onlyOwner {
        minStakeAmount = newMin;
    }
    
    /// @notice Deposit rewards
    /// @param amount Amount of reward tokens to deposit
    function depositRewards(uint256 amount) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
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
