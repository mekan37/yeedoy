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
    // Görsel URL'leri güncellemede versiyon query param'ı alır (bkz. medya-adresi.ts
    // appendMediaVersion), bu yüzden uzun TTL bayat görsel riski taşımaz.
    minimumCacheTTL: 604800, // 7 gün
  },
  // ── Flutter Web panel backwards-compat redirects ─────────────────────────
  // Old Flutter Web URLs that users may have bookmarked → new Next.js paths.
  // All permanent (308) so search engines update their indices.
  async redirects() {
    return [
      // Turkish-language auth aliases used by the Flutter panel
      { source: '/isletme-giris', destination: '/giris', permanent: true },
      { source: '/isletme-kayit', destination: '/giris', permanent: true },
      // Flutter used /owner/qr/design, Next.js consolidates to /owner/qr
      { source: '/owner/qr/design', destination: '/owner/qr', permanent: true },
      // QR Studio / short QR-scan links — İngilizce ikizler Türkçe kanoniğe taşındı.
      // /q/:code fiziksel olarak basılmış QR kodlarında olabilir — SİLİNMEDİ, kalıcı yönlendirildi.
      { source: '/qr/:businessId', destination: '/karekod/:businessId', permanent: true },
      { source: '/q/:code', destination: '/kod/:code', permanent: true },
      // Flutter editor push-routes → Next.js segment-based editor paths
      // (matches /owner/menu/editor?menuId=xxx and similar)
      { source: '/owner/menu/editor', destination: '/owner/menus', permanent: true },
      { source: '/owner/menu/section-editor', destination: '/owner/menus', permanent: true },
      // Owner paneli Türkçeleştirme — eski İngilizce path'lerden yenilerine
      { source: '/owner', destination: '/sahip', permanent: true },
      { source: '/owner/login', destination: '/giris', permanent: true },
      { source: '/owner/dashboard', destination: '/sahip/gosterge-panosu', permanent: true },
      { source: '/owner/businesses', destination: '/sahip/isletmeler', permanent: true },
      { source: '/owner/businesses/new', destination: '/sahip/isletmeler/yeni', permanent: true },
      { source: '/owner/businesses/submissions', destination: '/sahip/isletmeler/basvurular', permanent: true },
      { source: '/owner/businesses/:id', destination: '/sahip/isletmeler/:id', permanent: true },
      { source: '/owner/menus', destination: '/sahip/menuler', permanent: true },
      { source: '/owner/menus/:menuId', destination: '/sahip/menuler/:menuId', permanent: true },
      { source: '/owner/menus/:menuId/edit', destination: '/sahip/menuler/:menuId/duzenle', permanent: true },
      { source: '/owner/menu/translations', destination: '/sahip/menu/ceviriler', permanent: true },
      { source: '/owner/photos', destination: '/sahip/fotograflar', permanent: true },
      { source: '/owner/reviews', destination: '/sahip/yorumlar', permanent: true },
      { source: '/owner/reservations', destination: '/sahip/rezervasyonlar', permanent: true },
      { source: '/owner/analytics', destination: '/sahip/analitik', permanent: true },
      { source: '/owner/marketing', destination: '/sahip/pazarlama', permanent: true },
      { source: '/owner/marketing/:path*', destination: '/sahip/pazarlama/:path*', permanent: true },
      { source: '/owner/qr', destination: '/sahip/karekod', permanent: true },
      { source: '/owner/notifications', destination: '/sahip/bildirimler', permanent: true },
      { source: '/owner/settings', destination: '/sahip/ayarlar', permanent: true },
      { source: '/owner/settings/domain', destination: '/sahip/ayarlar/alan-adi', permanent: true },
      { source: '/owner/settings/hours', destination: '/sahip/ayarlar/saatler', permanent: true },
      { source: '/owner/ai-analysis', destination: '/sahip/yapay-zeka-analizi', permanent: true },
      { source: '/owner/team', destination: '/sahip/ekip', permanent: true },
      { source: '/owner/trash', destination: '/sahip/cop-kutusu', permanent: true },
      { source: '/owner/price-suggestions', destination: '/sahip/fiyat-onerileri', permanent: true },
      { source: '/owner/growth', destination: '/sahip/buyume', permanent: true },
      { source: '/owner/audit', destination: '/sahip/denetim-kaydi', permanent: true },
      { source: '/owner/activity', destination: '/sahip/denetim-kaydi', permanent: true },
      { source: '/owner/requests', destination: '/sahip/istekler', permanent: true },
      { source: '/owner/suspended', destination: '/sahip/askiya-alinanlar', permanent: true },
      { source: '/owner/pricing', destination: '/sahip/fiyatlandirma', permanent: true },
      { source: '/owner/onboarding', destination: '/sahip/baslangic', permanent: true },
      // Admin paneli Türkçeleştirme — eski İngilizce path'lerden yenilerine
      { source: '/admin', destination: '/yonetici', permanent: true },
      { source: '/admin/dashboard', destination: '/yonetici/gosterge-panosu', permanent: true },
      { source: '/admin/analytics', destination: '/yonetici/analitik', permanent: true },
      { source: '/admin/appeals', destination: '/yonetici/itirazlar', permanent: true },
      { source: '/admin/audit', destination: '/yonetici/denetim-kaydi', permanent: true },
      { source: '/admin/b2b-exports', destination: '/yonetici/b2b-dis-aktarim', permanent: true },
      { source: '/admin/business-submissions', destination: '/yonetici/isletme-basvurulari', permanent: true },
      { source: '/admin/businesses', destination: '/yonetici/isletmeler', permanent: true },
      { source: '/admin/businesses/new', destination: '/yonetici/isletmeler/yeni', permanent: true },
      { source: '/admin/businesses/:id/menus/new', destination: '/yonetici/isletmeler/:id/menuler/yeni', permanent: true },
      { source: '/admin/chains', destination: '/yonetici/zincirler', permanent: true },
      { source: '/admin/chains/:id', destination: '/yonetici/zincirler/:id', permanent: true },
      { source: '/admin/claims', destination: '/yonetici/itirazlar/claims', permanent: true },
      { source: '/admin/dev-tools', destination: '/yonetici/gelistirme-araclari', permanent: true },
      { source: '/admin/group-requests', destination: '/yonetici/grup-istekleri', permanent: true },
      { source: '/admin/growth', destination: '/yonetici/buyume', permanent: true },
      { source: '/admin/incidents', destination: '/yonetici/olaylar', permanent: true },
      { source: '/admin/locations', destination: '/yonetici/konumlar', permanent: true },
      { source: '/admin/observability', destination: '/yonetici/gozlemlenebilirlik', permanent: true },
      { source: '/admin/price-suggestions', destination: '/yonetici/fiyat-onerileri', permanent: true },
      { source: '/admin/queue', destination: '/yonetici/kuyruk', permanent: true },
      { source: '/admin/receipt-submissions', destination: '/yonetici/fis-basvurulari', permanent: true },
      { source: '/admin/reports', destination: '/yonetici/raporlar', permanent: true },
      { source: '/admin/reviews', destination: '/yonetici/yorumlar', permanent: true },
      { source: '/admin/roles', destination: '/yonetici/roller', permanent: true },
      { source: '/admin/search', destination: '/yonetici/arama', permanent: true },
      { source: '/admin/sponsorship-leads', destination: '/yonetici/sponsor-adaylari', permanent: true },
      { source: '/admin/sponsorship-packages', destination: '/yonetici/sponsor-paketleri', permanent: true },
      { source: '/admin/sponsorships', destination: '/yonetici/sponsorluklar', permanent: true },
      { source: '/admin/suggestions', destination: '/yonetici/oneriler', permanent: true },
      { source: '/admin/suspended', destination: '/yonetici/askiya-alinanlar', permanent: true },
      { source: '/admin/table-feedback', destination: '/yonetici/masa-geri-bildirimleri', permanent: true },
      { source: '/admin/temp-uploads', destination: '/yonetici/gecici-yuklemeler', permanent: true },
      { source: '/admin/trash', destination: '/yonetici/cop-kutusu', permanent: true },
      { source: '/admin/users', destination: '/yonetici/kullanicilar', permanent: true },
      { source: '/admin/users/:id', destination: '/yonetici/kullanicilar/:id', permanent: true },
      { source: '/admin/verified', destination: '/yonetici/isletmeler?status=verified', permanent: true },
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
