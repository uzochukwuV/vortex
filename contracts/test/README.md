# PerpetualTrading Contract Test Suite

This directory contains comprehensive tests for the PerpetualTrading smart contract, covering functionality, security, and integration aspects.

## Test Files

### 1. `PerpetualTrading.t.sol`
**Main functionality tests**
- Position opening/closing
- Leverage validation
- Fee calculations
- Liquidation mechanics
- Funding rate updates
- Open interest tracking
- Access controls
- Fuzz testing

### 2. `PerpetualTradingSecurity.t.sol`
**Security-focused tests**
- Fee transfer before collateral validation vulnerability
- Liquidation threshold boundary conditions
- Funding payment overflow protection
- Negative collateral handling
- Reentrancy protection
- Oracle manipulation resistance
- Position size limits
- Gas griefing protection

### 3. `PerpetualTradingIntegration.t.sol`
**Integration tests with Vault contract**
- Vault liquidity reservation system
- Balance changes during position lifecycle
- Multiple positions affecting reserves
- Insufficient liquidity protection
- Authorization system
- Liquidation with vault interaction
- Fee collection integration
- State consistency during complex operations

### 4. `mocks/`
**Mock contracts for testing**
- `MockERC20.sol` - ERC20 token with mint/burn functions
- `MockAggregatorV3.sol` - Chainlink price feed mock

## Critical Issues Identified

The tests reveal several critical vulnerabilities in the current implementation:

### 🔴 Critical Issues
1. **Incorrect Liquidation Threshold Logic** (Line 310-312)
   - Uses `<=` instead of `<` for liquidation check
   - Positions can be liquidated when they still have 20% collateral

2. **Fee Transfer Before Collateral Validation** (Line 158-162)
   - Fees are transferred before validating sufficient collateral
   - Users can lose fees without getting a position

### 🟡 Medium Issues
3. **Missing Funding Payment Validation** (Line 240-245)
   - No validation if position has sufficient collateral for funding payments
   - Large negative funding could make positions insolvent

4. **No Validation for Negative Collateral Returns** (Line 280-285)
   - When closing positions with negative collateral, vault could become insolvent

5. **Funding Payment Calculation Overflow Risk** (Line 430-440)
   - Large number multiplication without overflow protection

## Running Tests

### Prerequisites
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

### Run All Tests
```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/PerpetualTrading.t.sol

# Run specific test function
forge test --match-test testOpenPositionSuccess

# Run with gas reporting
forge test --gas-report
```

### Run Security Tests
```bash
# Run only security-focused tests
forge test --match-path test/PerpetualTradingSecurity.t.sol -vvv

# Run specific security test
forge test --match-test testLiquidationThresholdBoundary -vvv
```

### Run Integration Tests
```bash
# Run integration tests
forge test --match-path test/PerpetualTradingIntegration.t.sol -vvv
```

### Coverage Analysis
```bash
# Generate coverage report
forge coverage

# Generate detailed coverage report
forge coverage --report lcov
```

## Test Results Summary

### Expected Test Results
- **Basic Functionality**: ✅ Most tests should pass
- **Security Tests**: ❌ Several tests will fail due to identified vulnerabilities
- **Integration Tests**: ✅ Should pass with proper vault setup

### Key Test Failures to Investigate
1. `testLiquidationThresholdBoundary` - Exposes the `<=` vs `<` bug
2. `testFeeTransferBeforeCollateralValidation` - Shows fee loss vulnerability
3. `testFundingPaymentOverflow` - May cause reverts with extreme values
4. `testNegativeCollateralHandling` - Vault insolvency risk

## Recommendations

### Immediate Fixes Required
1. **Fix liquidation logic**: Change `<=` to `<` in liquidation check
2. **Reorder fee transfers**: Validate collateral before transferring fees
3. **Add overflow protection**: Use SafeMath or check for overflows in funding calculations
4. **Validate negative collateral**: Ensure vault doesn't lose more than position collateral

### Additional Security Measures
1. **Add circuit breakers**: Implement maximum daily loss limits
2. **TWAP oracle integration**: Reduce oracle manipulation risks
3. **Position size limits per user**: Prevent concentration risk
4. **Emergency pause mechanism**: Allow pausing in case of exploits

### Testing Improvements
1. **Add invariant tests**: Ensure vault solvency is maintained
2. **Property-based testing**: Use more extensive fuzz testing
3. **Formal verification**: Consider formal verification for critical functions
4. **Mainnet fork testing**: Test against real market conditions

## Gas Optimization

The tests also help identify gas optimization opportunities:
- Position opening: ~300k gas
- Position closing: ~250k gas
- Liquidation: ~200k gas

Consider optimizing storage reads/writes and reducing external calls.