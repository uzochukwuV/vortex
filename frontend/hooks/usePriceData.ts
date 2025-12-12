import { useState, useEffect } from 'react';

const COINGECKO_API_KEY = 'CG-R58brJSKYcxGS2pMEYAVftBG';

const COIN_MAP: Record<string, string> = {
  'BTC': 'bitcoin',
  'ETH': 'ethereum',
  'BNB': 'binancecoin',
  'SOL': 'solana',
};

interface PriceData {
  price: number;
  change24h: number;
  high24h: number;
  low24h: number;
  volume24h: number;
}

interface CandleData {
  time: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume?: number;
}

export function usePriceData(symbol: string) {
  const [priceData, setPriceData] = useState<PriceData | null>(null);
  const [candles, setCandles] = useState<CandleData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const coinId = COIN_MAP[symbol] || 'bitcoin';
    const options = {
      method: 'GET',
      headers: { 'x-cg-demo-api-key': COINGECKO_API_KEY }
    };

    const fetchPrice = async () => {
      try {
        const data = await fetch(
          `https://api.coingecko.com/api/v3/simple/price?ids=${coinId}&vs_currencies=usd&include_24hr_vol=true&include_24hr_change=true&include_last_updated_at=true`,
          options
        ).then(r => r.json());

        const coinData = data[coinId];
        if (coinData) {
          setPriceData({
            price: coinData.usd,
            change24h: coinData.usd_24h_change || 0,
            high24h: coinData.usd * 1.02, // Approximate
            low24h: coinData.usd * 0.98,  // Approximate
            volume24h: coinData.usd_24h_vol || 0,
          });
        }
      } catch (error) {
        console.error('Failed to fetch price:', error);
      }
    };

    const fetchCandles = async () => {
      try {
        const data = await fetch(
          `https://api.coingecko.com/api/v3/coins/${coinId}/ohlc?vs_currency=usd&days=1`,
          options
        ).then(r => r.json());

        const formatted = data.map((k: number[]) => ({
          time: k[0] / 1000,
          open: k[1],
          high: k[2],
          low: k[3],
          close: k[4],
        }));

        setCandles(formatted);
        setLoading(false);
      } catch (error) {
        console.error('Failed to fetch candles:', error);
        setLoading(false);
      }
    };

    fetchPrice();
    fetchCandles();

    // Poll for updates every 30 seconds (CoinGecko rate limit)
    const interval = setInterval(() => {
      fetchPrice();
      fetchCandles();
    }, 100000);

    return () => clearInterval(interval);
  }, [symbol]);

  return { priceData, candles, loading };
}
