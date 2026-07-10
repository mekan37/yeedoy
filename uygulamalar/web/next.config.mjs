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
  // İşletme cover/logo URL'leri harici kaynaklara (OSM, FSQ, Unsplash, vb.) işaret edebilir
  {
    protocol: 'https',
    hostname: 'images.unsplash.com',
  },
  {
    protocol: 'https',
    hostname: '*.unsplash.com',
  },
  {
    protocol: 'https',
    hostname: 'fastly.4sqi.net',
  },
  {
    protocol: 'https',
    hostname: '*.googleusercontent.com',
  },
  {
    protocol: 'https',
    hostname: 'lh3.googleusercontent.com',
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
  // ── Flutter Web panel backwards-compat redirects ─────────────────────────
  // Old Flutter Web URLs that users may have bookmarked → new Next.js paths.
  // All permanent (308) so search engines update their indices.
  async redirects() {
    return [
      // Turkish-language auth aliases used by the Flutter panel
      { source: '/isletme-giris', destination: '/login', permanent: true },
      { source: '/isletme-kayit', destination: '/login', permanent: true },
      // Flutter used /owner/qr/design, Next.js consolidates to /owner/qr
      { source: '/owner/qr/design', destination: '/owner/qr', permanent: true },
      // Flutter editor push-routes → Next.js segment-based editor paths
      // (matches /owner/menu/editor?menuId=xxx and similar)
      { source: '/owner/menu/editor', destination: '/owner/menus', permanent: true },
      { source: '/owner/menu/section-editor', destination: '/owner/menus', permanent: true },
    ];
  },
  async headers() {
    const supabaseHost = (() => {
      try { return new URL(process.env.NEXT_PUBLIC_SUPABASE_URL ?? '').hostname; } catch { return '*.supabase.co'; }
    })();

    const isDev = process.env.NODE_ENV === 'development';

    const ContentSecurityPolicy = [
      "default-src 'self'",
      // 'unsafe-eval' is required by Next.js React Fast Refresh in development only.
      // Production builds do not use eval and this directive is omitted there.
      `script-src 'self' 'unsafe-inline'${isDev ? " 'unsafe-eval'" : ''} https://vercel-scripts.com https://va.vercel-scripts.com`,
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' data: https://fonts.gstatic.com",
      "img-src 'self' data: blob: https: http:",
      // blob: worker — MapLibre GL creates its WebGL worker via blob URL
      "worker-src blob:",
      // In development, also allow the local WebSocket HMR connection.
      `connect-src 'self'${isDev ? ' ws://localhost:* ws://127.0.0.1:*' : ''} https://${supabaseHost} wss://${supabaseHost} https://*.supabase.co wss://*.supabase.co https://fonts.googleapis.com https://maps.yeedoy.com https://cdn.jsdelivr.net`,
      "frame-src https://www.openstreetmap.org",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "upgrade-insecure-requests",
    ].join('; ');

    // Embed pages allow framing from any origin (they are designed to be iframed)
    const EmbedCSP = ContentSecurityPolicy.replace("frame-ancestors 'none'", "frame-ancestors *");

    return [
      // Embed viewer: allow iframing from any origin
      {
        source: '/embed/:businessId*',
        headers: [
          { key: 'X-Frame-Options', value: 'ALLOWALL' },
          { key: 'Content-Security-Policy', value: EmbedCSP },
        ],
      },
      {
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains',
          },
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
          {
            key: 'Content-Security-Policy',
            value: ContentSecurityPolicy,
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(self), payment=()',
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
