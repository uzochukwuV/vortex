// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Reward Distributor
/// @notice Distributes trading fees to VLP holders and stakers
/// @dev Collects fees from trading activities and distributes proportionally
contract RewardDistributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Distribution config
    struct DistributionConfig {
        uint256 vlpHoldersShare; // Basis points (e.g., 6000 = 60%)
        uint256 stakersShare; // Basis points
        uint256 treasuryShare; // Basis points
        uint256 buybackShare; // Basis points
    }

    /// @notice Reward tracking for VLP holders
    struct VlpRewardInfo {
        uint256 accRewardPerShare; // Accumulated reward per VLP share
        uint256 lastUpdateTime;
        uint256 totalDistributed;
    }

    /// @notice User reward tracking
    struct UserReward {
        uint256 rewardDebt;
        uint256 pendingReward;
        uint256 totalClaimed;
    }

    /// @notice Vault contract
    address public vault;

    /// @notice Staking contract
    address public stakingContract;

    /// @notice Treasury address
    address public treasury;

    /// @notice Buyback contract
    address public buybackContract;

    /// @notice Distribution configuration
    DistributionConfig public config;

    /// @notice Reward info per token
    mapping(address => VlpRewardInfo) public vlpRewardInfo;

    /// @notice User rewards per token
    mapping(address => mapping(address => UserReward)) public userRewards;

    /// @notice Reward tokens (tokens accepted for distribution)
    address[] public rewardTokens;
    mapping(address => bool) public isRewardToken;

    /// @notice Total fees collected per token
    mapping(address => uint256) public totalFeesCollected;

    /// @notice Pending distribution per token
    mapping(address => uint256) public pendingDistribution;

    /// @notice Events
    event FeesCollected(address indexed token, uint256 amount);
    event RewardDistributed(address indexed token, uint256 vlpAmount, uint256 stakersAmount, uint256 treasuryAmount, uint256 buybackAmount);
    event RewardClaimed(address indexed user, address indexed token, uint256 amount);
    event ConfigUpdated(uint256 vlpShare, uint256 stakersShare, uint256 treasuryShare, uint256 buybackShare);

    constructor(
        address _vault,
        address _stakingContract,
        address _treasury,
        address _buybackContract
    ) Ownable(msg.sender) {
        require(_vault != address(0), "Invalid vault");
        require(_stakingContract != address(0), "Invalid staking");
        require(_treasury != address(0), "Invalid treasury");
        require(_buybackContract != address(0), "Invalid buyback");

        vault = _vault;
        stakingContract = _stakingContract;
        treasury = _treasury;
        buybackContract = _buybackContract;

        // Default distribution: 60% VLP, 20% Stakers, 10% Treasury, 10% Buyback
        config = DistributionConfig({
            vlpHoldersShare: 6000,
            stakersShare: 2000,
            treasuryShare: 1000,
            buybackShare: 1000
        });
    }

    /// @notice Collect fees from trading contracts
    /// @param token Token address
    /// @param amount Amount of fees
    function collectFees(address token, uint256 amount) external nonReentrant {
        require(isRewardToken[token], "Token not supported");
        require(amount > 0, "Invalid amount");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        totalFeesCollected[token] += amount;
        pendingDistribution[token] += amount;

        emit FeesCollected(token, amount);
    }

    /// @notice Distribute pending rewards
    /// @param token Reward token
    function distributeRewards(address token) external nonReentrant {
        require(isRewardToken[token], "Token not supported");

        uint256 amount = pendingDistribution[token];
        require(amount > 0, "No pending distribution");

        // Calculate shares
        uint256 vlpAmount = (amount * config.vlpHoldersShare) / 10000;
        uint256 stakersAmount = (amount * config.stakersShare) / 10000;
        uint256 treasuryAmount = (amount * config.treasuryShare) / 10000;
        uint256 buybackAmount = (amount * config.buybackShare) / 10000;

        // Update VLP reward accumulator
        VlpRewardInfo storage info = vlpRewardInfo[token];

        // Get total VLP supply from vault
        (bool success, bytes memory data) = vault.staticcall(
            abi.encodeWithSignature("totalVlpSupply()")
        );

        uint256 totalVlp = 0;
        if (success && data.length >= 32) {
            totalVlp = abi.decode(data, (uint256));
        }

        if (totalVlp > 0) {
            info.accRewardPerShare += (vlpAmount * 1e18) / totalVlp;
            info.totalDistributed += vlpAmount;
        } else {
            // If no VLP holders, add to treasury
            treasuryAmount += vlpAmount;
        }

        info.lastUpdateTime = block.timestamp;

        // Transfer to staking contract
        if (stakersAmount > 0) {
            IERC20(token).safeTransfer(stakingContract, stakersAmount);
        }

        // Transfer to treasury
        if (treasuryAmount > 0) {
            IERC20(token).safeTransfer(treasury, treasuryAmount);
        }

        // Transfer to buyback contract
        if (buybackAmount > 0) {
            IERC20(token).safeTransfer(buybackContract, buybackAmount);
        }

        pendingDistribution[token] = 0;

        emit RewardDistributed(token, vlpAmount, stakersAmount, treasuryAmount, buybackAmount);
    }

    /// @notice Claim VLP holder rewards
    /// @param token Reward token
    function claimRewards(address token) external nonReentrant {
        require(isRewardToken[token], "Token not supported");

        _updateUserReward(token, msg.sender);

        UserReward storage userReward = userRewards[token][msg.sender];
        uint256 pending = userReward.pendingReward;

        require(pending > 0, "No rewards");

        userReward.pendingReward = 0;
        userReward.totalClaimed += pending;

        IERC20(token).safeTransfer(msg.sender, pending);

        emit RewardClaimed(msg.sender, token, pending);
    }

    /// @notice Update user reward calculation
    /// @param token Reward token
    /// @param user User address
    function _updateUserReward(address token, address user) internal {
        VlpRewardInfo memory info = vlpRewardInfo[token];
        UserReward storage userReward = userRewards[token][user];

        // Get user VLP balance from vault
        (bool success, bytes memory data) = vault.staticcall(
            abi.encodeWithSignature("balanceOf(address)", user)
        );

        uint256 userVlp = 0;
        if (success && data.length >= 32) {
            userVlp = abi.decode(data, (uint256));
        }

        if (userVlp > 0) {
            uint256 accumulatedReward = (userVlp * info.accRewardPerShare) / 1e18;
            uint256 pending = accumulatedReward - userReward.rewardDebt;

            if (pending > 0) {
                userReward.pendingReward += pending;
            }
        }

        userReward.rewardDebt = (userVlp * info.accRewardPerShare) / 1e18;
    }

    /// @notice Get pending rewards for user
    /// @param token Reward token
    /// @param user User address
    function pendingReward(address token, address user) external view returns (uint256) {
        VlpRewardInfo memory info = vlpRewardInfo[token];
        UserReward memory userReward = userRewards[token][user];

        // Get user VLP balance
        (bool success, bytes memory data) = vault.staticcall(
            abi.encodeWithSignature("balanceOf(address)", user)
        );

        uint256 userVlp = 0;
        if (success && data.length >= 32) {
            userVlp = abi.decode(data, (uint256));
        }

        if (userVlp == 0) {
            return userReward.pendingReward;
        }

        uint256 accumulatedReward = (userVlp * info.accRewardPerShare) / 1e18;
        uint256 pending = accumulatedReward - userReward.rewardDebt;

        return userReward.pendingReward + pending;
    }

    /// @notice Add reward token
    /// @param token Token address
    function addRewardToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(!isRewardToken[token], "Already added");

        rewardTokens.push(token);
        isRewardToken[token] = true;

        vlpRewardInfo[token] = VlpRewardInfo({
            accRewardPerShare: 0,
            lastUpdateTime: block.timestamp,
            totalDistributed: 0
        });
    }

    /// @notice Update distribution config
    /// @param vlpShare VLP holders share (basis points)
    /// @param stakersShare Stakers share (basis points)
    /// @param treasuryShare Treasury share (basis points)
    /// @param buybackShare Buyback share (basis points)
    function updateConfig(
        uint256 vlpShare,
        uint256 stakersShare,
        uint256 treasuryShare,
        uint256 buybackShare
    ) external onlyOwner {
        require(
            vlpShare + stakersShare + treasuryShare + buybackShare == 10000,
            "Invalid shares"
        );

        config = DistributionConfig({
            vlpHoldersShare: vlpShare,
            stakersShare: stakersShare,
            treasuryShare: treasuryShare,
            buybackShare: buybackShare
        });

        emit ConfigUpdated(vlpShare, stakersShare, treasuryShare, buybackShare);
    }

    /// @notice Update vault address
    function setVault(address newVault) external onlyOwner {
        require(newVault != address(0), "Invalid vault");
        vault = newVault;
    }

    /// @notice Update staking contract
    function setStakingContract(address newStaking) external onlyOwner {
        require(newStaking != address(0), "Invalid staking");
        stakingContract = newStaking;
    }

    /// @notice Update treasury
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury");
        treasury = newTreasury;
    }

    /// @notice Update buyback contract
    function setBuybackContract(address newBuyback) external onlyOwner {
        require(newBuyback != address(0), "Invalid buyback");
        buybackContract = newBuyback;
    }

    /// @notice Get reward tokens array
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }
}
