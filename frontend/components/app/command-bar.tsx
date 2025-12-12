"use client"

import { useState, useEffect } from "react"
import { useRouter, usePathname } from "next/navigation"
import { TrendingUp, ArrowLeftRight, Droplets, Lock, Home, Search, Command, X } from "lucide-react"
import { Dialog, DialogContent } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"

const commands = [
  { id: "home", label: "Home", href: "/", icon: Home, shortcut: "H" },
  { id: "trade", label: "Trade Perpetuals", href: "/trade", icon: TrendingUp, shortcut: "T" },
  { id: "spot", label: "Spot Trading", href: "/spot", icon: ArrowLeftRight, shortcut: "S" },
  { id: "liquidity", label: "Liquidity Mining", href: "/liquidity", icon: Droplets, shortcut: "L" },
  { id: "staking", label: "Staking", href: "/staking", icon: Lock, shortcut: "K" },
]

export function CommandBar() {
  const [open, setOpen] = useState(false)
  const [search, setSearch] = useState("")
  const router = useRouter()
  const pathname = usePathname()

  const filteredCommands = commands.filter(
    (cmd) =>
      cmd.label.toLowerCase().includes(search.toLowerCase()) ||
      cmd.shortcut.toLowerCase().includes(search.toLowerCase()),
  )

  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        setOpen((open) => !open)
      }

      // Quick navigation shortcuts
      if (!open) {
        commands.forEach((cmd) => {
          if (e.key.toLowerCase() === cmd.shortcut.toLowerCase() && (e.metaKey || e.ctrlKey)) {
            e.preventDefault()
            router.push(cmd.href)
          }
        })
      }
    }

    document.addEventListener("keydown", down)
    return () => document.removeEventListener("keydown", down)
  }, [open, router])

  // Don't show on landing page
  if (pathname === "/") return null

  const handleSelect = (href: string) => {
    router.push(href)
    setOpen(false)
    setSearch("")
  }

  return (
    <>
      {/* Floating command bar trigger */}
      <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50">
        <button
          onClick={() => setOpen(true)}
          className="flex items-center gap-3 px-4 py-3 bg-card/80 backdrop-blur-lg border border-border rounded-full shadow-lg hover:bg-card transition-colors"
        >
          <Command className="w-4 h-4 text-muted-foreground" />
          <span className="text-sm text-muted-foreground">Quick Navigation</span>
          <kbd className="px-2 py-0.5 text-xs bg-secondary rounded border border-border">⌘K</kbd>
        </button>
      </div>

      {/* Command palette dialog */}
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="sm:max-w-lg p-0 bg-card border-border overflow-hidden">
          {/* Search input */}
          <div className="flex items-center gap-3 px-4 border-b border-border">
            <Search className="w-5 h-5 text-muted-foreground" />
            <Input
              placeholder="Search commands..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="flex-1 border-0 bg-transparent focus-visible:ring-0 h-14 text-lg"
            />
            <button onClick={() => setOpen(false)} className="p-1 hover:bg-secondary rounded">
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Commands list */}
          <div className="max-h-80 overflow-y-auto p-2">
            <div className="text-xs text-muted-foreground px-3 py-2">Navigation</div>
            {filteredCommands.map((cmd) => (
              <button
                key={cmd.id}
                onClick={() => handleSelect(cmd.href)}
                className={`w-full flex items-center justify-between px-3 py-3 rounded-lg transition-colors ${
                  pathname === cmd.href ? "bg-primary/20 text-primary" : "hover:bg-secondary"
                }`}
              >
                <div className="flex items-center gap-3">
                  <cmd.icon className="w-5 h-5" />
                  <span>{cmd.label}</span>
                </div>
                <kbd className="px-2 py-0.5 text-xs bg-secondary rounded border border-border">⌘{cmd.shortcut}</kbd>
              </button>
            ))}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-between px-4 py-3 border-t border-border text-xs text-muted-foreground">
            <div className="flex items-center gap-4">
              <span>
                <kbd className="px-1.5 py-0.5 bg-secondary rounded">↑↓</kbd> Navigate
              </span>
              <span>
                <kbd className="px-1.5 py-0.5 bg-secondary rounded">↵</kbd> Select
              </span>
              <span>
                <kbd className="px-1.5 py-0.5 bg-secondary rounded">Esc</kbd> Close
              </span>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
