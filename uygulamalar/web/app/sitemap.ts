import type { MetadataRoute } from 'next';
import { appConfig } from '@/src/lib/config';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const revalidate = 3600; // regenerate every hour

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const now = new Date();

  // Only indexable public routes — login/forgot-password carry noindex and must not appear.
  const staticRoutes: MetadataRoute.Sitemap = [
    {
      url: `${siteUrl}/`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 1.0,
    },
    {
      url: `${siteUrl}/discover`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 0.9,
    },
    {
      url: `${siteUrl}/top`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 0.8,
    },
    {
      url: `${siteUrl}/feed`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 0.7,
    },
    {
      url: `${siteUrl}/heroes`,
      lastModified: now,
      changeFrequency: 'weekly',
      priority: 0.6,
    },
    {
      url: `${siteUrl}/suggest`,
      lastModified: now,
      changeFrequency: 'monthly',
      priority: 0.5,
    },
    {
      url: `${siteUrl}/legal`,
      lastModified: now,
      changeFrequency: 'yearly',
      priority: 0.3,
    },
  ];

  let businessRoutes: MetadataRoute.Sitemap = [];
  let isletmeRoutes: MetadataRoute.Sitemap = [];
  let menuRoutes: MetadataRoute.Sitemap = [];

  try {
    const supabase = await createSupabaseServerClient();

    // Fetch active businesses — cap at 5000 total between /b/ and /m/
    const { data: businesses } = await (supabase as any)
      .from('businesses')
      .select('slug, updated_at, created_at')
      .eq('is_active', true)
      .not('slug', 'is', null)
      .order('created_at', { ascending: false })
      .range(0, 2499) as { data: Array<{ slug: string; updated_at: string | null; created_at: string | null }> | null };

    if (businesses) {
      businessRoutes = businesses.map((b) => ({
        url: `${siteUrl}/b/${b.slug}`,
        lastModified: b.updated_at ? new Date(b.updated_at) : b.created_at ? new Date(b.created_at) : now,
        changeFrequency: 'weekly' as const,
        priority: 0.8,
      }));
      // /isletme/[slug] — marketplace business detail pages (higher priority, SEO-rich)
      isletmeRoutes = businesses.map((b) => ({
        url: `${siteUrl}/isletme/${b.slug}`,
        lastModified: b.updated_at ? new Date(b.updated_at) : b.created_at ? new Date(b.created_at) : now,
        changeFrequency: 'weekly' as const,
        priority: 0.85,
      }));
    }

    // Fetch published menus — cap remaining budget to keep total dynamic entries <= 5000
    const menuLimit = 5000 - (businesses?.length ?? 0);
    if (menuLimit > 0) {
      const { data: menus } = await (supabase as any)
        .from('menus')
        .select('slug, updated_at, created_at')
        .eq('status', 'published')
        .not('slug', 'is', null)
        .order('created_at', { ascending: false })
        .range(0, menuLimit - 1) as { data: Array<{ slug: string; updated_at: string | null; created_at: string | null }> | null };

      if (menus) {
        menuRoutes = menus.map((m) => ({
          url: `${siteUrl}/m/${m.slug}`,
          lastModified: m.updated_at ? new Date(m.updated_at) : m.created_at ? new Date(m.created_at) : now,
          changeFrequency: 'weekly' as const,
          priority: 0.7,
        }));
      }
    }
  } catch {
    // Return static routes only if DB fetch fails
  }

  return [...staticRoutes, ...isletmeRoutes, ...businessRoutes, ...menuRoutes];
}
