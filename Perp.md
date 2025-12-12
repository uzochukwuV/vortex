# GMX-Style Perpetual DEX Architecture Research

## Overview

This document provides comprehensive research on building a GMX-style perpetual decentralized exchange (DEX) on Base chain. GMX is one of the leading perpetual DEXs in DeFi, utilizing an innovative multi-asset liquidity pool model that eliminates the need for traditional order books.

## Key Findings

### 1. Core Perpetual Trading Mechanics

#### GLP Pool Architecture

**Multi-Asset Liquidity Pool:**
- The GLP (GMX Liquidity Provider) pool is the cornerstone of GMX's architecture
- Comprises a basket of top assets: ETH, BTC (WBTC), stablecoins (USDC, USDT), and sometimes other blue-chip tokens
- Pool composition is dynamic and designed to balance risk and liquidity
- Target weights are maintained through dynamic fee adjustments

**How It Works:**
- Liquidity providers mint GLP tokens by depositing any supported asset
- Deposits are automatically rebalanced into the pool's target composition
- The pool acts as the counterparty to all leveraged trades
- When traders profit, the pool pays out; when traders lose, the pool gains

**Revenue Model:**
- GLP holders earn from multiple sources:
  - Trading fees (open/close positions)
  - Borrowing fees (funding rates for leveraged positions)
  - Liquidation fees
  - Swap fees
- Yields are distributed in native chain tokens (ETH on Arbitrum, AVAX on Avalanche)

#### Position Management

**GMX V2 Architecture:**

**Market Contracts:**
- Each trading pair (ETH/USD, BTC/USD) has isolated market contracts
- Risk isolation prevents contagion between different markets
- Allows for market-specific configurations and parameters

**Position Manager:**
- Handles all user interactions for positions
- Core functions:
  - Opening positions (long/short with leverage)
  - Modifying positions (adding/removing collateral, adjusting size)
  - Closing positions
  - Triggering liquidations

**Position Lifecycle:**

1. **Opening:**
   - User specifies market, size, collateral, direction (long/short)
   - Position Manager fetches current price from oracle
   - Validates margin requirements and applies fees
   - Creates position (often as NFT in V2)
   - Updates vault and market state

2. **Modifying:**
   - Users can add/remove collateral
   - Adjust position size
   - Contract validates new margin requirements
   - Updates balances and position parameters

3. **Closing:**
   - PnL calculated based on current oracle price
   - Collateral + PnL (minus fees) returned to user
   - Position record deleted or NFT burned

4. **Liquidation:**
   - Triggered when margin falls below maintenance threshold
   - Any party can execute liquidation
   - Liquidator receives reward
   - Remaining collateral handled per protocol rules

#### PnL Calculations

**Formula:**
```
For Long Positions:
PnL = Position Size × (Current Price - Entry Price) / Entry Price

For Short Positions:
PnL = Position Size × (Entry Price - Current Price) / Entry Price
```

**Mark Price:**
- Uses oracle prices (not internal AMM prices) to prevent manipulation
- Typically aggregates multiple price sources
- Time-weighted average price (TWAP) for stability

**Unrealized vs Realized PnL:**
- Unrealized: Calculated continuously based on mark price
- Realized: Locked in when position is closed
- Funding fees accrue over time and affect net PnL

#### Leverage System

**Leverage Mechanics:**
- GMX offers up to 50x leverage on major pairs
- Leverage = Position Size / Collateral
- Higher leverage = lower liquidation threshold

**Margin Requirements:**
- Initial Margin: Required to open position
- Maintenance Margin: Minimum to keep position open
- Typical maintenance margin: 1-2% of position size

**Liquidation Threshold:**
```
Liquidation Price (Long) = Entry Price × (1 - (Collateral - Fees) / Position Size)
Liquidation Price (Short) = Entry Price × (1 + (Collateral - Fees) / Position Size)
```

#### Liquidation Mechanism

**Trigger Conditions:**
- Position equity falls below maintenance margin
- Calculated using mark price (oracle-based)

**Process:**
1. Liquidator calls liquidation function
2. Contract verifies position is liquidatable
3. Position closed at mark price
4. Liquidation fee paid to liquidator
5. Remaining collateral (if any) handled per protocol rules

**Protection Mechanisms:**
- Partial liquidations: Close only portion needed to restore health
- Cooldown periods: Prevent instant liquidations on price spikes
- Oracle aggregation: Use multiple sources to prevent manipulation
- Spread protection: Ignore outlier prices

### 2. Fee Structures and Tokenomics

#### Fee Distribution Models

**V1 Model:**
- 70% of platform fees → GLP holders
- 30% of platform fees → GMX stakers
- Distributed in native chain tokens (ETH/AVAX)

**V2 Model (Updated):**
- 63% of fees → Liquidity providers (GLP/GM pools)
- 27% of fees → GMX stakers
- 10% of fees → GMX Treasury (for sustainability)

#### Fee Types

**Trading Fees:**
- Position open/close fees: ~0.1% of position size
- Swap fees: 0.2-0.8% (dynamic based on pool composition)
- Borrowing fees: Hourly rate based on utilization

