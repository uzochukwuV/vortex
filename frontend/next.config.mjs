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
  webpack: (config, { isServer, webpack }) => {
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

    // Fix for viem test module exports in Vercel
    config.plugins.push(
      new webpack.NormalModuleReplacementPlugin(
        /viem\/_esm\/actions\/test\/.*/,
        (resource) => {
          resource.request = resource.request.replace(/.*/, 'node:stream');
        }
      )
    );

    // Additional aliases to prevent test imports
    config.resolve.alias = {
      ...config.resolve.alias,
      'viem/actions/test/dropTransaction': false,
      'viem/actions/test/dumpState': false,
      'viem/actions/test/getAutomine': false,
      'viem/actions/test/getTxpoolContent': false,
      'viem/actions/test/getTxpoolStatus': false,
    };

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

    // Externalize viem test actions to prevent bundling
    config.externals = [
      ...config.externals,
      ({ request }, callback) => {
        if (/viem\/_esm\/actions\/test\//.test(request)) {
          return callback(null, 'commonjs ' + request);
        }
        callback();
      },
    ];

    return config;
  },
}

export default nextConfig
