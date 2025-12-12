# Frontend Analysis - GMX-Style Perpetual DEX

## Overview

The frontend is built with **Next.js 16 (App Router)** using modern React 19 and TypeScript, with a comprehensive UI component library based on Radix UI and Tailwind CSS.

## Current Status

✅ **Completed**:
- Landing page structure
- Trading UI components
- Spot market interface
- Liquidity pools UI
- Staking interface
- Component library (Shadcn/UI style)

❌ **Missing** (Critical for functionality):
- Web3/Blockchain integration
- Smart contract connections
- Wallet connectivity
- Real blockchain data
- Transaction handling

---

## Technology Stack

### Core Framework
- **Next.js 16.0.7** - App Router (latest)
- **React 19.2.0** - Latest React
- **TypeScript 5** - Type safety

### UI Components
- **Radix UI** - Accessible component primitives
- **Tailwind CSS 4.1.9** - Utility-first CSS
- **Lucide React** - Icon library
- **Recharts** - Charts for trading data
- **Sonner** - Toast notifications

### Forms & Validation
- **React Hook Form 7.60.0** - Form management
- **Zod 3.25.76** - Schema validation

### Current Dependencies
```json
{
  "next": "16.0.7",
  "react": "19.2.0",
  "tailwindcss": "^4.1.9"
}
```

---

## Project Structure

```
frontend/
├── app/
│   ├── layout.tsx          # Root layout with dark theme
│   ├── page.tsx            # Landing page
│   ├── trade/              # Perpetual trading page
│   ├── spot/               # Spot market page
│   ├── liquidity/          # Liquidity pools page
│   └── staking/            # Staking page
│
├── components/
│   ├── ui/                 # Reusable UI components (58 components)
│   ├── landing/            # Landing page sections
│   ├── trade/              # Trading interface components
│   ├── spot/               # Spot market components
│   ├── liquidity/          # Liquidity pool components
│   ├── staking/            # Staking components
│   ├── web3/               # Web3 integration (placeholder)
│   └── app/                # App-wide components
│
└── lib/
    └── utils.ts            # Utility functions
```

---

## Existing Components Analysis

### Landing Page Components
- ✅ `landing-header.tsx` - Navigation header
- ✅ `hero-section.tsx` - Hero section
- ✅ `features-section.tsx` - Features showcase
- ✅ `stats-section.tsx` - Platform statistics
- ✅ `cta-section.tsx` - Call-to-action
- ✅ `footer.tsx` - Footer

### Trading Interface
- ✅ `market-selector.tsx` - Asset selection dropdown
- ✅ `price-chart.tsx` - Price chart display
- ✅ `order-panel.tsx` - Order entry form
- ✅ `order-book.tsx` - Order book visualization
- ✅ `positions-panel.tsx` - Active positions table
- ✅ `market-stats.tsx` - Market statistics
- ✅ `trade-page.tsx` - Main trading page layout

### Spot Market
- ✅ `token-selector.tsx` - Token pair selection
- ✅ `swap-card.tsx` - Swap interface
- ✅ `recent-trades.tsx` - Recent swap history
- ✅ `token-balances.tsx` - User token balances

### Liquidity Pools
- ✅ `pool-card.tsx` - Individual pool display
- ✅ `rewards-card.tsx` - Rewards summary
- ✅ `liquidity-stats.tsx` - Pool statistics

### Staking
- ✅ `staking-overview.tsx` - Staking dashboard
- ✅ `stake-card.tsx` - Stake/unstake interface
- ✅ `staking-tiers.tsx` - Lock period tiers
- ✅ `vesting-schedule.tsx` - Vesting timeline

### Web3 (Placeholder)
- 📋 `wallet-modal.tsx` - Wallet connection modal (needs implementation)
- 📋 `transaction-modal.tsx` - Transaction status (needs implementation)

---

## What Needs to be Added

