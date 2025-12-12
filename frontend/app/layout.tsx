import type React from "react"
import type { Metadata } from "next"

import { Analytics } from "@vercel/analytics/next"
import "./globals.css"
import { CommandBar } from "@/components/app/command-bar"


import { Oxanium, Space_Grotesk, Oxanium as V0_Font_Oxanium, Source_Code_Pro as V0_Font_Source_Code_Pro, Source_Serif_4 as V0_Font_Source_Serif_4 } from 'next/font/google'
import Providers from "@/providers/rainbow"
import { Toaster } from "@/components/ui/toaster"

const _spaceGrotesk = Space_Grotesk({ subsets: ["latin"], variable: "--font-space" })
// Initialize fonts
const _oxanium = V0_Font_Oxanium({ subsets: ['latin'], weight: ["200","300","400","500","600","700","800"] })
const _sourceCodePro = V0_Font_Source_Code_Pro({ subsets: ['latin'], weight: ["200","300","400","500","600","700","800","900"] })
const _sourceSerif_4 = V0_Font_Source_Serif_4({ subsets: ['latin'], weight: ["200","300","400","500","600","700","800","900"] })

export const metadata: Metadata = {

  title: "VORTEX DEX | Perpetual & Spot Trading",
  description:
    "Trade perpetual futures and spot markets with deep liquidity. Earn yield through liquidity mining and staking.",
  generator: "v0.app",
  icons: {
    icon: [
      {
        url: "/icon-light-32x32.png",
        media: "(prefers-color-scheme: light)",
      },
      {
        url: "/icon-dark-32x32.png",
        media: "(prefers-color-scheme: dark)",
      },
      {
        url: "/icon.svg",
        type: "image/svg+xml",
      },
    ],
    apple: "/apple-icon.png",
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="dark">
      <Providers>
        <body className={`font-sans antialiased`}>
        {children}
        <CommandBar />
        <Toaster />
        <Analytics />
      </body>
      </Providers>
    </html>
  )
}
