import { AppHeader } from "@/components/app/app-header"
import { SwapCard } from "@/components/spot/swap-card"
import { RecentTrades } from "@/components/spot/recent-trades"
import { TokenBalances } from "@/components/spot/token-balances"

export default function SpotPage() {
  return (
    <div className="min-h-screen bg-background">
      <AppHeader />

      <main className="p-6">
        <div className="max-w-6xl mx-auto">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold mb-2">Spot Trading</h1>
            <p className="text-muted-foreground">Swap tokens instantly with deep liquidity and minimal slippage.</p>
          </div>

          <div className="grid lg:grid-cols-3 gap-6">
            {/* Swap card - center */}
            <div className="lg:col-span-2 flex justify-center">
              <SwapCard />
            </div>

            {/* Sidebar */}
            <div className="space-y-6">
              <TokenBalances />
              <RecentTrades />
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
