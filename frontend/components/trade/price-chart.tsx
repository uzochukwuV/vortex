"use client"

import { useEffect, useRef, useState } from "react"
import { usePriceData } from "@/hooks/usePriceData"

export function PriceChart({ asset = 'BTC' }: { asset?: string }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const containerRef = useRef<HTMLDivElement>(null)
  const [timeframe, setTimeframe] = useState("1D")
  const { candles, loading } = usePriceData(asset)

  useEffect(() => {
    console.log("Rendering chart with candles:", candles)
    const canvas = canvasRef.current
    const container = containerRef.current
    if (!canvas || !container || loading || candles.length === 0) return

    const ctx = canvas.getContext("2d")
    if (!ctx) return

    const data = candles

    // Set canvas size
    const rect = container.getBoundingClientRect()
    const dpr = window.devicePixelRatio || 1
    canvas.width = rect.width * dpr
    canvas.height = rect.height * dpr
    ctx.scale(dpr, dpr)
    canvas.style.width = `${rect.width}px`
    canvas.style.height = `${rect.height}px`

    const width = rect.width
    const height = rect.height

    // Clear canvas
    ctx.fillStyle = "#0a0a0a"
    ctx.fillRect(0, 0, width, height)

    // Calculate price range
    const prices = data.flatMap((d) => [d.high, d.low])
    if (prices.length === 0) return
    const minPrice = Math.min(...prices)
    const maxPrice = Math.max(...prices)
    const priceRange = maxPrice - minPrice
    const padding = 60

    // Draw grid
    ctx.strokeStyle = "#1a1a1a"
    ctx.lineWidth = 1

    // Horizontal grid lines
    for (let i = 0; i <= 5; i++) {
      const y = padding + ((height - padding * 2) * i) / 5
      ctx.beginPath()
      ctx.moveTo(padding, y)
      ctx.lineTo(width - padding, y)
      ctx.stroke()

      // Price labels
      const price = maxPrice - (priceRange * i) / 5
      ctx.fillStyle = "#737373"
      ctx.font = "12px Oxanium"
      ctx.textAlign = "right"
      ctx.fillText(`$${price.toFixed(0)}`, padding - 10, y + 4)
    }

    // Draw candlesticks
    const candleWidth = (width - padding * 2) / data.length
    const candleGap = candleWidth * 0.2
    const candleBodyWidth = candleWidth - candleGap

    data.forEach((candle, i) => {
      const x = padding + i * candleWidth + candleWidth / 2
      const isGreen = candle.close >= candle.open

      // Calculate Y positions
      const highY = padding + ((maxPrice - candle.high) / priceRange) * (height - padding * 2)
      const lowY = padding + ((maxPrice - candle.low) / priceRange) * (height - padding * 2)
      const openY = padding + ((maxPrice - candle.open) / priceRange) * (height - padding * 2)
      const closeY = padding + ((maxPrice - candle.close) / priceRange) * (height - padding * 2)

      // Wick
      ctx.strokeStyle = isGreen ? "#22c55e" : "#ef4444"
      ctx.lineWidth = 1
      ctx.beginPath()
      ctx.moveTo(x, highY)
      ctx.lineTo(x, lowY)
      ctx.stroke()

      // Body
      ctx.fillStyle = isGreen ? "#22c55e" : "#ef4444"
      const bodyTop = Math.min(openY, closeY)
      const bodyHeight = Math.abs(closeY - openY) || 1
      ctx.fillRect(x - candleBodyWidth / 2, bodyTop, candleBodyWidth, bodyHeight)
    })

    // Draw current price line
    const lastCandle = data[data.length - 1]
    const currentPriceY = padding + ((maxPrice - lastCandle.close) / priceRange) * (height - padding * 2)

    ctx.strokeStyle = "#f59e0b"
    ctx.lineWidth = 1
    ctx.setLineDash([5, 5])
    ctx.beginPath()
    ctx.moveTo(padding, currentPriceY)
    ctx.lineTo(width - padding, currentPriceY)
    ctx.stroke()
    ctx.setLineDash([])

    // Current price label
    ctx.fillStyle = "#f59e0b"
    ctx.fillRect(width - padding, currentPriceY - 10, 70, 20)
    ctx.fillStyle = "#0a0a0a"
    ctx.font = "bold 11px Oxanium"
    ctx.textAlign = "left"
    ctx.fillText(`$${lastCandle.close.toFixed(0)}`, width - padding + 5, currentPriceY + 4)
  }, [candles, loading, timeframe])

  const timeframes = ["1D", "7D", "14D", "30D", "90D"]

  return (
    <div className="h-full flex flex-col bg-card rounded-lg border border-border overflow-hidden">
      {/* Chart header */}
      <div className="flex items-center justify-between p-3 border-b border-border">
        <div className="flex items-center gap-2">
          {timeframes.map((tf) => (
            <button
              key={tf}
              onClick={() => setTimeframe(tf)}
              className={`px-3 py-1 text-xs font-medium rounded transition-colors ${
                timeframe === tf ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              {tf}
            </button>
          ))}
        </div>
        <div className="text-xs text-muted-foreground">
          {loading ? 'Loading...' : `${asset}/USD`}
        </div>
      </div>

      {/* Chart canvas */}
      <div ref={containerRef} className="flex-1 relative">
        <canvas ref={canvasRef} className="absolute inset-0" />
      </div>
    </div>
  )
}
