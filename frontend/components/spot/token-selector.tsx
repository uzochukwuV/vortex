"use client"

import { useState } from "react"
import { Search, ChevronDown } from "lucide-react"
import { Input } from "@/components/ui/input"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

const tokens = [
  { symbol: "ETH", name: "Ethereum", balance: 2.5, price: 3542.18, icon: "E" },
  { symbol: "BTC", name: "Bitcoin", balance: 0.15, price: 67432.5, icon: "B" },
  { symbol: "USDC", name: "USD Coin", balance: 10000, price: 1.0, icon: "U" },
  { symbol: "USDT", name: "Tether", balance: 5000, price: 1.0, icon: "T" },
  { symbol: "SOL", name: "Solana", balance: 25, price: 178.92, icon: "S" },
  { symbol: "AVAX", name: "Avalanche", balance: 50, price: 42.15, icon: "A" },
  { symbol: "ARB", name: "Arbitrum", balance: 500, price: 1.24, icon: "A" },
  { symbol: "LINK", name: "Chainlink", balance: 100, price: 18.56, icon: "L" },
  { symbol: "UNI", name: "Uniswap", balance: 200, price: 12.34, icon: "U" },
  { symbol: "AAVE", name: "Aave", balance: 10, price: 156.78, icon: "A" },
]

interface TokenSelectorProps {
  selectedToken: string
  onSelectToken: (token: string) => void
  label?: string
  excludeToken?: string
}

export function TokenSelector({ selectedToken, onSelectToken, label, excludeToken }: TokenSelectorProps) {
  const [search, setSearch] = useState("")
  const [open, setOpen] = useState(false)

  const currentToken = tokens.find((t) => t.symbol === selectedToken) || tokens[0]
  const filteredTokens = tokens.filter(
    (t) =>
      t.symbol !== excludeToken &&
      (t.symbol.toLowerCase().includes(search.toLowerCase()) || t.name.toLowerCase().includes(search.toLowerCase())),
  )

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button
          variant="ghost"
          className="h-auto px-3 py-2 gap-2 bg-secondary hover:bg-secondary/80 rounded-full border-0"
        >
          <div className="w-7 h-7 bg-primary/20 rounded-full flex items-center justify-center">
            <span className="text-primary font-bold text-xs">{currentToken.icon}</span>
          </div>
          <span className="font-semibold">{currentToken.symbol}</span>
          <ChevronDown className="w-4 h-4 text-muted-foreground" />
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md bg-card border-border">
        <DialogHeader>
          <DialogTitle>{label || "Select Token"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search by name or symbol..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-10 bg-secondary border-border"
            />
          </div>

          {/* Popular tokens */}
          <div className="flex flex-wrap gap-2">
            {["ETH", "BTC", "USDC", "SOL"].map((symbol) => (
              <button
                key={symbol}
                onClick={() => {
                  if (symbol !== excludeToken) {
                    onSelectToken(symbol)
                    setOpen(false)
                  }
                }}
                disabled={symbol === excludeToken}
                className={`px-3 py-1.5 rounded-full text-sm border transition-colors ${
                  selectedToken === symbol
                    ? "bg-primary/20 border-primary text-primary"
                    : symbol === excludeToken
                      ? "opacity-40 cursor-not-allowed border-border"
                      : "border-border hover:border-muted-foreground"
                }`}
              >
                {symbol}
              </button>
            ))}
          </div>

          <div className="max-h-80 overflow-y-auto space-y-1">
            {filteredTokens.map((token) => (
              <button
                key={token.symbol}
                onClick={() => {
                  onSelectToken(token.symbol)
                  setOpen(false)
                }}
                className={`w-full flex items-center justify-between p-3 rounded-lg transition-colors ${
                  selectedToken === token.symbol ? "bg-primary/20" : "hover:bg-secondary"
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                    <span className="text-primary font-bold">{token.icon}</span>
                  </div>
                  <div className="text-left">
                    <div className="font-medium">{token.symbol}</div>
                    <div className="text-sm text-muted-foreground">{token.name}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-mono">
                    {token.balance.toLocaleString()} {token.symbol}
                  </div>
                  <div className="text-sm text-muted-foreground">${(token.balance * token.price).toLocaleString()}</div>
                </div>
              </button>
            ))}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
