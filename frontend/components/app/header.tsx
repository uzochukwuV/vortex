'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';

export function Header() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-14 max-w-screen-2xl items-center justify-between">
        <div className="flex items-center gap-6">
          <a href="/" className="flex items-center space-x-2">
            <span className="font-bold text-xl">VORTEX DEX</span>
          </a>
          <nav className="hidden md:flex gap-6">
            <a href="/trade" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">
              Trade
            </a>
            <a href="/spot" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">
              Spot
            </a>
            <a href="/liquidity" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">
              Liquidity
            </a>
            <a href="/staking" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">
              Staking
            </a>
          </nav>
        </div>
        <div className="flex items-center gap-4">
          <ConnectButton />
        </div>
      </div>
    </header>
  );
}
