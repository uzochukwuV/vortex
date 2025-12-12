# Security Fixes - GMX-Style Perpetual DEX

## Status: In Progress 🚧

This document tracks all security issues identified and their fixes.

---

## Critical Issues (MUST FIX BEFORE MAINNET)

### ✅ #1: PerpetualTrading.sol - Insufficient Collateral Validation
**Status**: FIXED ✅

**Issue**: Fee was deducted after collateral transfer without verifying sufficient balance.

**Risk**: Traders could open positions with insufficient collateral after fees.

**Fix Applied**:
```solidity
// Added balance checks before transfer
require(collateralToken.balanceOf(msg.sender) >= totalRequired, "Insufficient balance");

// Added balance verification after transfer (protection against fee-on-transfer tokens)
uint256 balanceBefore = collateralToken.balanceOf(address(this));
// ... transfer ...
uint256 actualReceived = balanceAfter - balanceBefore;
require(actualReceived == totalRequired, "Transfer amount mismatch");
```

**Location**: [PerpetualTrading.sol:163-183](contracts/src/PerpetualTrading.sol#L163-L183)

---

### ⚠️ #2: PerpetualTrading.sol - Price Manipulation Risk
**Status**: TO BE FIXED 🔴

**Issue**: Uses spot price from oracle without TWAP or price impact checks.

**Risk**: Flash loan attacks could manipulate oracle prices to liquidate positions unfairly.

**Recommended Fix**:
1. Implement TWAP (Time-Weighted Average Price) mechanism
2. Add price deviation checks (max % change per update)
3. Use multiple oracle sources and compare
4. Add circuit breakers for extreme price movements

**Priority**: CRITICAL - Must fix before mainnet

---

### ✅ #3: PerpetualTrading.sol - Funding Payment Not Applied
**Status**: FIXED ✅

**Issue**: `_calculateFundingPayment` was called but never updated `position.accumulatedFunding`.

**Risk**: Funding payments calculated but not recorded, leading to incorrect PnL.

**Fix Applied**:
```solidity
// In closePosition() and liquidatePosition():
int256 fundingPayment = _calculateFundingPayment(positionId);

// Update accumulated funding
position.accumulatedFunding += fundingPayment;
position.lastFundingTime = block.timestamp;

// Calculate PnL with accumulated funding
int256 pnl = _calculatePnL(position, currentPrice);
pnl -= position.accumulatedFunding; // Use total accumulated funding
```

**Location**:
- [PerpetualTrading.sol:235-244](contracts/src/PerpetualTrading.sol#L235-L244)
- [PerpetualTrading.sol:292-301](contracts/src/PerpetualTrading.sol#L292-L301)

---

### ✅ #4: SpotMarket.sol - AMM Formula Vulnerability
**Status**: FIXED ✅

**Issue**: Swap calculation didn't follow checks-effects-interactions pattern and lacked k invariant verification.

**Risk**: Incorrect pricing, potential arbitrage exploitation, reentrancy issues.

**Fix Applied**:
```solidity
// 1. Calculate output amount
// 2. Store old reserves
// 3. Update state (Effects)
pool.reserveA += amountIn;
pool.reserveB -= amountOut;

// 4. Verify k invariant
require(
    pool.reserveA * pool.reserveB >= oldReserveA * oldReserveB,
    "K invariant violated"
);

// 5. Transfer tokens (Interactions last)
```

**Location**: [SpotMarket.sol:253-302](contracts/src/SpotMarket.sol#L253-L302)

---

### ⚠️ #5: Vault.sol - No Slippage Protection on Swaps
**Status**: TO BE FIXED 🔴

**Issue**: `_calculateSwapAmount` uses 1:1 swap without oracle prices.

**Risk**: Massive value loss, users can drain vault with unfavorable swaps.

**Recommended Fix**:
```solidity
function _calculateSwapAmount(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
) internal view returns (uint256) {
    // Get prices from oracle
    uint256 priceIn = priceOracle.getTokenPrice(tokenIn);
    uint256 priceOut = priceOracle.getTokenPrice(tokenOut);

    // Calculate value in USD
    uint256 valueUSD = (amountIn * priceIn) / 10**tokenInDecimals;

    // Convert to output token
    uint256 amountOut = (valueUSD * 10**tokenOutDecimals) / priceOut;

    // Apply slippage tolerance
    return (amountOut * 9950) / 10000; // 0.5% slippage protection
}
```

**Priority**: CRITICAL - Must implement before allowing vault swaps

---

### ⚠️ #6: Staking.sol - Reward Calculation Error
**Status**: TO BE FIXED 🔴

**Issue**: `_claimRewards` doesn't properly track claimed rewards.

**Risk**: Users could claim rewards multiple times.

**Recommended Fix**:
```solidity
function _claimRewards(uint256 stakeId, address owner) internal {
    Stake storage stakeData = stakes[stakeId];

    uint256 weightedAmount = (stakeData.amount * stakeData.multiplier) / 100;

    // Calculate rewards since last claim
    uint256 timeElapsed = block.timestamp - stakeData.lastClaimTime;

    if (timeElapsed > 0 && totalWeightedStake > 0) {
        uint256 rewardPerShare = accRewardPerWeightedStake;

        // Calculate pending rewards properly
        uint256 totalAccrued = (weightedAmount * rewardPerShare) / 1e18;
        uint256 previouslyPaid = stakeData.rewardDebt; // Track what was already paid

        uint256 reward = totalAccrued - previouslyPaid;

        if (reward > 0) {
            stakeData.rewardDebt = totalAccrued; // Update debt
            stakeData.lastClaimTime = block.timestamp;
            rewardToken.safeTransfer(owner, reward);
            emit RewardClaimed(stakeId, owner, reward);
        }
    }
}
```

**Priority**: HIGH - Prevents reward theft

---

### ⚠️ #7: LiquidityMining.sol - Reentrancy in Deposit
**Status**: TO BE FIXED 🔴

**Issue**: External call to `spotMarket.transferLPFrom` before state update completion.

**Risk**: Potential reentrancy attack vector.

**Current Code**:
```solidity
// State update happens AFTER external call
spotMarket.transferLPFrom(pool.spotPoolId, msg.sender, address(this), amount);

user.amount += amount; // Vulnerable!
```

**Recommended Fix**:
```solidity
// Update state BEFORE external call (Checks-Effects-Interactions)
user.amount += amount;
user.lastDepositTime = block.timestamp;
pool.totalStaked += amount;

// Then make external call
spotMarket.transferLPFrom(pool.spotPoolId, msg.sender, address(this), amount);
```

**Priority**: HIGH - Standard reentrancy protection

---

### ⚠️ #8: Governance.sol - No Proposal Validation
**Status**: TO BE FIXED 🔴

**Issue**: `execute()` calls arbitrary addresses without validation.

**Risk**: Malicious proposals could drain contracts or brick the system.

**Recommended Fix**:
```solidity
// Add whitelist of allowed target contracts
mapping(address => bool) public allowedTargets;

function execute(uint256 proposalId) external nonReentrant {
    // ... existing checks ...

    address[] memory targets = proposalTargets[proposalId];

    for (uint256 i = 0; i < targets.length; i++) {
        require(allowedTargets[targets[i]], "Target not whitelisted");

        (bool success, ) = targets[i].call(calldatas[i]);
        require(success, "Execution failed");
    }

    // ... rest of code ...
}

// Function to whitelist contracts (guardian only)
function setAllowedTarget(address target, bool allowed) external {
    require(msg.sender == guardian, "Only guardian");
    allowedTargets[target] = allowed;
}
```

**Priority**: CRITICAL - Prevents governance attacks

---

## High Severity Issues

### ✅ #9: PerpetualTrading.sol - Liquidation Threshold Logic
**Status**: FIXED ✅

**Issue**: Liquidation check used `<` instead of `<=` for threshold.

**Risk**: Positions can go underwater before liquidation.

**Fix Applied**:
```solidity
// Changed from:
require(currentCollateral < int256(liquidationThreshold), "Position not liquidatable");

// To:
require(currentCollateral <= int256(liquidationThreshold), "Position not liquidatable");
```

**Location**: [PerpetualTrading.sol:308](contracts/src/PerpetualTrading.sol#L308)

---

### ⚠️ #10: SpotMarket.sol - LP Token Manipulation
**Status**: TO BE FIXED 🔴

**Issue**: First liquidity provider can manipulate initial price ratio.

**Risk**: Initial LP can steal funds from subsequent LPs.

**Recommended Fix**:
```solidity
function createPool(...) external {
    // ... existing code ...

    // Require minimum initial liquidity to prevent manipulation
    require(amount0 >= MINIMUM_INITIAL_LIQUIDITY, "Insufficient amount0");
    require(amount1 >= MINIMUM_INITIAL_LIQUIDITY, "Insufficient amount1");

    // Calculate initial liquidity
    uint256 liquidity = _sqrt(amount0 * amount1);
    require(liquidity > MINIMUM_LIQUIDITY * 1000, "Insufficient liquidity"); // 1000x minimum

    // ... rest of code ...
}
```

**Priority**: HIGH - Prevents initial LP attacks

---

### ⚠️ #11: Vault.sol - Reserved Amounts Not Checked
**Status**: TO BE FIXED 🔴

**Issue**: Operations don't verify `poolAmounts >= reservedAmounts`.

**Risk**: Vault could become insolvent if reserved amounts exceed available liquidity.

**Recommended Fix**:
```solidity
function removeLiquidity(...) external {
    // ... calculate amountOut ...

    // Check available liquidity (not reserved)
    uint256 availableLiquidity = poolAmounts[token] - reservedAmounts[token];
    require(tokenAmount <= availableLiquidity, "Insufficient available liquidity");

    // ... rest of code ...
}
```

**Priority**: HIGH - Prevents insolvency

---

### ⚠️ #13: Governance.sol - Vote Snapshot Missing
**Status**: TO BE FIXED 🔴

**Issue**: Uses current balance instead of snapshot at proposal creation.

**Risk**: Flash loan governance attacks - buy tokens, vote, sell, repeat.

**Recommended Fix**: Implement ERC20Votes with snapshots:
```solidity
// In PlatformToken.sol - extend ERC20Votes
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract PlatformToken is ERC20, ERC20Votes, Ownable {
    // ... existing code ...
}

// In Governance.sol - use snapshot
function _castVote(...) internal {
    uint256 votes = token.getPastVotes(voter, proposalCore[proposalId].startBlock);
    require(votes > 0, "No voting power");
    // ... rest of code ...
}
```

**Priority**: CRITICAL - Prevents governance attacks

---

## Medium Severity Issues

### ⚠️ #14: PerpetualTrading.sol - Open Interest Not Capped
**Recommended**: Add max open interest per side to prevent imbalanced positions.

### ⚠️ #15: SpotMarket.sol - No Minimum Liquidity Check
**Recommended**: Prevent removing liquidity below minimum threshold.

### ⚠️ #16: Staking.sol - Lock Period Bypass
**Note**: Emergency withdraw bypassing lock period is intentional but should emit warning event.

### ⚠️ #18: PriceOracle.sol - Single Oracle Dependency
**Recommended**: Add fallback oracle and circuit breakers.

---

## Summary

### Fixes Completed: 4/23 ✅
- ✅ #1: Collateral validation
- ✅ #3: Funding payment tracking
- ✅ #4: AMM formula with k invariant
- ✅ #9: Liquidation threshold logic

### Critical Remaining: 4 🔴
- #2: Price manipulation protection
- #5: Vault swap oracle pricing
- #6: Staking reward calculation
- #7: Liquidity mining reentrancy
- #8: Governance proposal validation

### High Priority Remaining: 3 ⚠️
- #10: LP token manipulation
- #11: Vault reserved amounts
- #13: Governance vote snapshots

---

## Testing Requirements

Before mainnet deployment, ALL critical and high severity issues must be:
1. Fixed in code
2. Covered by unit tests
3. Covered by integration tests
4. Verified in professional security audit
5. Tested on testnet with real users

---

## Deployment Checklist

- [ ] All critical issues fixed
- [ ] All high severity issues fixed
- [ ] Comprehensive test coverage (>90%)
- [ ] Professional security audit completed
- [ ] Testnet deployment tested for 2+ weeks
- [ ] Bug bounty program launched
- [ ] Emergency pause mechanisms tested
- [ ] Multisig ownership transferred
- [ ] Guardian multisig configured

---

**Last Updated**: 2025-12-09
**Audited By**: Internal review (External audit required)
**Status**: NOT READY FOR MAINNET ⚠️


========================================
  DEPLOYMENT SUMMARY - QIE TESTNET
  ========================================

Mock Tokens:
    Mock USDT: 0xaD401e1D1627096D8D104A2eAF001774c84506c2
    Mock BTC: 0x217DF628fdc946D56D6979feC25A1337F9016e5c
    Mock ETH: 0xD97E0879dA340f314198Ba07f5795849200CbAE4
    Mock BNB: 0x63F143de8B970B50002f114bc30de525AdA076b0
    Mock SOL: 0x9eE3DE542E32ee05499dde037DE329F7fEd106cE
    Mock QIE: 0x4D918D30722C5ee4F47696f636065358bf9F01D8

Mock Price Feeds:
    BTC Feed: 0xE4ea3991639B057595A8CfD27114837dB70E6c00
    ETH Feed: 0xd407b6079cEdE735B4Bc9C63a108f9BE846ed071
    BNB Feed: 0x8beDD2d956Ff3eB3153D3ca74e597F9C4Dc6eff8
    SOL Feed: 0xA2139eDE2DBBC5Ae592D99724C4Fe5ed1e44BCDC
    QIE Feed: 0x2495cc9281278baa3e176d85991d60604E6e14e4

Protocol Contracts:
    PlatformToken (PDX): 0xf071e080dc3A91FD9720Fe8B0E65BeA605F83499
    PriceOracle: 0xC6323a0186E1cAB9D7622d0F9a64230853be3743
    PerpetualTrading: 0x49182074794BE4398e60d690B4490ea1Addf5208
    SpotMarket: 0x1Ace5e44560BFF4496BC9a539a11438A4Ac2A5f2
    Staking: 0x0E2a395CBB03D736eF4E00AfeE6a34fDBD258323
    Vault: 0x751097800E50F570d62C09BAa325cF497376b263
    Governance: 0x6Cd3aB1D524467B7469b55Fa6FEe91Bc58c0BE4b
    LiquidityMining: 0x29AD2b79A776Bb387083380C131868B2552B20a5
    RewardDistributor: 0xA88B6764E7067f538Fa376112d2326413F8BE0Cf
  ========================================

  Deployment addresses saved to: ./deployments/qie-testnet-1991.json

========================================
  NEXT STEPS - TESTNET
  ========================================
  1. Mint mock tokens for testing:
     mockUSDT.mint(yourAddress, amount)
     mockBTC.mint(yourAddress, amount)

  2. Update mock price feeds:
     btcPriceFeed.updateAnswer(newPrice)
     ethPriceFeed.updateAnswer(newPrice)

  3. Test perpetual trading:
     - Approve mock USDT
     - Deposit collateral
     - Open positions (BTC, ETH, BNB, SOL, QIE)

  4. Create spot market pools

  5. Test staking and rewards

  6. Set up frontend with testnet addresses
  ========================================


SKIPPING ON CHAIN SIMULATION.
