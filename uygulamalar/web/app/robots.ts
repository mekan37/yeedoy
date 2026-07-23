import type { MetadataRoute } from 'next';
import { appConfig } from '@/src/lib/ayarlar';

export default function robots(): MetadataRoute.Robots {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  return {
    rules: [
      {
        userAgent: '*',
        allow: ['/', '/m/', '/q/', '/kesif', '/en-iyiler', '/isletme/', '/arama'],
        disallow: ['/login', '/qr/', '/api/', '/auth/', '/forbidden', '/admin/', '/owner/', '/sahip/', '/yonetici/'],
      },
    ],
    sitemap: `${siteUrl}/sitemap.xml`,
    host: siteUrl,
  };
}
