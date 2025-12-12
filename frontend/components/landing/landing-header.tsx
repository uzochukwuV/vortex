"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { Menu, X } from "lucide-react"
import { Button } from "@/components/ui/button"

export function LandingHeader() {
  const [isScrolled, setIsScrolled] = useState(false)
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 20)
    window.addEventListener("scroll", handleScroll, { passive: true })
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled ? "bg-background/80 backdrop-blur-lg border-b border-border" : "bg-transparent"
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2">
          <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
            <span className="text-primary-foreground font-bold text-xl">V</span>
          </div>
          <span className="font-bold text-xl tracking-tight">VORTEX</span>
        </Link>

        {/* Desktop nav */}
        <nav className="hidden md:flex items-center gap-8">
          <Link href="#features" className="text-muted-foreground hover:text-foreground transition-colors">
            Features
          </Link>
          <Link href="/trade" className="text-muted-foreground hover:text-foreground transition-colors">
            Trade
          </Link>
          <Link href="/spot" className="text-muted-foreground hover:text-foreground transition-colors">
            Spot
          </Link>
          <Link href="/liquidity" className="text-muted-foreground hover:text-foreground transition-colors">
            Earn
          </Link>
          <a
            href="https://docs.example.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-muted-foreground hover:text-foreground transition-colors"
          >
            Docs
          </a>
        </nav>

        {/* CTA */}
        <div className="hidden md:flex items-center gap-4">
          <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
            <Link href="/trade">Launch App</Link>
          </Button>
        </div>

        {/* Mobile menu button */}
        <button className="md:hidden p-2" onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}>
          {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
      </div>

      {/* Mobile menu */}
      {isMobileMenuOpen && (
        <div className="md:hidden bg-background border-b border-border">
          <nav className="flex flex-col p-6 gap-4">
            <Link href="#features" className="text-muted-foreground hover:text-foreground transition-colors py-2">
              Features
            </Link>
            <Link href="/trade" className="text-muted-foreground hover:text-foreground transition-colors py-2">
              Trade
            </Link>
            <Link href="/spot" className="text-muted-foreground hover:text-foreground transition-colors py-2">
              Spot
            </Link>
            <Link href="/liquidity" className="text-muted-foreground hover:text-foreground transition-colors py-2">
              Earn
            </Link>
            <Button asChild className="mt-4 bg-primary text-primary-foreground">
              <Link href="/trade">Launch App</Link>
            </Button>
          </nav>
        </div>
      )}
    </header>
  )
}
