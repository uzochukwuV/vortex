import { usePositionEvents } from './usePositionEvents';

interface PositionData {
  longOI: number;
  shortOI: number;
  openPositions: any[];
}

export function useOrderBook(asset: string) {
  const { longOI, shortOI, openPositions } = usePositionEvents(asset);

  return { longOI, shortOI, openPositions };
}
