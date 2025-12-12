"use client"

import { useEffect, useRef, useState } from "react"
import { TrendingUp, ArrowLeftRight, Droplets, Lock, Zap, Shield } from "lucide-react"

const features = [
  {
    icon: TrendingUp,
    title: "Perpetual Futures",
    description:
      "Trade with up to 50x leverage on major crypto assets. Advanced order types and risk management tools.",
    accent: "bg-amber-500/20 text-amber-500",
  },
  {
    icon: ArrowLeftRight,
    title: "Spot Trading",
    description: "Instant swaps with minimal slippage. Access deep liquidity pools across all major trading pairs.",
    accent: "bg-orange-500/20 text-orange-500",
  },
  {
    icon: Droplets,
    title: "Liquidity Mining",
    description: "Provide liquidity and earn competitive yields. Auto-compounding rewards with no lockup periods.",
    accent: "bg-amber-600/20 text-amber-600",
  },
  {
    icon: Lock,
    title: "Staking",
    description: "Stake tokens to earn protocol fees. Governance rights and exclusive benefits for stakers.",
    accent: "bg-yellow-500/20 text-yellow-500",
  },
  {
    icon: Zap,
    title: "Lightning Fast",
    description: "Sub-second transaction finality. Built on high-performance infrastructure for instant execution.",
    accent: "bg-orange-400/20 text-orange-400",
  },
  {
    icon: Shield,
    title: "Battle-Tested Security",
    description: "Audited smart contracts. Multi-sig treasury and comprehensive insurance fund protection.",
    accent: "bg-amber-400/20 text-amber-400",
  },
]

export function FeaturesSection() {
  const [visibleItems, setVisibleItems] = useState<number[]>([])
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = Number(entry.target.getAttribute("data-index"))
            setVisibleItems((prev) => [...new Set([...prev, index])])
          }
        })
      },
      { threshold: 0.2, rootMargin: "0px 0px -100px 0px" },
    )

    const items = sectionRef.current?.querySelectorAll("[data-index]")
    items?.forEach((item) => observer.observe(item))

    return () => observer.disconnect()
  }, [])

  return (
    <section id="features" ref={sectionRef} className="py-32 px-6">
      <div className="max-w-7xl mx-auto">
        {/* Section header */}
        <div className="text-center mb-20">
          <h2 className="text-4xl sm:text-5xl lg:text-6xl font-bold mb-6">
            Built for <span className="text-primary">Traders</span>
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Everything you need to trade, earn, and grow your portfolio in one powerful platform.
          </p>
        </div>

        {/* Features grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <div
              key={index}
              data-index={index}
              className={`group relative p-8 bg-card border border-border rounded-lg transition-all duration-500 hover:border-primary/50 hover:bg-card/80 ${
                visibleItems.includes(index) ? "opacity-100 translate-y-0" : "opacity-0 translate-y-10"
              }`}
              style={{ transitionDelay: `${index * 100}ms` }}
            >
              {/* Icon */}
              <div className={`inline-flex p-3 rounded-lg mb-6 ${feature.accent}`}>
                <feature.icon className="w-6 h-6" />
              </div>

              {/* Content */}
              <h3 className="text-xl font-semibold mb-3 group-hover:text-primary transition-colors">{feature.title}</h3>
              <p className="text-muted-foreground leading-relaxed">{feature.description}</p>

              {/* Hover glow effect */}
              <div className="absolute inset-0 rounded-lg bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
