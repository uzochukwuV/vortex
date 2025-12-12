"use client"

import { useMemo } from "react"
import { ArrowUpRight, ArrowDownRight } from "lucide-react"

function generateRecentTrades(count: number) {
  const trades = []
  const now = Date.now()

  for (let i = 0; i < count; i++) {
    const isBuy = Math.random() > 0.5
    trades.push({
      id: i,
      type: isBuy ? "buy" : "sell",
      price: 67432.5 + (Math.random() - 0.5) * 100,
      amount: Math.random() * 2 + 0.01,
      time: new Date(now - i * 30000).toLocaleTimeString(),
    })
  }
  return trades
}

export function RecentTrades() {
  const trades = useMemo(() => generateRecentTrades(20), [])

  return (
    <div className="bg-card border border-border rounded-xl overflow-hidden">
      <div className="p-4 border-b border-border">
        <h3 className="font-semibold">Recent Trades</h3>
      </div>

      <div className="grid grid-cols-3 px-4 py-2 text-xs text-muted-foreground border-b border-border">
        <span>Price (USD)</span>
        <span className="text-right">Amount (BTC)</span>
        <span className="text-right">Time</span>
      </div>

      <div className="max-h-96 overflow-y-auto">
        {trades.map((trade) => (
          <div
            key={trade.id}
            className="grid grid-cols-3 px-4 py-2 text-sm hover:bg-secondary/30 transition-colors items-center"
          >
            <span
              className={`font-mono flex items-center gap-1 ${trade.type === "buy" ? "text-green-500" : "text-red-500"}`}
            >
              {trade.type === "buy" ? <ArrowUpRight className="w-3 h-3" /> : <ArrowDownRight className="w-3 h-3" />}$
              {trade.price.toFixed(2)}
            </span>
            <span className="text-right font-mono">{trade.amount.toFixed(4)}</span>
            <span className="text-right text-muted-foreground">{trade.time}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
