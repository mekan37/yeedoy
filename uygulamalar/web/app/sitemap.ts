import type { MetadataRoute } from 'next';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const revalidate = 3600;

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/ğ/g, 'g')
    .replace(/ş/g, 's')
    .replace(/ı/g, 'i')
    .replace(/ç/g, 'c')
    .replace(/ö/g, 'o')
    .replace(/ü/g, 'u')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '');
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const now = new Date();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${siteUrl}/`, lastModified: now, changeFrequency: 'daily', priority: 1.0 },
    { url: `${siteUrl}/kesif`, lastModified: now, changeFrequency: 'daily', priority: 0.9 },
    { url: `${siteUrl}/en-iyiler`, lastModified: now, changeFrequency: 'daily', priority: 0.8 },
    { url: `${siteUrl}/akis`, lastModified: now, changeFrequency: 'daily', priority: 0.7 },
    { url: `${siteUrl}/liderler`, lastModified: now, changeFrequency: 'weekly', priority: 0.6 },
    { url: `${siteUrl}/gurmeler`, lastModified: now, changeFrequency: 'weekly', priority: 0.6 },
    { url: `${siteUrl}/arama`, lastModified: now, changeFrequency: 'weekly', priority: 0.5 },
    { url: `${siteUrl}/askida`, lastModified: now, changeFrequency: 'weekly', priority: 0.5 },
    { url: `${siteUrl}/fiyat-endeksi`, lastModified: now, changeFrequency: 'monthly', priority: 0.7 },
    { url: `${siteUrl}/yasal`, lastModified: now, changeFrequency: 'yearly', priority: 0.3 },
  ];

  let isletmeRoutes: MetadataRoute.Sitemap = [];
  let businessRoutes: MetadataRoute.Sitemap = [];
  let menuRoutes: MetadataRoute.Sitemap = [];
  let cityRoutes: MetadataRoute.Sitemap = [];
  let districtRoutes: MetadataRoute.Sitemap = [];
  let categoryRoutes: MetadataRoute.Sitemap = [];

  try {
    const supabase = await createSupabaseServerClient();

    // İşletme detay sayfaları — /isletme/[slug] (SEO öncelikli)
    const { data: businesses } = await (supabase as any)
      .from('businesses')
      .select('slug, updated_at, created_at')
      .eq('is_active', true)
      .not('slug', 'is', null)
      .order('created_at', { ascending: false })
      .range(0, 2499) as { data: Array<{ slug: string; updated_at: string | null; created_at: string | null }> | null };

    if (businesses) {
      isletmeRoutes = businesses.map((b) => ({
        url: `${siteUrl}/isletme/${b.slug}`,
        lastModified: b.updated_at ? new Date(b.updated_at) : b.created_at ? new Date(b.created_at) : now,
        changeFrequency: 'weekly' as const,
        priority: 0.85,
      }));
      // /b/[slug] — QR alias sayfaları
      businessRoutes = businesses.map((b) => ({
        url: `${siteUrl}/b/${b.slug}`,
        lastModified: b.updated_at ? new Date(b.updated_at) : b.created_at ? new Date(b.created_at) : now,
        changeFrequency: 'weekly' as const,
        priority: 0.8,
      }));
    }

    // Menü sayfaları — /m/[slug]
    const menuLimit = Math.max(0, 5000 - (businesses?.length ?? 0));
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

    // Şehir/ilçe/kategori listesi sayfaları — /[sehir], /[sehir]/[ilce], /[sehir]/[ilce]/[kategori]
    const { data: combos } = await (supabase as any)
      .from('businesses')
      .select('city, district, category')
      .eq('is_active', true)
      .not('city', 'is', null)
      .not('district', 'is', null)
      .not('category', 'is', null)
      .order('city')
      .range(0, 4999) as { data: Array<{ city: string; district: string; category: string }> | null };

    if (combos) {
      const seenCity = new Set<string>();
      const seenDistrict = new Set<string>();
      const seenCategory = new Set<string>();

      for (const row of combos) {
        const cs = slugify(row.city);
        const ds = slugify(row.district);
        const ks = slugify(row.category);
        if (!cs || !ds || !ks) continue;

        // /[sehir] — city hub
        if (!seenCity.has(cs)) {
          seenCity.add(cs);
          cityRoutes.push({
            url: `${siteUrl}/${cs}`,
            lastModified: now,
            changeFrequency: 'daily' as const,
            priority: 0.85,
          });
        }

        // /[sehir]/[ilce] — district listing
        const districtKey = `${cs}||${ds}`;
        if (!seenDistrict.has(districtKey)) {
          seenDistrict.add(districtKey);
          districtRoutes.push({
            url: `${siteUrl}/${cs}/${ds}`,
            lastModified: now,
            changeFrequency: 'daily' as const,
            priority: 0.82,
          });
        }

        // /[sehir]/[ilce]/[kategori] — category listing
        const categoryKey = `${cs}||${ds}||${ks}`;
        if (!seenCategory.has(categoryKey)) {
          seenCategory.add(categoryKey);
          categoryRoutes.push({
            url: `${siteUrl}/${cs}/${ds}/${ks}`,
            lastModified: now,
            changeFrequency: 'daily' as const,
            priority: 0.8,
          });
        }
      }
    }
  } catch {
    // DB hatasında sadece statik rotaları döndür
  }

  return [...staticRoutes, ...isletmeRoutes, ...businessRoutes, ...menuRoutes, ...cityRoutes, ...districtRoutes, ...categoryRoutes];
}
