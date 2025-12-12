import { AppHeader } from "@/components/app/app-header"
import { LiquidityStats } from "@/components/liquidity/liquidity-stats"
import { PoolCard } from "@/components/liquidity/pool-card"
import { RewardsCard } from "@/components/liquidity/rewards-card"

const pools = [
  {
    id: "1",
    token0: "ETH",
    token1: "USDC",
    tvl: 45000000,
    apr: 18.5,
    volume24h: 12000000,
    fees24h: 36000,
    userDeposit: 5000,
    userEarnings: 125.5,
  },
  {
    id: "2",
    token0: "BTC",
    token1: "USDC",
    tvl: 32000000,
    apr: 15.2,
    volume24h: 8500000,
    fees24h: 25500,
    userDeposit: 7450,
    userEarnings: 234.2,
  },
  {
    id: "3",
    token0: "SOL",
    token1: "USDC",
    tvl: 8500000,
    apr: 32.8,
    volume24h: 4200000,
    fees24h: 12600,
  },
  {
    id: "4",
    token0: "AVAX",
    token1: "USDC",
    tvl: 5200000,
    apr: 28.4,
    volume24h: 2100000,
    fees24h: 6300,
  },
  {
    id: "5",
    token0: "ETH",
    token1: "BTC",
    tvl: 18000000,
    apr: 12.1,
    volume24h: 5600000,
    fees24h: 16800,
  },
  {
    id: "6",
    token0: "ARB",
    token1: "ETH",
    tvl: 3800000,
    apr: 45.2,
    volume24h: 1800000,
    fees24h: 5400,
  },
]

export default function LiquidityPage() {
  return (
    <div className="min-h-screen bg-background">
      <AppHeader />

      <main className="p-6">
        <div className="max-w-7xl mx-auto space-y-8">
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold mb-2">Liquidity Mining</h1>
            <p className="text-muted-foreground">
              Provide liquidity to earn trading fees and token rewards. Auto-compounding available.
            </p>
          </div>

          {/* Stats */}
          <LiquidityStats />

          <div className="grid lg:grid-cols-3 gap-6">
            {/* Pools grid */}
            <div className="lg:col-span-2 space-y-6">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-semibold">Available Pools</h2>
                <div className="flex gap-2">
                  <select className="bg-secondary border border-border rounded-lg px-3 py-2 text-sm">
                    <option>Sort by APR</option>
                    <option>Sort by TVL</option>
                    <option>Sort by Volume</option>
                  </select>
                </div>
              </div>

              <div className="grid md:grid-cols-2 gap-4">
                {pools.map((pool) => (
                  <PoolCard key={pool.id} pool={pool} />
                ))}
              </div>
            </div>

            {/* Rewards sidebar */}
            <div className="space-y-6">
              <RewardsCard />
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
