"use client"

import { useState } from "react"
import { Search, Star, TrendingUp, TrendingDown } from "lucide-react"
import { Input } from "@/components/ui/input"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

const markets = [
  { symbol: "BTC-USD", name: "Bitcoin", price: 67432.5, change: 2.34, favorite: true },
  { symbol: "ETH-USD", name: "Ethereum", price: 3542.18, change: -1.23, favorite: true },
  { symbol: "SOL-USD", name: "Solana", price: 178.92, change: 5.67, favorite: false },
  { symbol: "AVAX-USD", name: "Avalanche", price: 42.15, change: 3.21, favorite: false },
  { symbol: "ARB-USD", name: "Arbitrum", price: 1.24, change: -0.89, favorite: false },
  { symbol: "LINK-USD", name: "Chainlink", price: 18.56, change: 1.45, favorite: false },
  { symbol: "MATIC-USD", name: "Polygon", price: 0.892, change: -2.15, favorite: false },
  { symbol: "OP-USD", name: "Optimism", price: 2.78, change: 4.32, favorite: false },
]

interface MarketSelectorProps {
  selectedMarket: string
  onSelectMarket: (market: string) => void
}

export function MarketSelector({ selectedMarket, onSelectMarket }: MarketSelectorProps) {
  const [search, setSearch] = useState("")
  const [open, setOpen] = useState(false)

  const currentMarket = markets.find((m) => m.symbol === selectedMarket) || markets[0]
  const filteredMarkets = markets.filter(
    (m) => m.symbol.toLowerCase().includes(search.toLowerCase()) || m.name.toLowerCase().includes(search.toLowerCase()),
  )

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="ghost" className="h-auto p-3 gap-3 hover:bg-secondary">
          <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
            <span className="text-primary font-bold text-sm">{currentMarket.symbol.split("-")[0].slice(0, 2)}</span>
          </div>
          <div className="text-left">
            <div className="font-semibold text-lg">{currentMarket.symbol}</div>
            <div className={`text-sm ${currentMarket.change >= 0 ? "text-green-500" : "text-red-500"}`}>
              ${currentMarket.price.toLocaleString()} ({currentMarket.change >= 0 ? "+" : ""}
              {currentMarket.change}%)
            </div>
          </div>
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md bg-card border-border">
        <DialogHeader>
          <DialogTitle>Select Market</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search markets..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-10 bg-secondary border-border"
            />
          </div>
          <div className="max-h-80 overflow-y-auto space-y-1">
            {filteredMarkets.map((market) => (
              <button
                key={market.symbol}
                onClick={() => {
                  onSelectMarket(market.symbol)
                  setOpen(false)
                }}
                className={`w-full flex items-center justify-between p-3 rounded-lg transition-colors ${
                  selectedMarket === market.symbol ? "bg-primary/20" : "hover:bg-secondary"
                }`}
              >
                <div className="flex items-center gap-3">
                  <Star
                    className={`w-4 h-4 ${market.favorite ? "text-primary fill-primary" : "text-muted-foreground"}`}
                  />
                  <div className="text-left">
                    <div className="font-medium">{market.symbol}</div>
                    <div className="text-sm text-muted-foreground">{market.name}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-mono">${market.price.toLocaleString()}</div>
                  <div
                    className={`text-sm flex items-center gap-1 justify-end ${market.change >= 0 ? "text-green-500" : "text-red-500"}`}
                  >
                    {market.change >= 0 ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                    {market.change >= 0 ? "+" : ""}
                    {market.change}%
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
