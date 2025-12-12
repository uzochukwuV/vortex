"use client"

import { Check, Star, Crown, Gem } from "lucide-react"

const tiers = [
  {
    name: "Bronze",
    minStake: 0,
    maxStake: 1000,
    benefits: ["Base APR", "Standard fees"],
    icon: Star,
    color: "text-amber-600",
    bgColor: "bg-amber-600/10",
    borderColor: "border-amber-600/30",
  },
  {
    name: "Silver",
    minStake: 1000,
    maxStake: 10000,
    benefits: ["1.2x APR boost", "10% fee discount", "Priority support"],
    icon: Star,
    color: "text-gray-400",
    bgColor: "bg-gray-400/10",
    borderColor: "border-gray-400/30",
  },
  {
    name: "Gold",
    minStake: 10000,
    maxStake: 50000,
    benefits: ["1.5x APR boost", "25% fee discount", "Exclusive pools", "Governance voting"],
    icon: Crown,
    color: "text-amber-400",
    bgColor: "bg-amber-400/10",
    borderColor: "border-amber-400/30",
    current: true,
  },
  {
    name: "Diamond",
    minStake: 50000,
    maxStake: null,
    benefits: ["2x APR boost", "50% fee discount", "All pool access", "Protocol revenue share", "VIP events"],
    icon: Gem,
    color: "text-cyan-400",
    bgColor: "bg-cyan-400/10",
    borderColor: "border-cyan-400/30",
  },
]

export function StakingTiers() {
  const currentStake = 12500

  return (
    <div className="bg-card border border-border rounded-xl overflow-hidden">
      <div className="p-5 border-b border-border">
        <h3 className="font-semibold text-lg">Staking Tiers</h3>
        <p className="text-sm text-muted-foreground mt-1">
          Stake more VTX to unlock exclusive benefits and higher rewards.
        </p>
      </div>

      <div className="p-5 space-y-4">
        {tiers.map((tier, index) => {
          const isCurrentTier =
            currentStake >= tier.minStake && (tier.maxStake === null || currentStake < tier.maxStake)
          const isUnlocked = currentStake >= tier.minStake

          return (
            <div
              key={index}
              className={`p-4 rounded-xl border transition-all ${
                isCurrentTier
                  ? `${tier.bgColor} ${tier.borderColor} border-2`
                  : isUnlocked
                    ? "border-border bg-secondary/30"
                    : "border-border opacity-60"
              }`}
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-full ${tier.bgColor} flex items-center justify-center`}>
                    <tier.icon className={`w-5 h-5 ${tier.color}`} />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className={`font-semibold ${tier.color}`}>{tier.name}</span>
                      {isCurrentTier && (
                        <span className="text-xs px-2 py-0.5 bg-primary text-primary-foreground rounded-full">
                          Current
                        </span>
                      )}
                    </div>
                    <span className="text-sm text-muted-foreground">{tier.minStake.toLocaleString()}+ VTX</span>
                  </div>
                </div>
                {isUnlocked && <Check className="w-5 h-5 text-green-500" />}
              </div>

              <div className="flex flex-wrap gap-2">
                {tier.benefits.map((benefit, i) => (
                  <span
                    key={i}
                    className={`text-xs px-2 py-1 rounded-full ${
                      isUnlocked ? "bg-secondary text-foreground" : "bg-secondary/50 text-muted-foreground"
                    }`}
                  >
                    {benefit}
                  </span>
                ))}
              </div>
            </div>
          )
        })}
      </div>

      {/* Progress to next tier */}
      <div className="p-5 border-t border-border bg-secondary/20">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-muted-foreground">Progress to Diamond</span>
          <span className="text-sm font-mono">{currentStake.toLocaleString()} / 50,000 VTX</span>
        </div>
        <div className="h-2 bg-secondary rounded-full overflow-hidden">
          <div
            className="h-full bg-primary rounded-full transition-all"
            style={{ width: `${(currentStake / 50000) * 100}%` }}
          />
        </div>
        <p className="text-xs text-muted-foreground mt-2">
          Stake {(50000 - currentStake).toLocaleString()} more VTX to reach Diamond tier
        </p>
      </div>
    </div>
  )
}
