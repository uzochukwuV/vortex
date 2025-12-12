"use client"

import { useState } from "react"
import { AppHeader } from "@/components/app/app-header"
import { MarketSelector } from "@/components/trade/market-selector"
import { MarketStats } from "@/components/trade/market-stats"
import { PriceChart } from "@/components/trade/price-chart"
import { OrderPanel } from "@/components/trade/order-panel"
import { OrderBook } from "@/components/trade/order-book"
import { PositionsPanel } from "@/components/trade/positions-panel"

export function TradePage() {
  const [selectedMarket, setSelectedMarket] = useState("BTC-USD")

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <AppHeader />

      {/* Market selector bar */}
      <div className="border-b border-border bg-card/30">
        <div className="px-4 py-2 flex items-center">
          <MarketSelector selectedMarket={selectedMarket} onSelectMarket={setSelectedMarket} />
        </div>
        <MarketStats />
      </div>

      {/* Main trading interface */}
      <div className="flex-1 p-4 grid grid-cols-12 gap-4 min-h-0">
        {/* Chart area */}
        <div className="col-span-12 lg:col-span-6 xl:col-span-7 min-h-[400px]">
          <PriceChart />
        </div>

        {/* Order book */}
        <div className="col-span-12 md:col-span-6 lg:col-span-3 xl:col-span-2 min-h-[400px]">
          <OrderBook />
        </div>

        {/* Order panel */}
        <div className="col-span-12 md:col-span-6 lg:col-span-3 min-h-[400px]">
          <OrderPanel />
        </div>

        {/* Positions panel - full width */}
        <div className="col-span-12 h-64">
          <PositionsPanel />
        </div>
      </div>
    </div>
  )
}
