import type { MetadataRoute } from 'next';
import { appConfig } from '@/src/lib/ayarlar';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { BUSINESS_CHUNK_SIZE, getSitemapBusinessChunkCount } from '@/src/lib/veri/sitemap-parcalari';

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

// id 0: statik sayfalar + şehir/ilçe/kategori hub sayfaları (küçük, sabit boyutlu).
// id 1..N: işletme parçaları — her biri en fazla BUSINESS_CHUNK_SIZE işletmeyi
// (/isletme/[slug] + /m/[slug] olmak üzere 2 URL/işletme) kapsar. Toplam işletme
// sayısı Google'ın 50.000 URL/dosya sınırını çoktan aştığı için (42K+ işletme),
// tek dosyaya sığdırmak yerine generateSitemaps ile birden fazla dosyaya bölünür.
export async function generateSitemaps() {
  const businessChunks = await getSitemapBusinessChunkCount();
  return Array.from({ length: businessChunks + 1 }, (_, i) => ({ id: i }));
}

async function buildStaticAndGeoSitemap(): Promise<MetadataRoute.Sitemap> {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const now = new Date();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${siteUrl}/`, lastModified: now, changeFrequency: 'daily', priority: 1.0 },
    { url: `${siteUrl}/kesif`, lastModified: now, changeFrequency: 'daily', priority: 0.9 },
    { url: `${siteUrl}/en-iyiler`, lastModified: now, changeFrequency: 'daily', priority: 0.8 },
    { url: `${siteUrl}/liderler`, lastModified: now, changeFrequency: 'weekly', priority: 0.6 },
    { url: `${siteUrl}/arama`, lastModified: now, changeFrequency: 'weekly', priority: 0.5 },
    { url: `${siteUrl}/askida`, lastModified: now, changeFrequency: 'weekly', priority: 0.5 },
    { url: `${siteUrl}/fiyat-endeksi`, lastModified: now, changeFrequency: 'monthly', priority: 0.7 },
    { url: `${siteUrl}/yasal`, lastModified: now, changeFrequency: 'yearly', priority: 0.3 },
  ];

  const cityRoutes: MetadataRoute.Sitemap = [];
  const districtRoutes: MetadataRoute.Sitemap = [];
  const categoryRoutes: MetadataRoute.Sitemap = [];

  try {
    const supabase = await createSupabaseServerClient();
    const seenCity = new Set<string>();
    const seenDistrict = new Set<string>();
    const seenCategory = new Set<string>();

    // ÖNEMLİ: şehir/ilçe/kategori kombinasyonlarını tekilleştirmeden önce TÜM
    // satırları sayfalayarak çekiyoruz (sabit bir range() sınırı koyup sonra
    // tekilleştirmek, alfabetik olarak önce gelen tek bir şehir — örn. Adana —
    // o sınırı tek başına doldurursa diğer TÜM şehirlerin sitemap'ten tamamen
    // dışarıda kalmasına yol açıyordu).
    const PAGE = 1000;
    let from = 0;
    for (;;) {
      const { data: combos } = await (supabase as any)
        .from('businesses')
        .select('city, district, category')
        .eq('is_active', true)
        .not('city', 'is', null)
        .not('district', 'is', null)
        .not('category', 'is', null)
        .order('id', { ascending: true })
        .range(from, from + PAGE - 1) as { data: Array<{ city: string; district: string; category: string }> | null };

      if (!combos || combos.length === 0) break;

      for (const row of combos) {
        const cs = slugify(row.city);
        const ds = slugify(row.district);
        const ks = slugify(row.category);
        if (!cs || !ds || !ks) continue;

        if (!seenCity.has(cs)) {
          seenCity.add(cs);
          cityRoutes.push({ url: `${siteUrl}/${cs}`, lastModified: now, changeFrequency: 'daily', priority: 0.85 });
        }

        const districtKey = `${cs}||${ds}`;
        if (!seenDistrict.has(districtKey)) {
          seenDistrict.add(districtKey);
          districtRoutes.push({ url: `${siteUrl}/${cs}/${ds}`, lastModified: now, changeFrequency: 'daily', priority: 0.82 });
        }

        const categoryKey = `${districtKey}||${ks}`;
        if (!seenCategory.has(categoryKey)) {
          seenCategory.add(categoryKey);
          categoryRoutes.push({ url: `${siteUrl}/${cs}/${ds}/${ks}`, lastModified: now, changeFrequency: 'daily', priority: 0.8 });
        }
      }

      if (combos.length < PAGE) break;
      from += PAGE;
    }
  } catch {
    // DB hatasında sadece statik rotalar döner.
  }

  return [...staticRoutes, ...cityRoutes, ...districtRoutes, ...categoryRoutes];
}

async function buildBusinessChunkSitemap(chunkIndex: number): Promise<MetadataRoute.Sitemap> {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const now = new Date();
  const from = chunkIndex * BUSINESS_CHUNK_SIZE;
  const to = from + BUSINESS_CHUNK_SIZE - 1;

  try {
    const supabase = await createSupabaseServerClient();
    const routes: MetadataRoute.Sitemap = [];

    // PostgREST varsayılan olarak tek istekte en fazla 1000 satır döner (db-max-rows) —
    // .range(from, to) BUSINESS_CHUNK_SIZE (20.000) kadar geniş olsa da, sunucu bunu
    // sessizce 1000'e kırpıyor. Bu yüzden parça penceresi (from..to) içinde de
    // PAGE'er PAGE'er sayfalamak gerekiyor.
    const PAGE = 1000;
    let pageFrom = from;
    for (;;) {
      const pageTo = Math.min(pageFrom + PAGE - 1, to);
      if (pageFrom > to) break;

      const { data: businesses } = await (supabase as any)
        .from('businesses')
        .select('slug, created_at')
        .eq('is_active', true)
        .not('slug', 'is', null)
        .order('created_at', { ascending: false })
        .order('id', { ascending: true })
        .range(pageFrom, pageTo) as { data: Array<{ slug: string; created_at: string | null }> | null };

      if (!businesses || businesses.length === 0) break;

      for (const b of businesses) {
        const lastModified = b.created_at ? new Date(b.created_at) : now;
        // /b/[slug] (QR alias sayfası) kasıtlı olarak sitemap'e dahil edilmiyor —
        // canonical URL değil, /isletme/[slug]'ın kopyası; sitemap'e sadece
        // canonical URL'ler girmeli.
        routes.push({ url: `${siteUrl}/isletme/${b.slug}`, lastModified, changeFrequency: 'weekly', priority: 0.85 });
        routes.push({ url: `${siteUrl}/m/${b.slug}`, lastModified, changeFrequency: 'weekly', priority: 0.7 });
      }

      if (businesses.length < PAGE) break;
      pageFrom += PAGE;
    }
    return routes;
  } catch {
    return [];
  }
}

export default async function sitemap({ id }: { id: number | Promise<number> }): Promise<MetadataRoute.Sitemap> {
  const resolvedId = Number(await id);
  if (resolvedId === 0) return buildStaticAndGeoSitemap();
  return buildBusinessChunkSitemap(resolvedId - 1);
}
