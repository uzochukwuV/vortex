"use client"

const balances = [
  { symbol: "ETH", name: "Ethereum", balance: 2.5, value: 8855.45, change: 2.34 },
  { symbol: "BTC", name: "Bitcoin", balance: 0.15, value: 10114.88, change: 1.23 },
  { symbol: "USDC", name: "USD Coin", balance: 10000, value: 10000, change: 0 },
  { symbol: "SOL", name: "Solana", balance: 25, value: 4473, change: 5.67 },
  { symbol: "AVAX", name: "Avalanche", balance: 50, value: 2107.5, change: 3.21 },
]

export function TokenBalances() {
  const totalValue = balances.reduce((sum, b) => sum + b.value, 0)

  return (
    <div className="bg-card border border-border rounded-xl overflow-hidden">
      <div className="p-4 border-b border-border">
        <div className="flex items-center justify-between">
          <h3 className="font-semibold">Your Balances</h3>
          <span className="text-sm text-muted-foreground">Total: ${totalValue.toLocaleString()}</span>
        </div>
      </div>

      <div className="divide-y divide-border">
        {balances.map((token) => (
          <div
            key={token.symbol}
            className="p-4 flex items-center justify-between hover:bg-secondary/30 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                <span className="text-primary font-bold text-sm">{token.symbol.slice(0, 2)}</span>
              </div>
              <div>
                <div className="font-medium">{token.symbol}</div>
                <div className="text-sm text-muted-foreground">{token.name}</div>
              </div>
            </div>
            <div className="text-right">
              <div className="font-mono">{token.balance.toLocaleString()}</div>
              <div className="text-sm">
                <span className="text-muted-foreground">${token.value.toLocaleString()}</span>
                {token.change !== 0 && (
                  <span className={`ml-2 ${token.change >= 0 ? "text-green-500" : "text-red-500"}`}>
                    {token.change >= 0 ? "+" : ""}
                    {token.change}%
                  </span>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
