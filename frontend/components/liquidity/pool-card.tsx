"use client"

import { useState } from "react"
import { TrendingUp, Droplets, ExternalLink } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

interface Pool {
  id: string
  token0: string
  token1: string
  tvl: number
  apr: number
  volume24h: number
  fees24h: number
  userDeposit?: number
  userEarnings?: number
}

interface PoolCardProps {
  pool: Pool
}

export function PoolCard({ pool }: PoolCardProps) {
  const [depositAmount, setDepositAmount] = useState("")
  const [withdrawAmount, setWithdrawAmount] = useState("")
  const [isModalOpen, setIsModalOpen] = useState(false)

  return (
    <div className="bg-card border border-border rounded-xl overflow-hidden hover:border-primary/50 transition-colors">
      {/* Pool header */}
      <div className="p-5 border-b border-border">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex -space-x-2">
              <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center border-2 border-card z-10">
                <span className="text-primary font-bold text-xs">{pool.token0.slice(0, 2)}</span>
              </div>
              <div className="w-10 h-10 bg-secondary rounded-full flex items-center justify-center border-2 border-card">
                <span className="text-foreground font-bold text-xs">{pool.token1.slice(0, 2)}</span>
              </div>
            </div>
            <div>
              <h3 className="font-semibold text-lg">
                {pool.token0}/{pool.token1}
              </h3>
              <span className="text-xs text-muted-foreground">Liquidity Pool</span>
            </div>
          </div>
          <div className="text-right">
            <div className="flex items-center gap-1 text-green-500">
              <TrendingUp className="w-4 h-4" />
              <span className="text-xl font-bold">{pool.apr}%</span>
            </div>
            <span className="text-xs text-muted-foreground">APR</span>
          </div>
        </div>
      </div>

      {/* Pool stats */}
      <div className="p-5 grid grid-cols-3 gap-4 border-b border-border">
        <div>
          <span className="text-xs text-muted-foreground block mb-1">TVL</span>
          <span className="font-semibold font-mono">${(pool.tvl / 1000000).toFixed(2)}M</span>
        </div>
        <div>
          <span className="text-xs text-muted-foreground block mb-1">24h Volume</span>
          <span className="font-semibold font-mono">${(pool.volume24h / 1000000).toFixed(2)}M</span>
        </div>
        <div>
          <span className="text-xs text-muted-foreground block mb-1">24h Fees</span>
          <span className="font-semibold font-mono">${(pool.fees24h / 1000).toFixed(1)}K</span>
        </div>
      </div>

      {/* User position (if exists) */}
      {pool.userDeposit && (
        <div className="p-5 bg-primary/5 border-b border-border">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-muted-foreground">Your Deposit</span>
            <span className="font-semibold font-mono">${pool.userDeposit.toLocaleString()}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Earned</span>
            <span className="font-semibold font-mono text-green-500">+${pool.userEarnings?.toLocaleString()}</span>
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="p-5">
        <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
          <DialogTrigger asChild>
            <Button className="w-full gap-2 bg-primary text-primary-foreground hover:bg-primary/90">
              <Droplets className="w-4 h-4" />
              {pool.userDeposit ? "Manage Position" : "Add Liquidity"}
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-md bg-card border-border">
            <DialogHeader>
              <DialogTitle>
                {pool.token0}/{pool.token1} Pool
              </DialogTitle>
            </DialogHeader>

            <Tabs defaultValue="deposit" className="mt-4">
              <TabsList className="w-full grid grid-cols-2 bg-secondary">
                <TabsTrigger value="deposit">Deposit</TabsTrigger>
                <TabsTrigger value="withdraw">Withdraw</TabsTrigger>
              </TabsList>

              <TabsContent value="deposit" className="space-y-4 mt-4">
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">{pool.token0} Amount</span>
                    <span className="text-xs text-muted-foreground">Balance: 2.5</span>
                  </div>
                  <div className="relative">
                    <Input
                      type="number"
                      placeholder="0.0"
                      value={depositAmount}
                      onChange={(e) => setDepositAmount(e.target.value)}
                      className="bg-secondary border-border pr-16"
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm font-medium">{pool.token0}</span>
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">{pool.token1} Amount</span>
                    <span className="text-xs text-muted-foreground">Balance: 10,000</span>
                  </div>
                  <div className="relative">
                    <Input
                      type="number"
                      placeholder="0.0"
                      className="bg-secondary border-border pr-16"
                      readOnly
                      value={depositAmount ? (Number.parseFloat(depositAmount) * 3542).toFixed(2) : ""}
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm font-medium">{pool.token1}</span>
                  </div>
                </div>

                <div className="p-3 bg-secondary/50 rounded-lg space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Pool Share</span>
                    <span className="font-mono">0.05%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Est. Daily Earnings</span>
                    <span className="font-mono text-green-500">~$12.50</span>
                  </div>
                </div>

                <Button className="w-full py-6 bg-primary text-primary-foreground hover:bg-primary/90">
                  Add Liquidity
                </Button>
              </TabsContent>

              <TabsContent value="withdraw" className="space-y-4 mt-4">
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">Amount to Withdraw</span>
                    <span className="text-xs text-muted-foreground">
                      Available: ${pool.userDeposit?.toLocaleString() || 0}
                    </span>
                  </div>
                  <div className="relative">
                    <Input
                      type="number"
                      placeholder="0.0"
                      value={withdrawAmount}
                      onChange={(e) => setWithdrawAmount(e.target.value)}
                      className="bg-secondary border-border pr-16"
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm font-medium">USD</span>
                  </div>
                </div>

                <div className="flex gap-2">
                  {[25, 50, 75, 100].map((pct) => (
                    <button
                      key={pct}
                      onClick={() => setWithdrawAmount((((pool.userDeposit || 0) * pct) / 100).toString())}
                      className="flex-1 py-2 text-xs rounded border border-border text-muted-foreground hover:border-muted-foreground transition-colors"
                    >
                      {pct}%
                    </button>
                  ))}
                </div>

                <div className="p-3 bg-secondary/50 rounded-lg space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">You will receive</span>
                    <span className="font-mono">
                      {withdrawAmount || 0} {pool.token0} + {pool.token1}
                    </span>
                  </div>
                </div>

                <Button className="w-full py-6 bg-red-600 hover:bg-red-700 text-white">Withdraw Liquidity</Button>
              </TabsContent>
            </Tabs>
          </DialogContent>
        </Dialog>

        <a
          href="#"
          className="mt-3 flex items-center justify-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors"
        >
          View Pool Analytics
          <ExternalLink className="w-3 h-3" />
        </a>
      </div>
    </div>
  )
}
