"use client"

import { useEffect, useRef, useState } from "react"
import Link from "next/link"
import { ArrowRight, ChevronDown } from "lucide-react"
import { Button } from "@/components/ui/button"

export function HeroSection() {
  const [scrollY, setScrollY] = useState(0)
  const heroRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY)
    window.addEventListener("scroll", handleScroll, { passive: true })
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const opacity = Math.max(0, 1 - scrollY / 600)
  const scale = Math.max(0.8, 1 - scrollY / 3000)
  const translateY = scrollY * 0.3

  return (
    <section ref={heroRef} className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden">
      {/* Background gradient orbs */}
      <div
        className="absolute top-1/4 left-1/4 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl animate-pulse-glow"
        style={{ transform: `translate(${scrollY * 0.1}px, ${scrollY * 0.05}px)` }}
      />
      <div
        className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-orange-600/10 rounded-full blur-3xl animate-pulse-glow"
        style={{ animationDelay: "1.5s", transform: `translate(-${scrollY * 0.1}px, -${scrollY * 0.05}px)` }}
      />

      {/* Grid pattern overlay */}
      <div
        className="absolute inset-0 opacity-[0.02]"
        style={{
          backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
          backgroundSize: "60px 60px",
        }}
      />

      <div
        className="relative z-10 text-center px-6 max-w-6xl mx-auto"
        style={{
          opacity,
          transform: `scale(${scale}) translateY(${translateY}px)`,
        }}
      >
        {/* Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-2 mb-8 bg-secondary/50 border border-border rounded-full text-sm text-muted-foreground animate-fade-in">
          <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
          Live on Mainnet
        </div>

        {/* Main headline */}
        <h1 className="text-5xl sm:text-7xl lg:text-8xl font-bold tracking-tight mb-6 animate-slide-up">
          <span className="text-foreground">TRADE</span>
          <br />
          <span className="text-primary">WITHOUT</span>
          <br />
          <span className="text-foreground">LIMITS</span>
        </h1>

        {/* Subheadline */}
        <p
          className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto mb-10 leading-relaxed animate-slide-up"
          style={{ animationDelay: "0.2s" }}
        >
          Perpetual futures up to 50x leverage. Spot trading with deep liquidity. Earn yield through liquidity mining
          and staking.
        </p>

        {/* CTA Buttons */}
        <div
          className="flex flex-col sm:flex-row gap-4 justify-center animate-slide-up"
          style={{ animationDelay: "0.4s" }}
        >
          <Button
            asChild
            size="lg"
            className="text-lg px-8 py-6 bg-primary text-primary-foreground hover:bg-primary/90"
          >
            <Link href="/trade">
              Launch App
              <ArrowRight className="ml-2 w-5 h-5" />
            </Link>
          </Button>
          <Button
            asChild
            variant="outline"
            size="lg"
            className="text-lg px-8 py-6 border-border hover:bg-secondary bg-transparent"
          >
            <Link href="#features">Learn More</Link>
          </Button>
        </div>

        {/* Stats row */}
        <div
          className="grid grid-cols-3 gap-8 mt-20 pt-10 border-t border-border/50 animate-slide-up"
          style={{ animationDelay: "0.6s" }}
        >
          <div>
            <div className="text-3xl sm:text-4xl font-bold text-primary">$2.4B+</div>
            <div className="text-sm text-muted-foreground mt-1">Trading Volume</div>
          </div>
          <div>
            <div className="text-3xl sm:text-4xl font-bold text-foreground">150K+</div>
            <div className="text-sm text-muted-foreground mt-1">Traders</div>
          </div>
          <div>
            <div className="text-3xl sm:text-4xl font-bold text-foreground">$89M</div>
            <div className="text-sm text-muted-foreground mt-1">Total Value Locked</div>
          </div>
        </div>
      </div>

      {/* Scroll indicator */}
      <div
        className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-muted-foreground animate-bounce"
        style={{ opacity: Math.max(0, 1 - scrollY / 200) }}
      >
        <span className="text-xs uppercase tracking-widest">Scroll</span>
        <ChevronDown className="w-5 h-5" />
      </div>
    </section>
  )
}
