/** @type {import('next').NextConfig} */
const nextConfig = {
  turbopack: {
    
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
  webpack: (config, { isServer }) => {
    if (isServer) {
      config.externals.push(
        'pino-pretty', 
        'lokijs', 
        'encoding', 
        'bufferutil', 
        'utf-8-validate',
        'thread-stream',
        'pino',
        'tap',
        'why-is-node-running',
        'desm',
        'fastbench',
        'pino-elasticsearch',
        '@coinbase/wallet-sdk',
        '@react-native-async-storage/async-storage',
        '@walletconnect/core',
        '@walletconnect/sign-client',
        '@walletconnect/ethereum-provider'
      );
    }

    // Ignore test files and problematic patterns
    config.module.rules.push({
      test: /node_modules\/thread-stream\/(test|bench)/,
      use: 'ignore-loader'
    });
    
    config.module.rules.push({
      test: /\.(test|spec)\.(js|mjs|ts)$/,
      use: 'ignore-loader'
    });
    
    config.module.rules.push({
      test: /\/(test|tests)\//,
      use: 'ignore-loader'
    });
    
    config.module.rules.push({
      test: /\.(sh|yml|yaml)$/,
      use: 'ignore-loader'
    });
    
    config.module.rules.push({
      test: /\/LICENSE$/,
      use: 'ignore-loader'
    });

    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
      };
    } else {
      // Mock browser globals for SSR
      config.resolve.alias = {
        ...config.resolve.alias,
        'indexeddb': false,
        'localStorage': false,
        'sessionStorage': false
      };
    }

    return config;
  },
}

export default nextConfig
