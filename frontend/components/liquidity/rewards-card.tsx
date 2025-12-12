"use client"

import { Gift, Clock, ArrowRight } from "lucide-react"
import { Button } from "@/components/ui/button"

const rewards = [
  { token: "VTX", amount: 125.5, value: 376.5, claimable: true },
  { token: "ETH", amount: 0.05, value: 177.11, claimable: true },
  { token: "VTX", amount: 500, value: 1500, claimable: false, unlockTime: "3 days" },
]

export function RewardsCard() {
  const totalClaimable = rewards.filter((r) => r.claimable).reduce((sum, r) => sum + r.value, 0)
  const totalPending = rewards.filter((r) => !r.claimable).reduce((sum, r) => sum + r.value, 0)

  return (
    <div className="bg-card border border-border rounded-xl overflow-hidden">
      <div className="p-5 border-b border-border">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
            <Gift className="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 className="font-semibold">Your Rewards</h3>
            <p className="text-sm text-muted-foreground">Earnings from liquidity provision</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="bg-green-500/10 rounded-lg p-4">
            <span className="text-xs text-muted-foreground block mb-1">Claimable</span>
            <span className="text-2xl font-bold text-green-500">${totalClaimable.toFixed(2)}</span>
          </div>
          <div className="bg-secondary/50 rounded-lg p-4">
            <span className="text-xs text-muted-foreground block mb-1">Pending</span>
            <span className="text-2xl font-bold">${totalPending.toFixed(2)}</span>
          </div>
        </div>
      </div>

      <div className="divide-y divide-border">
        {rewards.map((reward, index) => (
          <div key={index} className="p-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-primary/20 rounded-full flex items-center justify-center">
                <span className="text-primary font-bold text-xs">{reward.token.slice(0, 2)}</span>
              </div>
              <div>
                <div className="font-medium">
                  {reward.amount} {reward.token}
                </div>
                <div className="text-sm text-muted-foreground">${reward.value.toFixed(2)}</div>
              </div>
            </div>
            {reward.claimable ? (
              <Button size="sm" className="bg-primary text-primary-foreground hover:bg-primary/90">
                Claim
              </Button>
            ) : (
              <div className="flex items-center gap-1 text-sm text-muted-foreground">
                <Clock className="w-3 h-3" />
                {reward.unlockTime}
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="p-5 border-t border-border">
        <Button className="w-full gap-2 bg-primary text-primary-foreground hover:bg-primary/90">
          Claim All Rewards
          <ArrowRight className="w-4 h-4" />
        </Button>
      </div>
    </div>
  )
}
