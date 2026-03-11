import type { MetadataRoute } from 'next';
import { appConfig } from '@/src/lib/config';

export default function sitemap(): MetadataRoute.Sitemap {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const now = new Date();

  return [
    {
      url: `${siteUrl}/`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${siteUrl}/login`,
      lastModified: now,
      changeFrequency: 'monthly',
      priority: 0.2,
    },
  ];
}
