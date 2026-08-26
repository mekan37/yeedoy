import { createSupabasePublicClient } from '@/src/lib/taban/acik';

// Google'ın tek sitemap dosyası başına 50.000 URL sınırının altında kalmak için
// güvenlik payı bırakılmış parça boyutu. Her işletme 2 URL üretir
// (/isletme/[slug] + /m/[slug]), yani 20.000 işletme = 40.000 URL/dosya.
export const BUSINESS_CHUNK_SIZE = 20_000;

/**
 * Sitemap için toplam aktif, slug'lı işletme sayısı.
 *
 * Kasıtlı olarak createSupabasePublicClient (cookie'siz) kullanır —
 * createSupabaseServerClient (cookies() gerektirir) burada ÇALIŞMAZ: bu
 * fonksiyon generateSitemaps() içinden çağrılıyor ve Next.js generateSitemaps'i
 * generateStaticParams ile aynı mekanizmayla çalıştırıyor (istek bağlamı/cookie
 * erişimi olmadan) — cookies() çağrısı "used cookies() inside
 * generateStaticParams" hatasıyla patlar.
 */
export async function getSitemapBusinessCount(): Promise<number> {
  const supabase = createSupabasePublicClient();
  const { count } = await (supabase as any)
    .from('businesses')
    .select('id', { count: 'exact', head: true })
    .eq('is_active', true)
    .not('slug', 'is', null);
  return count ?? 0;
}

/** İşletme URL'lerinin kaç ayrı sitemap parçasına bölüneceği (id 0 statik+coğrafi parça, id 1..N işletme parçaları). */
export async function getSitemapBusinessChunkCount(): Promise<number> {
  const count = await getSitemapBusinessCount();
  return Math.max(1, Math.ceil(count / BUSINESS_CHUNK_SIZE));
}
