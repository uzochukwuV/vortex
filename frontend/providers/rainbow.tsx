'use client';

import '@rainbow-me/rainbowkit/styles.css';
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit';
import { fallback, WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Define Tenderly Fork chain
const tenderlyFork = {
  id: 8,
  name: 'QIE Testnet (Tenderly Fork)',
  nativeCurrency: {
    name: 'Ethereum',
    symbol: 'ETH',
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ['https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff'],
    },
    public: {
      http: ['https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff'],
    },
  },
  blockExplorers: {
    default: {
      name: 'Tenderly',
      url: 'https://dashboard.tenderly.co',
    },
  },
  testnet: true,
} as const;



const qieBlockchain = {
  id: 1983,
  name: 'QIE Testnet',
  nativeCurrency: {
    name: 'QIE',
    symbol: 'QIE',
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: [
         'https://rpc1testnet.qie.digital/',
        'https://rpc2testnet.qie.digital/',
        'https://rpc3testnet.qie.digital/',
      ],

    },
    fallback : {
      http: [
        'https://rpc1testnet.qie.digital/',
        'https://rpc2testnet.qie.digital/',
        'https://rpc3testnet.qie.digital/',
      ],
     
    },
    public: {
      http: ['https://rpc1testnet.qie.digital/'],
    },
  },
  blockExplorers: {
    default: {
      name: 'QIE Explorer',
      url: 'https://testnet-explorer.qie.digital/',
    },
  },
  testnet: true,

}

// Configure wagmi with RainbowKit
const config = getDefaultConfig({
  appName: 'Perpetual DEX',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID',
  chains: [tenderlyFork as any, qieBlockchain as any ],
  ssr: false,
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,
    },
  },
});

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          modalSize="compact"
          appInfo={{
            appName: 'Perpetual DEX',
          }}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
