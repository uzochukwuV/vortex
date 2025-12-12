import Link from "next/link"
import { Twitter, Github, MessageCircle } from "lucide-react"

export function Footer() {
  return (
    <footer className="py-16 px-6 border-t border-border bg-card/30">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <Link href="/" className="flex items-center gap-2 mb-4">
              <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center">
                <span className="text-primary-foreground font-bold text-xl">V</span>
              </div>
              <span className="font-bold text-xl">VORTEX</span>
            </Link>
            <p className="text-sm text-muted-foreground">Decentralized perpetual and spot trading platform.</p>
          </div>

          {/* Products */}
          <div>
            <h4 className="font-semibold mb-4">Products</h4>
            <ul className="space-y-3 text-sm text-muted-foreground">
              <li>
                <Link href="/trade" className="hover:text-foreground transition-colors">
                  Perpetuals
                </Link>
              </li>
              <li>
                <Link href="/spot" className="hover:text-foreground transition-colors">
                  Spot Trading
                </Link>
              </li>
              <li>
                <Link href="/liquidity" className="hover:text-foreground transition-colors">
                  Liquidity
                </Link>
              </li>
              <li>
                <Link href="/staking" className="hover:text-foreground transition-colors">
                  Staking
                </Link>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h4 className="font-semibold mb-4">Resources</h4>
            <ul className="space-y-3 text-sm text-muted-foreground">
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  Documentation
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  API Reference
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  Audit Reports
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  Brand Assets
                </a>
              </li>
            </ul>
          </div>

          {/* Community */}
          <div>
            <h4 className="font-semibold mb-4">Community</h4>
            <ul className="space-y-3 text-sm text-muted-foreground">
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  Discord
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  Twitter
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  Telegram
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-foreground transition-colors">
                  Blog
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="flex flex-col md:flex-row justify-between items-center pt-8 border-t border-border gap-4">
          <p className="text-sm text-muted-foreground">2024 VORTEX. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <a href="#" className="text-muted-foreground hover:text-foreground transition-colors">
              <Twitter className="w-5 h-5" />
            </a>
            <a href="#" className="text-muted-foreground hover:text-foreground transition-colors">
              <Github className="w-5 h-5" />
            </a>
            <a href="#" className="text-muted-foreground hover:text-foreground transition-colors">
              <MessageCircle className="w-5 h-5" />
            </a>
          </div>
        </div>
      </div>
    </footer>
  )
}
