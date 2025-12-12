import { AppHeader } from "@/components/app/app-header"
import { StakingOverview } from "@/components/staking/staking-overview"
import { StakeCard } from "@/components/staking/stake-card"
import { StakingTiers } from "@/components/staking/staking-tiers"
import { VestingSchedule } from "@/components/staking/vesting-schedule"

export default function StakingPage() {
  return (
    <div className="min-h-screen bg-background">
      <AppHeader />

      <main className="p-6">
        <div className="max-w-7xl mx-auto space-y-8">
          {/* Header */}
          <div>
            <h1 className="text-3xl font-bold mb-2">Staking</h1>
            <p className="text-muted-foreground">
              Stake VTX tokens to earn rewards and unlock exclusive benefits. Lock for longer to earn higher APR.
            </p>
          </div>

          {/* Overview stats */}
          <StakingOverview />

          <div className="grid lg:grid-cols-2 gap-6">
            {/* Stake/Unstake card */}
            <StakeCard />

            {/* Staking tiers */}
            <StakingTiers />
          </div>

          {/* Vesting schedule */}
          <VestingSchedule />
        </div>
      </main>
    </div>
  )
}
