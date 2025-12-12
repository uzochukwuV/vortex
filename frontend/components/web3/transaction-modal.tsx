"use client"

import { useState, useEffect } from "react"
import { CheckCircle2, XCircle, Loader2, ExternalLink } from "lucide-react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

type TransactionStatus = "pending" | "confirming" | "success" | "error"

interface TransactionModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  status?: TransactionStatus
  title?: string
  description?: string
  txHash?: string
  error?: string
}

export function TransactionModal({
  open,
  onOpenChange,
  status = "pending",
  title = "Confirm Transaction",
  description = "Please confirm the transaction in your wallet.",
  txHash = "0x1234...5678",
  error,
}: TransactionModalProps) {
  const [currentStatus, setCurrentStatus] = useState<TransactionStatus>(status)

  // Simulate transaction flow for demo
  useEffect(() => {
    if (!open) return

    setCurrentStatus("pending")
    const timer1 = setTimeout(() => setCurrentStatus("confirming"), 2000)
    const timer2 = setTimeout(() => setCurrentStatus("success"), 5000)

    return () => {
      clearTimeout(timer1)
      clearTimeout(timer2)
    }
  }, [open])

  const statusConfig = {
    pending: {
      icon: Loader2,
      iconClass: "text-primary animate-spin",
      title: "Waiting for Confirmation",
      description: "Please confirm the transaction in your wallet.",
    },
    confirming: {
      icon: Loader2,
      iconClass: "text-amber-500 animate-spin",
      title: "Transaction Submitted",
      description: "Waiting for blockchain confirmation...",
    },
    success: {
      icon: CheckCircle2,
      iconClass: "text-green-500",
      title: "Transaction Successful",
      description: "Your transaction has been confirmed.",
    },
    error: {
      icon: XCircle,
      iconClass: "text-red-500",
      title: "Transaction Failed",
      description: error || "Something went wrong. Please try again.",
    },
  }

  const config = statusConfig[currentStatus]
  const Icon = config.icon

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-sm bg-card border-border">
        <DialogHeader>
          <DialogTitle className="sr-only">{config.title}</DialogTitle>
        </DialogHeader>

        <div className="flex flex-col items-center text-center py-6 space-y-4">
          <div
            className={`w-16 h-16 rounded-full ${currentStatus === "success" ? "bg-green-500/20" : currentStatus === "error" ? "bg-red-500/20" : "bg-primary/20"} flex items-center justify-center`}
          >
            <Icon className={`w-8 h-8 ${config.iconClass}`} />
          </div>

          <div className="space-y-2">
            <h3 className="text-lg font-semibold">{config.title}</h3>
            <p className="text-sm text-muted-foreground max-w-xs">{config.description}</p>
          </div>

          {(currentStatus === "confirming" || currentStatus === "success") && txHash && (
            <a
              href={`https://etherscan.io/tx/${txHash}`}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1 text-sm text-primary hover:text-primary/80"
            >
              View on Explorer
              <ExternalLink className="w-3 h-3" />
            </a>
          )}

          {currentStatus === "success" && (
            <Button className="w-full bg-primary text-primary-foreground" onClick={() => onOpenChange(false)}>
              Done
            </Button>
          )}

          {currentStatus === "error" && (
            <div className="flex gap-2 w-full">
              <Button variant="outline" className="flex-1 bg-transparent" onClick={() => onOpenChange(false)}>
                Cancel
              </Button>
              <Button className="flex-1 bg-primary text-primary-foreground">Try Again</Button>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
