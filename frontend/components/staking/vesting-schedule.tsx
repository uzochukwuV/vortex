"use client"

import { Calendar, Clock, Unlock } from "lucide-react"
import { Button } from "@/components/ui/button"

const vestingPositions = [
  {
    id: 1,
    amount: 5000,
    locked: "2024-06-15",
    unlocks: "2024-12-15",
    multiplier: 2.0,
    status: "locked",
    progress: 45,
  },
  {
    id: 2,
    amount: 2500,
    locked: "2024-01-01",
    unlocks: "2024-07-01",
    multiplier: 1.5,
    status: "unlocking",
    progress: 90,
  },
  {
    id: 3,
    amount: 5000,
    locked: "2023-06-15",
    unlocks: "2024-06-15",
    multiplier: 3.0,
    status: "claimable",
    progress: 100,
  },
]

export function VestingSchedule() {
  return (
    <div className="bg-card border border-border rounded-xl overflow-hidden">
      <div className="p-5 border-b border-border">
        <h3 className="font-semibold text-lg">Vesting Schedule</h3>
        <p className="text-sm text-muted-foreground mt-1">Track your locked positions and upcoming unlocks.</p>
      </div>

      <div className="divide-y divide-border">
        {vestingPositions.map((position) => (
          <div key={position.id} className="p-5">
            <div className="flex items-start justify-between mb-4">
              <div>
                <div className="font-semibold text-lg">{position.amount.toLocaleString()} VTX</div>
                <div className="text-sm text-muted-foreground flex items-center gap-1 mt-1">
                  <Calendar className="w-3 h-3" />
                  Locked: {position.locked}
                </div>
              </div>
              <div className="text-right">
                <span
                  className={`text-xs px-2 py-1 rounded-full ${
                    position.status === "claimable"
                      ? "bg-green-500/20 text-green-500"
                      : position.status === "unlocking"
                        ? "bg-amber-500/20 text-amber-500"
                        : "bg-secondary text-muted-foreground"
                  }`}
                >
                  {position.status === "claimable"
                    ? "Ready to Claim"
                    : position.status === "unlocking"
                      ? "Unlocking Soon"
                      : "Locked"}
                </span>
                <div className="text-sm text-muted-foreground mt-2">{position.multiplier}x boost</div>
              </div>
            </div>

            {/* Progress bar */}
            <div className="mb-3">
              <div className="h-2 bg-secondary rounded-full overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all ${
                    position.status === "claimable" ? "bg-green-500" : "bg-primary"
                  }`}
                  style={{ width: `${position.progress}%` }}
                />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1 text-sm text-muted-foreground">
                <Clock className="w-3 h-3" />
                Unlocks: {position.unlocks}
              </div>
              {position.status === "claimable" ? (
                <Button size="sm" className="gap-1 bg-green-600 hover:bg-green-700 text-white">
                  <Unlock className="w-3 h-3" />
                  Claim
                </Button>
              ) : (
                <span className="text-sm text-muted-foreground">{100 - position.progress}% remaining</span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
