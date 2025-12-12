"use client"

import { useState } from "react"
import { Lock, Unlock, Info, AlertCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

const lockPeriods = [
  { days: 0, multiplier: 1, label: "Flexible" },
  { days: 30, multiplier: 1.2, label: "30 Days" },
  { days: 90, multiplier: 1.5, label: "90 Days" },
  { days: 180, multiplier: 2.0, label: "180 Days" },
  { days: 365, multiplier: 3.0, label: "1 Year" },
]

export function StakeCard() {
  const [stakeAmount, setStakeAmount] = useState("")
  const [unstakeAmount, setUnstakeAmount] = useState("")
  const [selectedPeriod, setSelectedPeriod] = useState(0)

  const baseApr = 32.5
  const currentMultiplier = lockPeriods[selectedPeriod].multiplier
  const effectiveApr = (baseApr * currentMultiplier).toFixed(1)
  const walletBalance = 5000
  const stakedBalance = 12500

  return (
    <div className="bg-card border border-border rounded-xl overflow-hidden">
      <Tabs defaultValue="stake" className="w-full">
        <div className="p-5 border-b border-border">
          <TabsList className="w-full grid grid-cols-2 bg-secondary">
            <TabsTrigger value="stake" className="gap-2">
              <Lock className="w-4 h-4" />
              Stake
            </TabsTrigger>
            <TabsTrigger value="unstake" className="gap-2">
              <Unlock className="w-4 h-4" />
              Unstake
            </TabsTrigger>
          </TabsList>
        </div>

        <TabsContent value="stake" className="p-5 space-y-6 m-0">
          {/* Amount input */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Amount to Stake</span>
              <span className="text-xs text-muted-foreground">Balance: {walletBalance.toLocaleString()} VTX</span>
            </div>
            <div className="relative">
              <Input
                type="number"
                placeholder="0.0"
                value={stakeAmount}
                onChange={(e) => setStakeAmount(e.target.value)}
                className="bg-secondary border-border pr-20 text-lg h-14"
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-2">
                <button
                  onClick={() => setStakeAmount(walletBalance.toString())}
                  className="text-xs text-primary hover:text-primary/80"
                >
                  MAX
                </button>
                <span className="text-sm font-medium">VTX</span>
              </div>
            </div>
            <div className="flex gap-2">
              {[25, 50, 75, 100].map((pct) => (
                <button
                  key={pct}
                  onClick={() => setStakeAmount(((walletBalance * pct) / 100).toString())}
                  className="flex-1 py-1.5 text-xs rounded border border-border text-muted-foreground hover:border-muted-foreground transition-colors"
                >
                  {pct}%
                </button>
              ))}
            </div>
          </div>

          {/* Lock period selection */}
          <div className="space-y-3">
            <div className="flex items-center gap-2">
              <span className="text-sm text-muted-foreground">Lock Period</span>
              <Info className="w-3 h-3 text-muted-foreground" />
            </div>
            <div className="grid grid-cols-5 gap-2">
              {lockPeriods.map((period, index) => (
                <button
                  key={index}
                  onClick={() => setSelectedPeriod(index)}
                  className={`p-3 rounded-lg border text-center transition-all ${
                    selectedPeriod === index
                      ? "bg-primary/20 border-primary"
                      : "border-border hover:border-muted-foreground"
                  }`}
                >
                  <div className="text-sm font-medium">{period.label}</div>
                  <div className={`text-xs ${selectedPeriod === index ? "text-primary" : "text-muted-foreground"}`}>
                    {period.multiplier}x
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Summary */}
          <div className="p-4 bg-secondary/50 rounded-xl space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Effective APR</span>
              <span className="text-lg font-bold text-green-500">{effectiveApr}%</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Lock Multiplier</span>
              <span className="font-mono">{currentMultiplier}x</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Est. Daily Rewards</span>
              <span className="font-mono text-green-500">
                ~
                {stakeAmount
                  ? ((Number.parseFloat(stakeAmount) * Number.parseFloat(effectiveApr)) / 365 / 100).toFixed(2)
                  : "0"}{" "}
                VTX
              </span>
            </div>
            {selectedPeriod > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Unlock Date</span>
                <span className="font-mono">
                  {new Date(Date.now() + lockPeriods[selectedPeriod].days * 24 * 60 * 60 * 1000).toLocaleDateString()}
                </span>
              </div>
            )}
          </div>

          {/* Warning for locked staking */}
          {selectedPeriod > 0 && (
            <div className="flex items-start gap-2 p-3 bg-amber-500/10 border border-amber-500/20 rounded-lg">
              <AlertCircle className="w-4 h-4 text-amber-500 mt-0.5 flex-shrink-0" />
              <p className="text-sm text-amber-500">
                Locked tokens cannot be withdrawn before the lock period ends. Early withdrawal is not available.
              </p>
            </div>
          )}

          <Button
            className="w-full py-6 text-lg font-semibold bg-primary text-primary-foreground hover:bg-primary/90"
            disabled={!stakeAmount || Number.parseFloat(stakeAmount) <= 0}
          >
            {!stakeAmount ? "Enter Amount" : "Stake VTX"}
          </Button>
        </TabsContent>

        <TabsContent value="unstake" className="p-5 space-y-6 m-0">
          {/* Amount input */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Amount to Unstake</span>
              <span className="text-xs text-muted-foreground">Staked: {stakedBalance.toLocaleString()} VTX</span>
            </div>
            <div className="relative">
              <Input
                type="number"
                placeholder="0.0"
                value={unstakeAmount}
                onChange={(e) => setUnstakeAmount(e.target.value)}
                className="bg-secondary border-border pr-20 text-lg h-14"
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-2">
                <button
                  onClick={() => setUnstakeAmount(stakedBalance.toString())}
                  className="text-xs text-primary hover:text-primary/80"
                >
                  MAX
                </button>
                <span className="text-sm font-medium">VTX</span>
              </div>
            </div>
            <div className="flex gap-2">
              {[25, 50, 75, 100].map((pct) => (
                <button
                  key={pct}
                  onClick={() => setUnstakeAmount(((stakedBalance * pct) / 100).toString())}
                  className="flex-1 py-1.5 text-xs rounded border border-border text-muted-foreground hover:border-muted-foreground transition-colors"
                >
                  {pct}%
                </button>
              ))}
            </div>
          </div>

          {/* Summary */}
          <div className="p-4 bg-secondary/50 rounded-xl space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">You will receive</span>
              <span className="font-mono">{unstakeAmount || 0} VTX</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Cooldown Period</span>
              <span className="font-mono">7 days</span>
            </div>
          </div>

          <div className="flex items-start gap-2 p-3 bg-secondary/50 border border-border rounded-lg">
            <Info className="w-4 h-4 text-muted-foreground mt-0.5 flex-shrink-0" />
            <p className="text-sm text-muted-foreground">
              Unstaking requires a 7-day cooldown period. Your tokens will be available for withdrawal after this
              period.
            </p>
          </div>

          <Button
            className="w-full py-6 text-lg font-semibold bg-red-600 hover:bg-red-700 text-white"
            disabled={!unstakeAmount || Number.parseFloat(unstakeAmount) <= 0}
          >
            {!unstakeAmount ? "Enter Amount" : "Unstake VTX"}
          </Button>
        </TabsContent>
      </Tabs>
    </div>
  )
}