### 1. Web3 Integration Libraries

**Required Packages:**
```bash
npm install wagmi viem @tanstack/react-query
npm install @rainbow-me/rainbowkit  # Optional: Better wallet UX
```

**Why these?**
- `wagmi` - React hooks for Ethereum
- `viem` - TypeScript Ethereum library
- `@tanstack/react-query` - Data fetching/caching
- `rainbowkit` - Beautiful wallet connect UI

### 2. Contract Integration

Need to create:
- `lib/contracts/` - Contract ABIs and addresses
- `lib/hooks/` - Custom hooks for contract interactions
- `lib/providers/` - Web3 providers setup

### 3. QIE Blockchain Configuration

Add QIE network to wagmi config:
```typescript
const qieMainnet = {
  id: 1990,
  name: 'QIE Mainnet',
  network: 'qie',
  nativeCurrency: {
    decimals: 18,
    name: 'QIE',
    symbol: 'QIEV3',
  },
  rpcUrls: {
    default: { http: ['https://rpc5mainnet.qie.digital'] },
    public: { http: ['https://rpc5mainnet.qie.digital'] },
  },
  blockExplorers: {
    default: { name: 'QIE Explorer', url: 'https://mainnet.qie.digital' },
  },
}
```

### 4. Smart Contract Hooks

Need hooks for each contract:
- `usePerpetualTrading()` - Open/close positions
- `useSpotMarket()` - Swap tokens, create pools
- `useStaking()` - Stake/unstake tokens
- `useLiquidityMining()` - Deposit/withdraw LP tokens
- `usePriceOracle()` - Fetch asset prices
- `useVault()` - Add/remove liquidity

### 5. Real-Time Data

- WebSocket connections for live prices
- Event listeners for transactions
- Price feed updates from oracles

---

## Implementation Priority

### Phase 1: Core Web3 Setup (Week 1)
1. ✅ Install Web3 libraries
2. ✅ Configure QIE network
3. ✅ Set up Wagmi provider
4. ✅ Implement wallet connection
5. ✅ Add network switching

### Phase 2: Contract Integration (Week 2)
1. ✅ Generate/import contract ABIs
2. ✅ Create contract hooks
3. ✅ Connect to deployed contracts
4. ✅ Test basic reads (balances, prices)

### Phase 3: Trading Features (Week 3)
1. ✅ Connect perpetual trading UI
2. ✅ Implement order placement
3. ✅ Show active positions
4. ✅ Enable position closing
5. ✅ Add liquidation monitoring

### Phase 4: Spot & Liquidity (Week 4)
1. ✅ Connect spot swap interface
2. ✅ Pool creation
3. ✅ Add/remove liquidity
4. ✅ Liquidity mining deposits

### Phase 5: Staking & Governance (Week 5)
1. ✅ Staking interface
2. ✅ Rewards claiming
3. ✅ Governance voting
4. ✅ Proposal creation

### Phase 6: Polish & Optimization (Week 6)
1. ✅ Error handling
2. ✅ Loading states
3. ✅ Transaction notifications
4. ✅ Performance optimization
5. ✅ Mobile responsiveness

---

## Design System

### Theme
- **Mode**: Dark theme (hardcoded in layout)
- **Colors**: Uses Tailwind CSS variables
- **Typography**:
  - Oxanium (headings)
  - Space Grotesk (body)
  - Source Code Pro (monospace)
  - Source Serif 4 (serif)

### Component Library
- Based on Shadcn/UI patterns
- Radix UI primitives
- Fully accessible (ARIA compliant)
- Responsive by default

---

## Key Files to Modify

### 1. `app/layout.tsx`
Add Web3 providers:
```typescript
import { WagmiConfig } from 'wagmi'
import { RainbowKitProvider } from '@rainbow-me/rainbowkit'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <WagmiConfig config={wagmiConfig}>
          <RainbowKitProvider>
            {children}
          </RainbowKitProvider>
        </WagmiConfig>
      </body>
    </html>
  )
}
```

