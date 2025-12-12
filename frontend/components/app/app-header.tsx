"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { ChevronDown, Settings, Bell } from "lucide-react"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { WalletModal } from "@/components/web3/wallet-modal"
import { useChainId, useSwitchChain } from "wagmi"

const navItems = [
  { href: "/trade", label: "Trade" },
  { href: "/spot", label: "Spot" },
  { href: "/liquidity", label: "Liquidity" },
  { href: "/staking", label: "Staking" },
]

export function AppHeader() {
  const pathname = usePathname()
  const chainId = useChainId()
  const {chains, switchChain} = useSwitchChain();

  const changeNetwork = () => {
    // Logic to change network goes here
  }

  return (
    <header className="h-16 border-b border-border bg-card/50 backdrop-blur-sm sticky top-0 z-50">
      <div className="h-full px-4 flex items-center justify-between">
        {/* Logo and nav */}
        <div className="flex items-center gap-8">
          <Link href="/" className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <span className="text-primary-foreground font-bold text-lg">V</span>
            </div>
            <span className="font-bold text-lg tracking-tight hidden sm:block">VORTEX</span>
          </Link>

          <nav className="flex items-center gap-1">
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                  pathname === item.href
                    ? "bg-secondary text-foreground"
                    : "text-muted-foreground hover:text-foreground hover:bg-secondary/50"
                }`}
              >
                {item.label}
              </Link>
            ))}
          </nav>
        </div>

        {/* Right side */}
        <div className="flex items-center gap-3">
          {/* Network selector */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="gap-2 bg-transparent">
                <div className="w-2 h-2 bg-green-500 rounded-full" />
                <span className="hidden sm:inline">{chainId == 1990 ? "QIE Mainnet" : "QIE Testnet"}</span>
                <ChevronDown className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">

              {chains.map((chain) => (
        <DropdownMenuItem key={chain.id} onClick={() => switchChain({ chainId: chain.id })}>
          {chain.name}
        </DropdownMenuItem>
      ))}
            </DropdownMenuContent>
          </DropdownMenu>

          {/* Notifications */}
          <Button variant="ghost" size="icon" className="relative">
            <Bell className="w-5 h-5" />
            <span className="absolute top-1 right-1 w-2 h-2 bg-primary rounded-full" />
          </Button>

          {/* Settings */}
          <Button variant="ghost" size="icon">
            <Settings className="w-5 h-5" />
          </Button>

          <WalletModal />
        </div>
      </div>
    </header>
  )
}
