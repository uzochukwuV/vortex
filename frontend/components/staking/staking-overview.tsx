"use client"

import { Lock, TrendingUp, Coins, Award } from "lucide-react"

const stats = [
  {
    label: "Total Staked",
    value: "45.2M VTX",
    subValue: "$135.6M",
    icon: Lock,
    color: "text-primary",
  },
  {
    label: "Your Stake",
    value: "12,500 VTX",
    subValue: "$37,500",
    icon: Coins,
    color: "text-foreground",
  },
  {
    label: "Pending Rewards",
    value: "234.5 VTX",
    subValue: "$703.50",
    icon: TrendingUp,
    color: "text-green-500",
  },
  {
    label: "APR",
    value: "32.5%",
    subValue: "Variable",
    icon: Award,
    color: "text-amber-500",
  },
]

export function StakingOverview() {
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      {stats.map((stat, index) => (
        <div
          key={index}
          className="bg-card border border-border rounded-xl p-5 hover:border-primary/30 transition-colors"
        >
          <div className="flex items-center gap-2 mb-3">
            <stat.icon className={`w-5 h-5 ${stat.color}`} />
            <span className="text-sm text-muted-foreground">{stat.label}</span>
          </div>
          <div className={`text-2xl font-bold ${stat.color}`}>{stat.value}</div>
          <div className="text-sm text-muted-foreground mt-1">{stat.subValue}</div>
        </div>
      ))}
    </div>
  )
}
