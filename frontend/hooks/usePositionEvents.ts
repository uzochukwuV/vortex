import { useState, useEffect } from 'react';
import { usePublicClient, useWatchContractEvent } from 'wagmi';
import PerpetualTradingABI from '@/abi/PerpetualTrading.json';
import { formatUnits } from 'viem';
import { PERPETUAL_TRADING_ADDRESS } from '@/lib/constants';


interface Position {
  positionId: bigint;
  trader: string;
  asset: string;
  isLong: boolean;
  size: bigint;
  collateral: bigint;
  leverage: bigint;
  entryPrice: bigint;
  timestamp: number;
}

export function usePositionEvents(asset?: string) {
  const [openPositions, setOpenPositions] = useState<Position[]>([]);
  const [longOI, setLongOI] = useState(0);
  const [shortOI, setShortOI] = useState(0);

  // Watch PositionOpened events
  useWatchContractEvent({
    address: PERPETUAL_TRADING_ADDRESS,
    abi: PerpetualTradingABI,
    eventName: 'PositionOpened',
    onLogs(logs) {
      logs.forEach((log: any) => {
        const { positionId, trader, asset: posAsset, isLong, size, collateral, leverage, entryPrice } = log.args;
        console.log('PositionOpened event:', { positionId, trader, posAsset, isLong, size: formatUnits(size, 18) });
        // Filter by asset if specified
        if (asset && posAsset !== asset) return;

        const position: Position = {
          positionId,
          trader,
          asset: posAsset,
          isLong,
          size,
          collateral,
          leverage,
          entryPrice,
          timestamp: Date.now(),
        };

        setOpenPositions(prev => [...prev, position]);

        // Update OI
        const sizeUSD = parseFloat(formatUnits(size, 18));
        if (isLong) {
          setLongOI(prev => prev + sizeUSD);
        } else {
          setShortOI(prev => prev + sizeUSD);
        }
      });
    },
  });

  // Watch PositionClosed events
  useWatchContractEvent({
    address: PERPETUAL_TRADING_ADDRESS,
    abi: PerpetualTradingABI,
    eventName: 'PositionClosed',
    onLogs(logs) {
      logs.forEach((log: any) => {
        const { positionId } = log.args;

        setOpenPositions(prev => {
          const position = prev.find(p => p.positionId === positionId);
          if (position) {
            const sizeUSD = parseFloat(formatUnits(position.size, 18));
            if (position.isLong) {
              setLongOI(prev => Math.max(0, prev - sizeUSD));
            } else {
              setShortOI(prev => Math.max(0, prev - sizeUSD));
            }
          }
          return prev.filter(p => p.positionId !== positionId);
        });
      });
    },
  });

  // Watch PositionLiquidated events
  useWatchContractEvent({
    address: PERPETUAL_TRADING_ADDRESS,
    abi: PerpetualTradingABI,
    eventName: 'PositionLiquidated',
    onLogs(logs) {
      logs.forEach((log: any) => {
        const { positionId } = log.args;

        setOpenPositions(prev => {
          const position = prev.find(p => p.positionId === positionId);
          if (position) {
            const sizeUSD = parseFloat(formatUnits(position.size, 18));
            if (position.isLong) {
              setLongOI(prev => Math.max(0, prev - sizeUSD));
            } else {
              setShortOI(prev => Math.max(0, prev - sizeUSD));
            }
          }
          return prev.filter(p => p.positionId !== positionId);
        });
      });
    },
  });

  // Load historical positions on mount
  const publicClient = usePublicClient();

  useEffect(() => {
    const loadHistoricalPositions = async () => {
      if (!publicClient) return;
      console.log('Loading historical positions...');
      try {
        // Get PositionOpened events from last 1000 blocks
        const currentBlock = await publicClient.getBlockNumber();
        const fromBlock = currentBlock - BigInt(999);

        console.log(currentBlock, fromBlock, "dddhhhhhhh")

        const openedLogs = await publicClient.getContractEvents({
          address: PERPETUAL_TRADING_ADDRESS,
          abi: PerpetualTradingABI,
          eventName: 'PositionOpened',
          fromBlock,
        });

        console.log('Fetched openedLogs:', openedLogs.length);


        const closedLogs = await publicClient.getContractEvents({
          address: PERPETUAL_TRADING_ADDRESS,
          abi: PerpetualTradingABI,
          eventName: 'PositionClosed',
          fromBlock,
        });

        const liquidatedLogs = await publicClient.getContractEvents({
          address: PERPETUAL_TRADING_ADDRESS,
          abi: PerpetualTradingABI,
          eventName: 'PositionLiquidated',
          fromBlock,
        });

        // Build set of closed position IDs
        const closedIds = new Set([
          ...closedLogs.map((log: any) => log.args.positionId.toString()),
          ...liquidatedLogs.map((log: any) => log.args.positionId.toString()),
        ]);

        // Filter to only open positions
        const positions: Position[] = [];
        let totalLong = 0;
        let totalShort = 0;

        openedLogs.forEach((log: any) => {
          const { positionId, trader, asset: posAsset, isLong, size, collateral, leverage, entryPrice } = log.args;
          
          if (closedIds.has(positionId.toString())) return;
          if (asset && posAsset !== asset) return;

          positions.push({
            positionId,
            trader,
            asset: posAsset,
            isLong,
            size,
            collateral,
            leverage,
            entryPrice,
            timestamp: Date.now(),
          });

          const sizeUSD = parseFloat(formatUnits(size, 18));
          if (isLong) {
            totalLong += sizeUSD;
          } else {
            totalShort += sizeUSD;
          }
        });

        setOpenPositions(positions);
        setLongOI(totalLong);
        setShortOI(totalShort);
      } catch (error) {
        console.error('Failed to load historical positions:', error);
      }
    };

    loadHistoricalPositions();
  }, [publicClient, asset]);

  return { openPositions, longOI, shortOI };
}
