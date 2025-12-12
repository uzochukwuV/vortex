"use client"

import { useEffect, useState, useRef } from "react"

const stats = [
  { value: 2400000000, prefix: "$", suffix: "", label: "Total Trading Volume", decimals: 0 },
  { value: 89000000, prefix: "$", suffix: "", label: "Total Value Locked", decimals: 0 },
  { value: 150000, prefix: "", suffix: "+", label: "Active Traders", decimals: 0 },
  { value: 99.9, prefix: "", suffix: "%", label: "Uptime", decimals: 1 },
]

function formatNumber(num: number, decimals = 0): string {
  if (num >= 1000000000) return (num / 1000000000).toFixed(1) + "B"
  if (num >= 1000000) return (num / 1000000).toFixed(1) + "M"
  if (num >= 1000) return (num / 1000).toFixed(1) + "K"
  return num.toFixed(decimals)
}

function AnimatedCounter({
  value,
  prefix,
  suffix,
  decimals,
  isVisible,
}: {
  value: number
  prefix: string
  suffix: string
  decimals: number
  isVisible: boolean
}) {
  const [count, setCount] = useState(0)

  useEffect(() => {
    if (!isVisible) return

    const duration = 2000
    const steps = 60
    const increment = value / steps
    let current = 0

    const timer = setInterval(() => {
      current += increment
      if (current >= value) {
        setCount(value)
        clearInterval(timer)
      } else {
        setCount(current)
      }
    }, duration / steps)

    return () => clearInterval(timer)
  }, [isVisible, value])

  return (
    <span>
      {prefix}
      {formatNumber(count, decimals)}
      {suffix}
    </span>
  )
}

export function StatsSection() {
  const [isVisible, setIsVisible] = useState(false)
  const sectionRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true)
        }
      },
      { threshold: 0.3 },
    )

    if (sectionRef.current) {
      observer.observe(sectionRef.current)
    }

    return () => observer.disconnect()
  }, [])

  return (
    <section ref={sectionRef} className="py-24 px-6 bg-secondary/30 border-y border-border">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-8 lg:gap-12">
          {stats.map((stat, index) => (
            <div
              key={index}
              className={`text-center transition-all duration-700 ${
                isVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"
              }`}
              style={{ transitionDelay: `${index * 150}ms` }}
            >
              <div className="text-4xl sm:text-5xl lg:text-6xl font-bold text-primary mb-2">
                <AnimatedCounter
                  value={stat.value}
                  prefix={stat.prefix}
                  suffix={stat.suffix}
                  decimals={stat.decimals}
                  isVisible={isVisible}
                />
              </div>
              <div className="text-sm sm:text-base text-muted-foreground">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
