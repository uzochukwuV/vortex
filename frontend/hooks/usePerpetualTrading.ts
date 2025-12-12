import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, parseGwei } from 'viem';
import PerpetualTradingABI from '@/abi/PerpetualTrading.json';
import { PERPETUAL_TRADING_ADDRESS } from '@/lib/constants';


export function usePerpetualTrading() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  // Read functions
  const useGetPosition = (positionId: bigint) => {
    return useReadContract({
      address: PERPETUAL_TRADING_ADDRESS,
      abi: PerpetualTradingABI,
      functionName: 'getPosition',
      args: [positionId],
    });
  };

  const useGetTraderPositions = (trader: `0x${string}`) => {
    return useReadContract({
      address: PERPETUAL_TRADING_ADDRESS,
      abi: PerpetualTradingABI,
      functionName: 'getTraderPositions',
      args: [trader],
    });
  };

  const useMaxLeverage = () => {
    return useReadContract({
      address: PERPETUAL_TRADING_ADDRESS,
      abi: PerpetualTradingABI,
      functionName: 'MAX_LEVERAGE',
    });
  };

  // Write functions with gas settings for QIE blockchain
  const openPosition = async (
    asset: string,
    isLong: boolean,
    collateralAmount: string,
    leverage: number
  ) => {
    console.log(asset, isLong, collateralAmount, leverage);
    return writeContract({
      address: PERPETUAL_TRADING_ADDRESS,
      abi: PerpetualTradingABI,
      functionName: 'openPosition',
      args: [asset, isLong, parseUnits(collateralAmount, 6), BigInt(leverage)],
      gas: BigInt(500000),
      gasPrice: parseGwei('2'),
    });
  };

  const closePosition = async (positionId: bigint) => {
    return writeContract({
      address: PERPETUAL_TRADING_ADDRESS,
      abi: PerpetualTradingABI,
      functionName: 'closePosition',
      args: [positionId],
      gas: BigInt(300000),
      gasPrice: parseGwei('2'),
    });
  };

  const liquidatePosition = async (positionId: bigint) => {
    return writeContract({
      address: PERPETUAL_TRADING_ADDRESS,
      abi: PerpetualTradingABI,
      functionName: 'liquidatePosition',
      args: [positionId],
      gas: BigInt(300000),
      gasPrice: parseGwei('2'),
    });
  };

  return {
    useGetPosition,
    useGetTraderPositions,
    useMaxLeverage,
    openPosition,
    closePosition,
    liquidatePosition,
    isPending,
    isConfirming,
    isSuccess,
    hash,
  };
}
