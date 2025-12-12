"use client"

import { Wallet, TrendingUp, Droplets, Percent } from "lucide-react"

const stats = [
  {
    label: "Total Value Locked",
    value: "$89.2M",
    change: "+5.2%",
    positive: true,
    icon: Wallet,
  },
  {
    label: "Your Liquidity",
    value: "$12,450",
    change: "+$234.50",
    positive: true,
    icon: Droplets,
  },
  {
    label: "Total Earnings",
    value: "$1,892.50",
    change: "All time",
    icon: TrendingUp,
  },
  {
    label: "Average APR",
    value: "24.5%",
    change: "Across pools",
    icon: Percent,
  },
]

export function LiquidityStats() {
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      {stats.map((stat, index) => (
        <div key={index} className="bg-card border border-border rounded-xl p-5">
          <div className="flex items-center justify-between mb-3">
            <stat.icon className="w-5 h-5 text-primary" />
            {stat.positive !== undefined && (
              <span className={`text-xs ${stat.positive ? "text-green-500" : "text-red-500"}`}>{stat.change}</span>
            )}
          </div>
          <div className="text-2xl font-bold mb-1">{stat.value}</div>
          <div className="text-sm text-muted-foreground">{stat.label}</div>
        </div>
      ))}
    </div>
  )
}
