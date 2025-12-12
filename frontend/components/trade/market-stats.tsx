"use client"

import { TrendingUp, TrendingDown, Activity, DollarSign } from "lucide-react"
import { usePriceData } from "@/hooks/usePriceData"
import { useOrderBook } from "@/hooks/useOrderBook"

const COINGECKO_API_KEY = 'CG-R58brJSKYcxGS2pMEYAVftBG';

function formatNumber(num: number): string {
  if (num >= 1e9) return `$${(num / 1e9).toFixed(2)}B`;
  if (num >= 1e6) return `$${(num / 1e6).toFixed(2)}M`;
  if (num >= 1e3) return `$${(num / 1e3).toFixed(2)}K`;
  return `$${num.toFixed(2)}`;
}

export function MarketStats({ asset = 'BTC' }: { asset?: string }) {
  const { priceData } = usePriceData(asset);
  const { longOI, shortOI } = useOrderBook(asset);
  if (!priceData) {
    return (
      <div className="flex items-center gap-6 px-4 py-3 bg-card border-b border-border">
        <span className="text-sm text-muted-foreground">Loading market data...</span>
      </div>
    );
  }

  const change24h = priceData.change24h;
  const isPositive = change24h >= 0;
  const totalOI = longOI + shortOI;

  return (
    <div className="flex items-center gap-6 px-4 py-3 bg-card border-b border-border overflow-x-auto">
      {/* 24h Change */}
      <div className="flex flex-col min-w-max">
        <span className="text-xs text-muted-foreground">24h Change</span>
        <div className="flex items-center gap-1">
          <span className={`font-mono font-medium ${isPositive ? 'text-green-500' : 'text-red-500'}`}>
            {isPositive ? '+' : ''}{change24h.toFixed(2)}%
          </span>
        </div>
      </div>
      <div className="w-px h-8 bg-border" />

      {/* 24h High */}
      <div className="flex flex-col min-w-max">
        <span className="text-xs text-muted-foreground">24h High</span>
        <span className="font-mono font-medium text-green-500">
          ${priceData.high24h.toFixed(2)}
        </span>
      </div>
      <div className="w-px h-8 bg-border" />

      {/* 24h Low */}
      <div className="flex flex-col min-w-max">
        <span className="text-xs text-muted-foreground">24h Low</span>
        <span className="font-mono font-medium text-red-500">
          ${priceData.low24h.toFixed(2)}
        </span>
      </div>
      <div className="w-px h-8 bg-border" />

      {/* 24h Volume */}
      <div className="flex flex-col min-w-max">
        <span className="text-xs text-muted-foreground">24h Volume</span>
        <span className="font-mono font-medium text-foreground">
          {formatNumber(priceData.volume24h)}
        </span>
      </div>
      <div className="w-px h-8 bg-border" />

      {/* Open Interest */}
      <div className="flex flex-col min-w-max">
        <span className="text-xs text-muted-foreground">Open Interest</span>
        <span className="font-mono font-medium text-foreground">
          {formatNumber(totalOI)}
        </span>
      </div>
      <div className="w-px h-8 bg-border" />

      {/* Long/Short Ratio */}
      <div className="flex flex-col min-w-max">
        <span className="text-xs text-muted-foreground">Long/Short</span>
        <div className="flex items-center gap-1">
          <span className="font-mono font-medium text-green-500">
            {totalOI > 0 ? ((longOI / totalOI) * 100).toFixed(0) : 50}%
          </span>
          <span className="text-muted-foreground">/</span>
          <span className="font-mono font-medium text-red-500">
            {totalOI > 0 ? ((shortOI / totalOI) * 100).toFixed(0) : 50}%
          </span>
        </div>
      </div>
    </div>
  )
}
