"use client"

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { useERC20Ethers } from '@/hooks/useERC20Ethers';
import { CONTRACTS } from '@/lib/constants';
import { usePrivy } from '@privy-io/react-auth';
import { toast } from 'sonner';

export function TestEthersMint() {
  const { user, authenticated } = usePrivy();
  const usdtToken = useERC20Ethers(CONTRACTS.MOCK_USDT as `0x${string}`, 6);
  const [balance, setBalance] = useState<string>('0');

  const handleMint = async () => {
    if (!authenticated || !user) {
      toast.error('Please connect wallet');
      return;
    }

    try {
      toast.info('Minting 10,000 USDT...');
      const result = await usdtToken.mintToSelf('10000');
      toast.success(`Minted! Tx: ${result.hash}`);

      // Refresh balance
      await checkBalance();
    } catch (error: any) {
      console.error('Mint error:', error);
      toast.error(error.message || 'Failed to mint');
    }
  };

  const checkBalance = async () => {
    if (!authenticated || !user?.wallet?.address) return;

    try {
      const bal = await usdtToken.getBalance(user.wallet.address);
      const balanceFormatted = (Number(bal) / 1e6).toFixed(2);
      setBalance(balanceFormatted);
    } catch (error) {
      console.error('Balance check error:', error);
    }
  };

  return (
    <div className="p-4 border rounded-lg space-y-4">
      <h3 className="font-bold">Test Ethers.js Direct</h3>
      <p>Balance: {balance} USDT</p>
      <div className="flex gap-2">
        <Button onClick={checkBalance} variant="outline" disabled={!authenticated}>
          Check Balance
        </Button>
        <Button
          onClick={handleMint}
          disabled={!authenticated || usdtToken.isPending}
        >
          {usdtToken.isPending ? 'Minting...' : 'Mint 10k USDT'}
        </Button>
      </div>
      {usdtToken.txHash && (
        <p className="text-xs text-muted-foreground">
          Last tx: {usdtToken.txHash}
        </p>
      )}
    </div>
  );
}