### 2. Create `lib/wagmi.ts`
Configure chains and connectors

### 3. Create `lib/contracts/`
Store contract ABIs and addresses

### 4. Create `lib/hooks/`
Custom contract interaction hooks

### 5. Update Trading Components
Connect to real contract functions

---

## Environment Variables Needed

Create `.env.local`:
```env
# Contract Addresses (from deployment)
NEXT_PUBLIC_PRICE_ORACLE=0x...
NEXT_PUBLIC_PERPETUAL_TRADING=0x...
NEXT_PUBLIC_SPOT_MARKET=0x...
NEXT_PUBLIC_STAKING=0x...
NEXT_PUBLIC_VAULT=0x...
NEXT_PUBLIC_GOVERNANCE=0x...
NEXT_PUBLIC_LIQUIDITY_MINING=0x...
NEXT_PUBLIC_REWARD_DISTRIBUTOR=0x...
NEXT_PUBLIC_PLATFORM_TOKEN=0x...

# Network Configuration
NEXT_PUBLIC_CHAIN_ID=1990
NEXT_PUBLIC_RPC_URL=https://rpc5mainnet.qie.digital
NEXT_PUBLIC_EXPLORER_URL=https://mainnet.qie.digital

# API Keys (if needed)
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

---

## Data Flow

### Current (Static)
```
Component → Static Data → UI Display
```

### Target (Live)
```
Component → Wagmi Hook → Smart Contract → Blockchain
                                       ↓
                             UI Update ← Events/State
```

---

## Testing Checklist

### Web3 Integration
- [ ] Wallet connects successfully
- [ ] Network switches to QIE
- [ ] Contract addresses load correctly
- [ ] ABIs are valid

### Perpetual Trading
- [ ] Can open long/short positions
- [ ] Positions display correctly
- [ ] Can close positions
- [ ] PnL calculates accurately
- [ ] Liquidations work

### Spot Market
- [ ] Token swaps execute
- [ ] Pool creation works
- [ ] Add/remove liquidity functions
- [ ] LP tokens mint/burn

### Staking
- [ ] Can stake tokens
- [ ] Lock periods apply correctly
- [ ] Rewards accrue
- [ ] Can claim rewards
- [ ] Can unstake after lock period

---

## Next Steps

1. **Install Web3 Dependencies**
   ```bash
   cd frontend
   npm install wagmi viem @tanstack/react-query @rainbow-me/rainbowkit
   ```

2. **Extract Contract ABIs**
   From `contracts/out/` directory

3. **Create Wagmi Configuration**
   Set up QIE network and providers

4. **Build Contract Hooks**
   One hook per contract

5. **Connect UI Components**
   Replace static data with real hooks

6. **Test on QIE Testnet**
   Deploy contracts, test frontend

7. **Deploy to Production**
   Connect to mainnet contracts

---

## Resources

- **Wagmi Docs**: https://wagmi.sh
- **Viem Docs**: https://viem.sh
- **RainbowKit**: https://www.rainbowkit.com
- **Next.js**: https://nextjs.org/docs
- **Radix UI**: https://www.radix-ui.com

---

## Estimated Timeline

- **Week 1-2**: Web3 integration & wallet connection
- **Week 3**: Contract hooks & basic interactions
- **Week 4**: Trading interface completion
- **Week 5**: Spot market & liquidity
- **Week 6**: Staking, governance, & polish

**Total**: 6 weeks for full integration

---

## Summary

✅ **Strengths**:
- Modern tech stack (React 19, Next.js 16)
- Complete UI component library
- Well-organized structure
- Beautiful design system

❌ **Gaps**:
- No blockchain integration
- Missing Web3 libraries
- Static data only
- No wallet connection

**Next Priority**: Add Web3 integration to connect UI to smart contracts!
