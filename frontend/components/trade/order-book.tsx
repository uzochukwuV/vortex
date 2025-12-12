"use client"

import { useOrderBook } from "@/hooks/useOrderBook"
import { usePriceData } from "@/hooks/usePriceData"

export function OrderBook() {
  const { longOI, shortOI } = useOrderBook('BTC')
  const { priceData } = usePriceData('BTCUSDT')
  console.log('OrderBook render:', { longOI, shortOI, priceData })
  const currentPrice = priceData?.price || 67432.5
  const maxOI = Math.max(longOI, shortOI)

  return (
    <div className="h-full flex flex-col bg-card rounded-lg border border-border overflow-hidden">
      {/* Header */}
      <div className="p-3 border-b border-border flex items-center justify-between">
        <span className="text-sm font-medium">Order Book</span>
        <div className="flex items-center gap-2">
          <button className="w-6 h-6 rounded border border-border flex items-center justify-center hover:bg-secondary">
            <div className="w-3 h-3 flex flex-col gap-0.5">
              <div className="h-1 w-full bg-red-500" />
              <div className="h-1 w-full bg-green-500" />
            </div>
          </button>
        </div>
      </div>

      {/* Column headers */}
      <div className="grid grid-cols-2 px-3 py-2 text-xs text-muted-foreground border-b border-border">
        <span>Side</span>
        <span className="text-right">Open Interest</span>
      </div>

      {/* Open Interest Display */}
      <div className="flex-1 overflow-y-auto p-3 space-y-3">
        {/* Shorts (like asks) */}
        <div className="space-y-2">
          <div className="text-xs font-medium text-red-500">Short Positions</div>
          <div className="relative">
            <div className="absolute inset-0 bg-red-500/10 rounded" style={{ width: `${maxOI > 0 ? (shortOI / maxOI) * 100 : 0}%` }} />
            <div className="relative px-3 py-2 rounded border border-red-500/20">
              <div className="text-sm font-mono">${shortOI.toFixed(2)}</div>
              <div className="text-xs text-muted-foreground">Total Short OI</div>
            </div>
          </div>
        </div>

        {/* Current Price */}
        <div className="px-3 py-2 bg-secondary/30 text-center rounded border border-border">
          <div className="text-lg font-semibold font-mono">${currentPrice.toFixed(2)}</div>
          <div className="text-xs text-muted-foreground">Mark Price</div>
        </div>

        {/* Longs (like bids) */}
        <div className="space-y-2">
          <div className="text-xs font-medium text-green-500">Long Positions</div>
          <div className="relative">
            <div className="absolute inset-0 bg-green-500/10 rounded" style={{ width: `${maxOI > 0 ? (longOI / maxOI) * 100 : 0}%` }} />
            <div className="relative px-3 py-2 rounded border border-green-500/20">
              <div className="text-sm font-mono">${longOI.toFixed(2)}</div>
              <div className="text-xs text-muted-foreground">Total Long OI</div>
            </div>
          </div>
        </div>

        {/* OI Ratio */}
        <div className="pt-3 border-t border-border">
          <div className="text-xs text-muted-foreground mb-2">Long/Short Ratio</div>
          <div className="flex gap-1 h-2 rounded overflow-hidden">
            <div className="bg-green-500" style={{ width: `${longOI + shortOI > 0 ? (longOI / (longOI + shortOI)) * 100 : 50}%` }} />
            <div className="bg-red-500" style={{ width: `${longOI + shortOI > 0 ? (shortOI / (longOI + shortOI)) * 100 : 50}%` }} />
          </div>
          <div className="flex justify-between text-xs mt-1">
            <span className="text-green-500">{longOI + shortOI > 0 ? ((longOI / (longOI + shortOI)) * 100).toFixed(1) : 50}%</span>
            <span className="text-red-500">{longOI + shortOI > 0 ? ((shortOI / (longOI + shortOI)) * 100).toFixed(1) : 50}%</span>
          </div>
        </div>
      </div>
    </div>
  )
}
