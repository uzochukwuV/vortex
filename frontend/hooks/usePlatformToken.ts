import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits } from 'viem';
import PlatformTokenABI from '@/abi/PlatformToken.json';
import { PLATFORM_TOKEN_ADDRESS } from '@/lib/constants';


export function usePlatformToken() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  // Read functions
  const useBalance = (address: `0x${string}` | undefined) => {
    return useReadContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'balanceOf',
      args: address ? [address] : undefined,
      query: { enabled: !!address },
    });
  };

  const useAllowance = (owner: `0x${string}` | undefined, spender: `0x${string}`) => {
    return useReadContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'allowance',
      args: owner ? [owner, spender] : undefined,
      query: { enabled: !!owner },
    });
  };

  const useTotalSupply = () => {
    return useReadContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'totalSupply',
    });
  };

  const useTokenInfo = () => {
    const { data: name } = useReadContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'name',
    });

    const { data: symbol } = useReadContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'symbol',
    });

    const { data: decimals } = useReadContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'decimals',
    });

    return { name, symbol, decimals };
  };

  // Write functions
  const approve = async (spender: `0x${string}`, amount: string) => {
    return writeContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'approve',
      args: [spender, parseUnits(amount, 18)],
    });
  };

  const transfer = async (to: `0x${string}`, amount: string) => {
    return writeContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'transfer',
      args: [to, parseUnits(amount, 18)],
    });
  };

  const burn = async (amount: string) => {
    return writeContract({
      address: PLATFORM_TOKEN_ADDRESS,
      abi: PlatformTokenABI,
      functionName: 'burn',
      args: [parseUnits(amount, 18)],
    });
  };

  return {
    useBalance,
    useAllowance,
    useTotalSupply,
    useTokenInfo,
    approve,
    transfer,
    burn,
    isPending,
    isConfirming,
    isSuccess,
    hash,
  };
}