**Dynamic Fee Adjustment:**
- Mint/redemption fees: 0-80 basis points
- Adjusted based on asset weight vs target weight
- Incentivizes deposits of underweight assets
- Discourages deposits of overweight assets

#### Token Economics

**GMX Token:**
- Governance and utility token
- Staking rewards:
  - Share of platform fees (27-30%)
  - esGMX (Escrowed GMX) emissions
  - Multiplier Points for boosted rewards

**GLP Token:**
- Represents share of liquidity pool
- Fungible token (V1) or position-specific (V2)
- Value fluctuates based on:
  - Pool asset values
  - Trader PnL (inversely correlated)
  - Accumulated fees

**esGMX (Escrowed GMX):**
- Non-transferable reward token
- Can be staked like regular GMX
- Can be vested to GMX over 365 days
- Vesting requires reserving equivalent GMX/GLP
- Reduces selling pressure and aligns long-term incentives

**Multiplier Points:**
- Awarded at 100% APR to GMX stakers
- Boost reward yields
- Burned proportionally when unstaking
- Encourages long-term staking

### 3. Risk Management Systems

#### Oracle-Based Risk Controls

**Multi-Source Price Aggregation:**
- Combines Chainlink, Binance, and other sources
- Uses median filtering to remove outliers
- TWAP mechanisms for stability
- Prevents single-source manipulation

**Staleness Checks:**
- Validates price freshness via timestamps
- Rejects stale data beyond heartbeat interval
- Fallback mechanisms for oracle failures

#### Position Risk Management

**Utilization Limits:**
- Maximum open interest per market
- Prevents pool from being over-exposed
- Dynamic based on pool size and composition

**Funding Rates:**
- Balance long/short open interest
- Charged hourly to over-weighted side
- Paid to under-weighted side
- Incentivizes market balance

**Insurance Mechanisms:**
- Protocol reserves for unexpected losses
- Funded by portion of fees
- Covers bad debt from liquidations
- Protects GLP holders from extreme events

#### Liquidity Risk Controls

**Pool Composition Targets:**
- Maintain balanced asset weights
- Dynamic fees encourage rebalancing
- Prevents concentration risk

**Maximum Position Sizes:**
- Caps on individual position sizes
- Prevents single positions from dominating pool
- Reduces systemic risk

## Recommendations

### For Base Chain Implementation

**1. Leverage Base's Infrastructure:**
- Lower gas costs compared to Ethereum mainnet
- Fast block times for better UX
- Growing DeFi ecosystem for integrations

**2. Oracle Strategy:**
- Use Chainlink price feeds (well-supported on Base)
- Implement multi-source aggregation
- Add circuit breakers for extreme price movements

**3. Liquidity Bootstrap:**
- Start with major pairs: ETH/USD, BTC/USD
- Incentivize early GLP providers with boosted rewards
- Partner with Base ecosystem projects for liquidity

**4. Security First:**
- Multiple audits before mainnet launch
- Gradual rollout with position size caps
- Bug bounty program
- Insurance fund from day one

**5. Modular Architecture:**
- Separate contracts for different markets
- Upgradeable components with timelock governance
- Clear separation of concerns

## Implementation Notes

### Smart Contract Architecture

**Core Contracts:**
```
PositionManager.sol - Handles position lifecycle
MarketFactory.sol - Creates and manages markets
Vault.sol - Holds collateral and manages balances
Oracle.sol - Price feed aggregation and validation
GLP.sol - Liquidity pool token
FeeDistributor.sol - Manages fee collection and distribution
Liquidator.sol - Handles liquidation logic
```

**Key Considerations:**
- Use proxy patterns for upgradeability
- Implement comprehensive access controls
- Emit detailed events for off-chain indexing
- Optimize for gas efficiency

### Technical Requirements

**Dependencies:**
- Solidity ^0.8.0
- OpenZeppelin contracts (security, access control)
- Chainlink oracle interfaces
- ERC-20, ERC-721 standards

**Infrastructure:**
- Subgraph for indexing events
- Off-chain keeper network for liquidations
- Price feed monitoring system
- Frontend with real-time position tracking

### Potential Challenges

**1. Oracle Reliability:**
- Mitigation: Multi-source aggregation, fallback mechanisms
- Monitor oracle health continuously

**2. Liquidation Cascades:**
- Mitigation: Partial liquidations, cooldown periods
- Insurance fund for extreme scenarios

**3. GLP Holder Risk:**
- Mitigation: Diversified pool composition, position limits
- Clear communication of risks

**4. Smart Contract Risk:**
- Mitigation: Multiple audits, gradual rollout, bug bounties
- Formal verification for critical components

## Sources

- [GMX Documentation](https://gmxio.gitbook.io/gmx/)
- [GMX V2 GitHub](https://github.com/gmx-io/gmx-synthetics)
- [GMX Tokenomics Analysis](https://alearesearch.io/deep-dives/gmx/)
- [CoinMarketCap GMX Deep Dive](https://coinmarketcap.com/academy/article/a-deep-dive-into-gmx)

## Next Steps

1. Review Chainlink integration documentation (see chainlink-base-integration.md)
2. Design spot market integration (see spot-market-implementation.md)
3. Plan tokenomics and staking system (see platform-token-staking.md)
4. Conduct security audit planning (see security-best-practices.md)
