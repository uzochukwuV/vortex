import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseGwei, parseUnits } from 'viem';
import MockERC20ABI from '@/abi/MockERC20.json';

export function useERC20(tokenAddress: `0x${string}`, decimals: number = 18) {
  const { mutateAsync, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  // Read functions
  const useBalance = (address: `0x${string}` | undefined) => {
    return useReadContract({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'balanceOf',
      args: address ? [address] : undefined,
      query: { enabled: !!address && !!tokenAddress },
    });
  };

  const useAllowance = (owner: `0x${string}` | undefined, spender: `0x${string}`) => {
    return useReadContract({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'allowance',
      args: owner ? [owner, spender] : undefined,
      query: { enabled: !!owner && !!tokenAddress },
    });
  };

  const useDecimals = () => {
    return useReadContract({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'decimals',
      query: { enabled: !!tokenAddress },
    });
  };

  const useSymbol = () => {
    return useReadContract({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'symbol',
      query: { enabled: !!tokenAddress },
    });
  };

  const useName = () => {
    return useReadContract({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'name',
      query: { enabled: !!tokenAddress },
    });
  };

  // Write functions with gas settings for QIE blockchain
  const approve = async (spender: `0x${string}`, amount: string) => {
    return mutateAsync({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'approve',
      args: [spender, parseUnits(amount, decimals)],
      gas: 100000n,
      gasPrice: parseGwei('2'),
    });
  };

  const transfer = async (to: `0x${string}`, amount: string) => {
    return mutateAsync({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'transfer',
      args: [to, parseUnits(amount, decimals)],
      gas: 100000n,
      gasPrice: parseGwei('2'),
    });
  };

  // Mint function for testnet mock tokens
  const mint = async (to: `0x${string}`, amount: string) => {
    return mutateAsync({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'mint',
      args: [to, parseUnits(amount, decimals)],

    });
  };

  // Convenience function to mint to self
  const mintToSelf = async (amount: string) => {
    return mutateAsync({
      address: tokenAddress,
      abi: MockERC20ABI,
      functionName: 'mintTo',
      args: [parseUnits(amount, decimals)],
      gas: 100000n,
      gasPrice: parseGwei('2'),
    });
  };

  return {
    useBalance,
    useAllowance,
    useDecimals,
    useSymbol,
    useName,
    approve,
    transfer,
    mint,
    mintToSelf,
    isPending,
    isConfirming,
    isSuccess,
    hash,
  };
}
