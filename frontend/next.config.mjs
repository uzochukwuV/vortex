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
      '@coinbase/wallet-sdk'
    );

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
    }

    return config;
  },
}

export default nextConfig
