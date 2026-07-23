import type { MetadataRoute } from 'next';
import { appConfig } from '@/src/lib/ayarlar';

export default function robots(): MetadataRoute.Robots {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  return {
    rules: [
      {
        userAgent: '*',
        allow: ['/', '/m/', '/kod/', '/kesif', '/en-iyiler', '/isletme/', '/arama'],
        disallow: ['/giris', '/karekod/', '/api/', '/auth/', '/forbidden', '/admin/', '/owner/', '/sahip/', '/yonetici/'],
      },
    ],
    sitemap: `${siteUrl}/sitemap.xml`,
    host: siteUrl,
  };
}
