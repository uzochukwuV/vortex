"use client"

import { useState } from "react"
import { X, TrendingUp, TrendingDown } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { usePositionEvents } from "@/hooks/usePositionEvents"
import { usePerpetualTrading } from "@/hooks/usePerpetualTrading"
import { usePriceData } from "@/hooks/usePriceData"
import { useAccount } from "wagmi"
import { formatUnits } from "viem"
import { toast } from "sonner"

export function PositionsPanel() {
  const [activeTab, setActiveTab] = useState("positions")
  const { address } = useAccount()
  const { openPositions } = usePositionEvents()
  const { closePosition, isPending } = usePerpetualTrading()
  const { priceData: btcPrice } = usePriceData('BTC')
  const { priceData: ethPrice } = usePriceData('ETH')

  // Filter user's positions
  const userPositions = openPositions.filter(p => p.trader.toLowerCase() === address?.toLowerCase())

  const handleClosePosition = async (positionId: bigint) => {
    try {
      toast.info('Closing position...')
      await closePosition(positionId)
      toast.success('Position closed successfully!')
    } catch (error: any) {
      toast.error(error.message || 'Failed to close position')
    }
  }

  const calculatePnL = (position: any) => {
    const currentPrice = position.asset === 'BTC' ? btcPrice?.price : ethPrice?.price
    if (!currentPrice) return { pnl: 0, pnlPercent: 0 }

    const entryPrice = parseFloat(formatUnits(position.entryPrice, 18))
    const size = parseFloat(formatUnits(position.size, 18))
    const priceDiff = currentPrice - entryPrice
    const pnl = position.isLong ? (size * priceDiff) / entryPrice : (size * -priceDiff) / entryPrice
    const collateral = parseFloat(formatUnits(position.collateral, 18))
    const pnlPercent = (pnl / collateral) * 100

    return { pnl, pnlPercent, currentPrice }
  }

  return (
    <div className="h-full flex flex-col bg-card rounded-lg border border-border overflow-hidden">
      <Tabs value={activeTab} onValueChange={setActiveTab} className="h-full flex flex-col">
        <div className="border-b border-border">
          <TabsList className="h-12 w-full justify-start rounded-none bg-transparent border-0 p-0">
            <TabsTrigger
              value="positions"
              className="h-12 px-4 rounded-none border-b-2 border-transparent data-[state=active]:border-primary data-[state=active]:bg-transparent"
            >
              Positions ({userPositions.length})
            </TabsTrigger>
            <TabsTrigger
              value="orders"
              className="h-12 px-4 rounded-none border-b-2 border-transparent data-[state=active]:border-primary data-[state=active]:bg-transparent"
            >
              Orders (0)
            </TabsTrigger>
            <TabsTrigger
              value="history"
              className="h-12 px-4 rounded-none border-b-2 border-transparent data-[state=active]:border-primary data-[state=active]:bg-transparent"
            >
              History
            </TabsTrigger>
          </TabsList>
        </div>

        <TabsContent value="positions" className="flex-1 m-0 overflow-auto">
          {!address ? (
            <div className="h-full flex items-center justify-center text-muted-foreground">Connect wallet to view positions</div>
          ) : userPositions.length === 0 ? (
            <div className="h-full flex items-center justify-center text-muted-foreground">No open positions</div>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-secondary/30">
                <tr className="text-xs text-muted-foreground">
                  <th className="text-left p-3 font-medium">Market</th>
                  <th className="text-left p-3 font-medium">Side</th>
                  <th className="text-right p-3 font-medium">Size</th>
                  <th className="text-right p-3 font-medium">Entry</th>
                  <th className="text-right p-3 font-medium">Mark</th>
                  <th className="text-right p-3 font-medium">PnL</th>
                  <th className="text-right p-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {userPositions.map((position) => {
                  const { pnl, pnlPercent, currentPrice } = calculatePnL(position)
                  const size = parseFloat(formatUnits(position.size, 18))
                  const entryPrice = parseFloat(formatUnits(position.entryPrice, 18))
                  const leverage = Number(position.leverage)

                  return (
                    <tr key={position.positionId.toString()} className="border-b border-border hover:bg-secondary/30">
                      <td className="p-3">
                        <div className="flex items-center gap-2">
                          <span className="font-medium">{position.asset}-USD</span>
                          <span className="text-xs px-1.5 py-0.5 bg-secondary rounded">{leverage}x</span>
                        </div>
                      </td>
                      <td className="p-3">
                        <span
                          className={`flex items-center gap-1 ${position.isLong ? "text-green-500" : "text-red-500"}`}
                        >
                          {position.isLong ? (
                            <TrendingUp className="w-3 h-3" />
                          ) : (
                            <TrendingDown className="w-3 h-3" />
                          )}
                          {position.isLong ? 'LONG' : 'SHORT'}
                        </span>
                      </td>
                      <td className="p-3 text-right font-mono">${size.toFixed(2)}</td>
                      <td className="p-3 text-right font-mono">${entryPrice.toFixed(2)}</td>
                      <td className="p-3 text-right font-mono">${currentPrice?.toFixed(2) || '-'}</td>
                      <td className="p-3 text-right">
                        <span className={pnl >= 0 ? "text-green-500" : "text-red-500"}>
                          <div className="font-mono">
                            {pnl >= 0 ? "+" : ""}${pnl.toFixed(2)}
                          </div>
                          <div className="text-xs">
                            ({pnlPercent >= 0 ? "+" : ""}
                            {pnlPercent.toFixed(2)}%)
                          </div>
                        </span>
                      </td>
                      <td className="p-3 text-right">
                        <Button
                          onClick={() => handleClosePosition(position.positionId)}
                          disabled={isPending}
                          variant="outline"
                          size="sm"
                          className="h-7 text-xs text-red-500 hover:text-red-400 bg-transparent"
                        >
                          {isPending ? 'Closing...' : 'Close'}
                        </Button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </TabsContent>

        <TabsContent value="orders" className="flex-1 m-0 overflow-auto">
          <div className="h-full flex items-center justify-center text-muted-foreground">
            Limit orders coming soon
          </div>
        </TabsContent>

        <TabsContent value="history" className="flex-1 m-0 overflow-auto">
          <div className="h-full flex items-center justify-center text-muted-foreground">
            Position history coming soon
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
