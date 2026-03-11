import path from 'node:path';
import bundleAnalyzer from '@next/bundle-analyzer';

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
});

function toRemotePattern(url) {
  if (!url) return [];

  try {
    const parsed = new URL(url);
    return [
      {
        protocol: parsed.protocol.replace(':', ''),
        hostname: parsed.hostname,
      },
    ];
  } catch {
    return [];
  }
}

const imageRemotePatterns = [
  ...toRemotePattern(process.env.NEXT_PUBLIC_SUPABASE_URL),
  ...toRemotePattern(process.env.NEXT_PUBLIC_SITE_URL),
  {
    protocol: 'http',
    hostname: 'localhost',
  },
  {
    protocol: 'http',
    hostname: '127.0.0.1',
  },
];

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  outputFileTracingRoot: path.join(process.cwd()),
  allowedDevOrigins: ['127.0.0.1'],
  images: {
    remotePatterns: imageRemotePatterns,
    minimumCacheTTL: 60,
  },
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
        ],
      },
      {
        source: '/robots.txt',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400',
          },
        ],
      },
      {
        source: '/sitemap.xml',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400',
          },
        ],
      },
      {
        source: '/api/og',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=0, s-maxage=86400, stale-while-revalidate=604800',
          },
        ],
      },
    ];
  },
};

export default withBundleAnalyzer(nextConfig);
