"use client"

import { useState } from "react"
import { ArrowDown, Settings, RefreshCw, Info, Fuel } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { TokenSelector } from "@/components/spot/token-selector"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"

const tokenPrices: Record<string, number> = {
  ETH: 3542.18,
  BTC: 67432.5,
  USDC: 1.0,
  USDT: 1.0,
  SOL: 178.92,
  AVAX: 42.15,
  ARB: 1.24,
  LINK: 18.56,
  UNI: 12.34,
  AAVE: 156.78,
}

export function SwapCard() {
  const [fromToken, setFromToken] = useState("ETH")
  const [toToken, setToToken] = useState("USDC")
  const [fromAmount, setFromAmount] = useState("")
  const [slippage, setSlippage] = useState("0.5")

  const fromPrice = tokenPrices[fromToken] || 1
  const toPrice = tokenPrices[toToken] || 1
  const exchangeRate = fromPrice / toPrice
  const toAmount = fromAmount ? (Number.parseFloat(fromAmount) * exchangeRate).toFixed(6) : ""

  const handleSwapTokens = () => {
    const tempToken = fromToken
    setFromToken(toToken)
    setToToken(tempToken)
    setFromAmount("")
  }

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-card border border-border rounded-2xl p-6 space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-xl font-semibold">Swap</h2>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon" className="w-8 h-8">
              <RefreshCw className="w-4 h-4" />
            </Button>
            <Popover>
              <PopoverTrigger asChild>
                <Button variant="ghost" size="icon" className="w-8 h-8">
                  <Settings className="w-4 h-4" />
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-72 bg-card border-border" align="end">
                <div className="space-y-4">
                  <h4 className="font-medium">Transaction Settings</h4>
                  <div className="space-y-2">
                    <label className="text-sm text-muted-foreground">Slippage Tolerance</label>
                    <div className="flex gap-2">
                      {["0.1", "0.5", "1.0"].map((val) => (
                        <button
                          key={val}
                          onClick={() => setSlippage(val)}
                          className={`flex-1 py-2 text-sm rounded-lg border transition-colors ${
                            slippage === val
                              ? "bg-primary/20 border-primary text-primary"
                              : "border-border hover:border-muted-foreground"
                          }`}
                        >
                          {val}%
                        </button>
                      ))}
                      <div className="relative flex-1">
                        <Input
                          type="number"
                          value={slippage}
                          onChange={(e) => setSlippage(e.target.value)}
                          className="h-full text-center bg-secondary border-border pr-6"
                        />
                        <span className="absolute right-2 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                          %
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </PopoverContent>
            </Popover>
          </div>
        </div>

        {/* From token */}
        <div className="bg-secondary/50 rounded-xl p-4 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">You Pay</span>
            <span className="text-sm text-muted-foreground">Balance: 2.5 ETH</span>
          </div>
          <div className="flex items-center gap-3">
            <Input
              type="number"
              placeholder="0.0"
              value={fromAmount}
              onChange={(e) => setFromAmount(e.target.value)}
              className="flex-1 text-3xl font-medium bg-transparent border-0 p-0 focus-visible:ring-0 h-auto"
            />
            <TokenSelector selectedToken={fromToken} onSelectToken={setFromToken} excludeToken={toToken} />
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">
              ${fromAmount ? (Number.parseFloat(fromAmount) * fromPrice).toLocaleString() : "0.00"}
            </span>
            <div className="flex gap-2">
              {[25, 50, 75, 100].map((pct) => (
                <button
                  key={pct}
                  onClick={() => setFromAmount(((2.5 * pct) / 100).toString())}
                  className="px-2 py-0.5 text-xs rounded border border-border text-muted-foreground hover:border-muted-foreground transition-colors"
                >
                  {pct === 100 ? "MAX" : `${pct}%`}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Swap button */}
        <div className="flex justify-center -my-2 relative z-10">
          <button
            onClick={handleSwapTokens}
            className="w-10 h-10 bg-card border border-border rounded-xl flex items-center justify-center hover:bg-secondary transition-colors"
          >
            <ArrowDown className="w-5 h-5" />
          </button>
        </div>

        {/* To token */}
        <div className="bg-secondary/50 rounded-xl p-4 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">You Receive</span>
            <span className="text-sm text-muted-foreground">Balance: 10,000 USDC</span>
          </div>
          <div className="flex items-center gap-3">
            <Input
              type="number"
              placeholder="0.0"
              value={toAmount}
              readOnly
              className="flex-1 text-3xl font-medium bg-transparent border-0 p-0 focus-visible:ring-0 h-auto"
            />
            <TokenSelector selectedToken={toToken} onSelectToken={setToToken} excludeToken={fromToken} />
          </div>
          <span className="text-sm text-muted-foreground">
            ${toAmount ? (Number.parseFloat(toAmount) * toPrice).toLocaleString() : "0.00"}
          </span>
        </div>

        {/* Exchange rate info */}
        {fromAmount && (
          <div className="bg-secondary/30 rounded-xl p-4 space-y-3 text-sm">
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground flex items-center gap-1">
                Rate
                <Info className="w-3 h-3" />
              </span>
              <span className="font-mono">
                1 {fromToken} = {exchangeRate.toFixed(4)} {toToken}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">Price Impact</span>
              <span className="text-green-500">{"<0.01%"}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">Minimum Received</span>
              <span className="font-mono">
                {(Number.parseFloat(toAmount) * (1 - Number.parseFloat(slippage) / 100)).toFixed(4)} {toToken}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground flex items-center gap-1">
                <Fuel className="w-3 h-3" />
                Network Fee
              </span>
              <span className="font-mono">~$2.50</span>
            </div>
          </div>
        )}

        {/* Swap button */}
        <Button className="w-full py-6 text-lg font-semibold bg-primary text-primary-foreground hover:bg-primary/90">
          {!fromAmount ? "Enter Amount" : "Connect Wallet to Swap"}
        </Button>
      </div>
    </div>
  )
}
