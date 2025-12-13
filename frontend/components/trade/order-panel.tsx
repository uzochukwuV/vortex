"use client"

import { useState } from "react"
import { Info, ChevronDown } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Slider } from "@/components/ui/slider"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { usePerpetualTrading } from "@/hooks/usePerpetualTrading"
import { useERC20 } from "@/hooks/useERC20"
import { useERC20Ethers } from "@/hooks/useERC20Ethers"
import { usePriceData } from "@/hooks/usePriceData"
import { useAccount } from "wagmi"
import { parseUnits } from "viem"
import { toast } from "sonner"
import { COLLATERAL_TOKEN_ADDRESS, PERPETUAL_TRADING_ADDRESS } from "@/lib/constants"
import { ClientOnly } from "@/components/client-only"

const COLLATERAL_DECIMALS = 6; // USDT has 6 decimals

export function OrderPanel({ asset = 'BTC' }: { asset?: string }) {
  const { address } = useAccount();
  const [orderType, setOrderType] = useState("market")
  const [leverage, setLeverage] = useState([10])
  const [amount, setAmount] = useState("")
  const [limitPrice, setLimitPrice] = useState("")
  const [stopLoss, setStopLoss] = useState("")
  const [takeProfit, setTakeProfit] = useState("")

  const leveragePresets = [2, 5, 10, 25, 50]

  return (
    <div className="h-full flex flex-col bg-card rounded-lg border border-border overflow-hidden">
      {/* Header */}
      <div className="p-4 border-b border-border">
        <Tabs defaultValue="long" className="w-full">
          <TabsList className="w-full grid grid-cols-2 bg-secondary">
            <TabsTrigger
              value="long"
              className="data-[state=active]:bg-green-500/20 data-[state=active]:text-green-500"
            >
              Long
            </TabsTrigger>
            <TabsTrigger value="short" className="data-[state=active]:bg-red-500/20 data-[state=active]:text-red-500">
              Short
            </TabsTrigger>
          </TabsList>

          <TabsContent value="long" className="mt-4 space-y-4">
            <ClientOnly>
              <OrderForm
                side="long"
                asset={asset}
                orderType={orderType}
                setOrderType={setOrderType}
                leverage={leverage}
                setLeverage={setLeverage}
                amount={amount}
                setAmount={setAmount}
                limitPrice={limitPrice}
                setLimitPrice={setLimitPrice}
                stopLoss={stopLoss}
                setStopLoss={setStopLoss}
                takeProfit={takeProfit}
                setTakeProfit={setTakeProfit}
                leveragePresets={leveragePresets}
                userAddress={address}
              />
            </ClientOnly>
          </TabsContent>

          <TabsContent value="short" className="mt-4 space-y-4">
            <ClientOnly>
              <OrderForm
                side="short"
                asset={asset}
                orderType={orderType}
                setOrderType={setOrderType}
                leverage={leverage}
                setLeverage={setLeverage}
                amount={amount}
                setAmount={setAmount}
                limitPrice={limitPrice}
                setLimitPrice={setLimitPrice}
                stopLoss={stopLoss}
                setStopLoss={setStopLoss}
                takeProfit={takeProfit}
                setTakeProfit={setTakeProfit}
                leveragePresets={leveragePresets}
                userAddress={address}
              />
            </ClientOnly>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}

function OrderForm({
  side,
  asset,
  orderType,
  setOrderType,
  leverage,
  setLeverage,
  amount,
  setAmount,
  limitPrice,
  setLimitPrice,
  stopLoss,
  setStopLoss,
  takeProfit,
  setTakeProfit,
  leveragePresets,
  userAddress,
}: {
  side: "long" | "short"
  asset?: string
  orderType: string
  setOrderType: (type: string) => void
  leverage: number[]
  setLeverage: (value: number[]) => void
  amount: string
  setAmount: (value: string) => void
  limitPrice: string
  setLimitPrice: (value: string) => void
  stopLoss: string
  setStopLoss: (value: string) => void
  takeProfit: string
  setTakeProfit: (value: string) => void
  leveragePresets: number[]
  userAddress?: `0x${string}`
}) {
  const isLong = side === "long"
  const { openPosition, isPending, isSuccess } = usePerpetualTrading()
  const collateralToken = useERC20(COLLATERAL_TOKEN_ADDRESS, COLLATERAL_DECIMALS)
  const ethersToken = useERC20Ethers(COLLATERAL_TOKEN_ADDRESS, COLLATERAL_DECIMALS)
  const { priceData } = usePriceData(asset || 'BTC')

  const { data: balance, refetch: refetchBalance } = collateralToken.useBalance(userAddress)
  const { data: allowance, refetch: refetchAllowance } = collateralToken.useAllowance(userAddress, PERPETUAL_TRADING_ADDRESS)
  const handleOpenPosition = async () => {
    if (!userAddress) {
      toast.error('Please connect your wallet')
      return
    }

    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Please enter a valid amount')
      return
    }

    const leverageValue = leverage[0]
    const amountNum = parseFloat(amount)

    // Check balance
    const balanceNum = balance ? Number(balance) / 1e6 : 0
    if (amountNum > balanceNum) {
      toast.error(`Insufficient balance. You have ${balanceNum.toFixed(2)} USDT`)
      return
    }

    try {
      const requiredAmount = parseUnits(amount, COLLATERAL_DECIMALS)
      const feeAmount = parseUnits((amountNum * leverageValue * 0.001).toString(), COLLATERAL_DECIMALS) // 0.1% fee
      const totalRequired = requiredAmount + feeAmount

      // Step 1: Check and handle approval
      const currentAllowance = allowance || BigInt(0)

      if (currentAllowance < totalRequired) {
        toast.info('Step 1/2: Approving USDT...')
        console.log('Approving USDT for:', PERPETUAL_TRADING_ADDRESS)

        // Approve max amount to avoid future approvals
        await collateralToken.approve(
          PERPETUAL_TRADING_ADDRESS,
          '1000000000' // Approve 1B USDT
        )

        toast.loading('Waiting for approval confirmation...')
        // Wait for approval to be mined
        await new Promise(resolve => setTimeout(resolve, 3000))
        await refetchAllowance()

        toast.success('✓ USDT approved successfully!')
        await new Promise(resolve => setTimeout(resolve, 1000))
      }

      // Step 2: Open position
      toast.info(`Step 2/2: Opening ${isLong ? 'LONG' : 'SHORT'} position...`)
      console.log('Opening position:', { asset, isLong, amount, leverage: leverageValue })

      await openPosition(asset || 'BTC', isLong, amount, leverageValue)

      // Wait for transaction confirmation
      toast.loading('Waiting for transaction confirmation...')
      await new Promise(resolve => setTimeout(resolve, 3000))

      toast.success(`✓ ${isLong ? 'Long' : 'Short'} position opened successfully!`)

      // Refresh balances
      await refetchBalance()
      setAmount('')

    } catch (error: any) {
      console.error('Error opening position:', error)

      // Better error messages
      if (error.message?.includes('user rejected')) {
        toast.error('Transaction cancelled by user')
      } else if (error.message?.includes('insufficient funds')) {
        toast.error('Insufficient funds for gas fees')
      } else if (error.message?.includes('execution reverted')) {
        toast.error('Transaction failed - Check contract requirements')
      } else {
        toast.error(error.shortMessage || error.message || 'Failed to open position')
      }
    }
  }

  const entryPrice = priceData?.price || 0
  const positionSize = parseFloat(amount || '0') * leverage[0]
  const liquidationPrice = isLong 
    ? entryPrice * (1 - 0.8 / leverage[0])
    : entryPrice * (1 + 0.8 / leverage[0])
  const fee = positionSize * 0.001 // 0.1% fee

  return (
    <div className="space-y-4">
      {/* Order type selector */}
      <div className="flex items-center gap-2">
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" size="sm" className="gap-2 capitalize bg-secondary border-border">
              {orderType}
              <ChevronDown className="w-4 h-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent>
            <DropdownMenuItem onClick={() => setOrderType("market")}>Market</DropdownMenuItem>
            <DropdownMenuItem onClick={() => setOrderType("limit")}>Limit</DropdownMenuItem>
            <DropdownMenuItem onClick={() => setOrderType("stop")}>Stop</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {/* Leverage slider */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-sm text-muted-foreground">Leverage</span>
          <span className="text-sm font-mono font-semibold">{leverage[0]}x</span>
        </div>
        <Slider value={leverage} onValueChange={setLeverage} min={1} max={50} step={1} className="w-full" />
        <div className="flex gap-2">
          {leveragePresets.map((preset) => (
            <button
              key={preset}
              onClick={() => setLeverage([preset])}
              className={`flex-1 py-1 text-xs rounded border transition-colors ${
                leverage[0] === preset
                  ? "bg-primary/20 border-primary text-primary"
                  : "border-border text-muted-foreground hover:border-muted-foreground"
              }`}
            >
              {preset}x
            </button>
          ))}
        </div>
      </div>

      {/* USDT Balance Display */}
      <div className="p-3 bg-secondary/50 rounded-lg border border-border">
        <div className="flex items-center justify-between mb-2">
          <span className="text-xs text-muted-foreground">Available Balance</span>
          <button
            onClick={async () => {
              if (!userAddress) return;
              try {
                toast.info('Minting USDT...');
                await collateralToken.mint(userAddress, '10000'); // Mint 10,000 USDT for testing
                toast.success('Minted 10,000 USDT for testing!');
                // Refetch balance after minting
                await new Promise(resolve => setTimeout(resolve, 2000));
                await refetchBalance();
              } catch (error: any) {
                console.error('Mint error:', error);
                toast.error(error.message || 'Failed to mint USDT');
              }
            }}
            className="text-xs px-2 py-1 rounded bg-primary/20 text-primary hover:bg-primary/30 transition-colors"
            disabled={!userAddress || ethersToken.isPending}
          >
            <ClientOnly>
              {ethersToken.isPending ? 'Minting...' : 'Mint Test USDT'}
            </ClientOnly>
          </button>
        </div>
        <div className="flex items-baseline gap-2">
          <span className="text-2xl font-bold font-mono">
            {balance ? (Number(balance) / 1e6).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00'}
          </span>
          <span className="text-sm text-muted-foreground">USDT</span>
        </div>
      </div>

      {/* Amount input */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-sm text-muted-foreground">Collateral Amount</span>
        </div>
        <div className="relative">
          <Input
            type="number"
            placeholder="0.00"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="bg-secondary border-border pr-16"
          />
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">USDT</span>
        </div>
        <div className="flex gap-2">
          {[25, 50, 75, 100].map((pct) => (
            <button
              key={pct}
              onClick={() => {
                const bal = balance ? Number(balance) / 1e6 : 0
                setAmount(((bal * pct) / 100).toFixed(2))
              }}
              className="flex-1 py-1 text-xs rounded border border-border text-muted-foreground hover:border-muted-foreground transition-colors"
            >
              {pct}%
            </button>
          ))}
        </div>
      </div>

      {/* Limit price (for limit orders) */}
      {orderType === "limit" && (
        <div className="space-y-2">
          <span className="text-sm text-muted-foreground">Limit Price</span>
          <div className="relative">
            <Input
              type="number"
              placeholder="0.00"
              value={limitPrice}
              onChange={(e) => setLimitPrice(e.target.value)}
              className="bg-secondary border-border pr-16"
            />
            <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">USD</span>
          </div>
        </div>
      )}

      {/* TP/SL */}
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          <span className="text-sm text-muted-foreground flex items-center gap-1">
            Take Profit
            <Info className="w-3 h-3" />
          </span>
          <Input
            type="number"
            placeholder="0.00"
            value={takeProfit}
            onChange={(e) => setTakeProfit(e.target.value)}
            className="bg-secondary border-border"
          />
        </div>
        <div className="space-y-2">
          <span className="text-sm text-muted-foreground flex items-center gap-1">
            Stop Loss
            <Info className="w-3 h-3" />
          </span>
          <Input
            type="number"
            placeholder="0.00"
            value={stopLoss}
            onChange={(e) => setStopLoss(e.target.value)}
            className="bg-secondary border-border"
          />
        </div>
      </div>

      {/* Order summary */}
      <div className="p-3 bg-secondary/50 rounded-lg space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-muted-foreground">Entry Price</span>
          <span className="font-mono">${entryPrice.toFixed(2)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Position Size</span>
          <span className="font-mono">${positionSize.toFixed(2)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Liquidation Price</span>
          <span className="font-mono text-red-500">${liquidationPrice.toFixed(2)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Fee (0.1%)</span>
          <span className="font-mono">~${fee.toFixed(2)}</span>
        </div>
      </div>

      {/* Submit button */}
      <Button
        onClick={handleOpenPosition}
        disabled={!userAddress || isPending || !amount}
        className={`w-full py-6 text-lg font-semibold ${
          isLong ? "bg-green-600 hover:bg-green-700 text-white" : "bg-red-600 hover:bg-red-700 text-white"
        }`}
      >
        <ClientOnly>
          {!userAddress ? 'Connect Wallet' : isPending ? 'Opening...' : `${isLong ? "Long" : "Short"} ${asset}-USD`}
        </ClientOnly>
      </Button>
    </div>
  )
}
