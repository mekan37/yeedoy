import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const revalidate = 300;

export const metadata: Metadata = {
  title: 'En İyi İşletmeler | Yeedoy',
  description: "Yeedoy'un en çok incelenen ve en yüksek puanlı işletmeleri",
};

type Props = { searchParams: Promise<{ city?: string; category?: string }> };

type BizRow = {
  id: string;
  name: string;
  slug: string;
  category: string;
  city: string | null;
  logo_url: string | null;
  is_verified: boolean;
  review_count: number | null;
  average_rating: number | null;
};

const CATEGORIES = [
  'Restoran',
  'Kafe',
  'Pastane',
  'Fast Food',
  'Bar',
  'Fırın',
];

export default async function TopPage({ searchParams }: Props) {
  const { city = '', category = '' } = await searchParams;
  const supabase = await createSupabaseServerClient();

  // Try ordering by review_count + average_rating; gracefully fall back to created_at
  let list: BizRow[] = [];
  let usedFallback = false;

  try {
    let query = (supabase as any)
      .from('businesses')
      .select('id, name, slug, category, city, logo_url, is_verified, review_count, average_rating')
      .eq('is_active', true)
      .order('review_count', { ascending: false, nullsFirst: false })
      .order('average_rating', { ascending: false, nullsFirst: false })
      .limit(50);

    if (city) query = query.eq('city', city);
    if (category) query = query.eq('category', category);

    const { data, error } = await query as { data: BizRow[] | null; error: { message?: string } | null };

    if (error) {
      // Columns may not exist — fall back to name ordering
      usedFallback = true;
      let fallbackQuery = (supabase as any)
        .from('businesses')
        .select('id, name, slug, category, city, logo_url, is_verified, review_count, average_rating')
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(50);
      if (city) fallbackQuery = fallbackQuery.eq('city', city);
      if (category) fallbackQuery = fallbackQuery.eq('category', category);
      const { data: fallbackData } = await fallbackQuery as { data: BizRow[] | null };
      list = fallbackData ?? [];
    } else {
      list = data ?? [];
    }
  } catch {
    list = [];
  }

  const hasFilters = Boolean(city || category);

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-10">

        {/* Header */}
        <h1 className="mb-1 text-3xl font-[900] text-textStrong">En İyi İşletmeler</h1>
        <p className="mb-6 text-sm text-muted">
          {usedFallback
            ? 'Yeedoy\'da kayıtlı işletmeler'
            : 'En çok incelenen ve en yüksek puanlı işletmeler'}
        </p>

        {/* Category chips */}
        <div className="mb-4 flex flex-wrap gap-2">
          <Link
            href={city ? `?city=${encodeURIComponent(city)}` : '/top'}
            className={`rounded-full border px-3 py-1 text-xs font-[700] transition-colors cursor-pointer ${
              !category
                ? 'border-primary bg-primary text-white'
                : 'border-border bg-card text-textStrong hover:border-primary/40'
            }`}
          >
            Tümü
          </Link>
          {CATEGORIES.map((cat) => (
            <Link
              key={cat}
              href={`?category=${encodeURIComponent(cat)}${city ? `&city=${encodeURIComponent(city)}` : ''}`}
              className={`rounded-full border px-3 py-1 text-xs font-[700] transition-colors cursor-pointer ${
                category === cat
                  ? 'border-primary bg-primary text-white'
                  : 'border-border bg-card text-textStrong hover:border-primary/40'
              }`}
            >
              {cat}
            </Link>
          ))}
        </div>

        {/* City + category form */}
        <form method="get" className="mb-6 flex flex-wrap gap-3">
          <input
            name="city"
            defaultValue={city}
            placeholder="Şehir filtrele"
            className="rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 w-40"
          />
          <input
            name="category"
            defaultValue={category}
            placeholder="Kategori"
            className="rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 w-40"
          />
          <button
            type="submit"
            className="rounded-xl bg-primary px-5 py-2 text-sm font-[700] text-white cursor-pointer hover:opacity-90 transition-opacity"
          >
            Filtrele
          </button>
          {hasFilters && (
            <Link
              href="/top"
              className="rounded-xl border border-border bg-card px-4 py-2 text-sm font-[700] text-muted hover:text-textStrong transition-colors cursor-pointer"
            >
              Temizle
            </Link>
          )}
        </form>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Sonuç bulunamadı</p>
            {hasFilters && (
              <Link href="/top" className="text-sm text-primary hover:underline cursor-pointer">
                Filtreleri temizle →
              </Link>
            )}
          </div>
        ) : (
          <ol className="flex flex-col gap-3">
            {list.map((biz, i) => {
              const rank = i + 1;
              const rankColor =
                rank === 1
                  ? 'text-yellow-500'
                  : rank === 2
                  ? 'text-slate-400'
                  : rank === 3
                  ? 'text-amber-600'
                  : 'text-muted';

              return (
                <li key={biz.id}>
                  <Link
                    href={`/b/${biz.slug}`}
                    className="flex items-center gap-4 rounded-2xl border border-border bg-card p-4 transition-colors hover:border-primary/30 cursor-pointer"
                  >
                    {/* Rank */}
                    <span className={`w-8 shrink-0 text-center text-lg font-[900] ${rankColor}`}>
                      #{rank}
                    </span>

                    {/* Logo */}
                    <div className="h-12 w-12 shrink-0 overflow-hidden rounded-xl border border-border bg-bg flex items-center justify-center">
                      {biz.logo_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img loading="lazy" src={biz.logo_url} alt={biz.name} className="h-full w-full object-cover" />
                      ) : (
                        <span className="text-lg font-[900] text-muted">{biz.name[0]}</span>
                      )}
                    </div>

                    {/* Info */}
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-1.5">
                        <span className="truncate font-[700] text-textStrong">{biz.name}</span>
                        {biz.is_verified && (
                          <span className="shrink-0 rounded-full bg-green-50 px-1.5 py-0.5 text-[10px] font-[700] text-green-700">
                            ✓ Doğrulandı
                          </span>
                        )}
                      </div>
                      <p className="mt-0.5 text-[12px] text-muted">
                        {biz.category}{biz.city ? ` · ${biz.city}` : ''}
                      </p>
                      {(biz.review_count != null || biz.average_rating != null) && (
                        <div className="mt-1 flex items-center gap-2">
                          {biz.average_rating != null && (
                            <span className="flex items-center gap-0.5 text-[12px] font-[700] text-textStrong">
                              ★ {biz.average_rating.toFixed(1)}
                            </span>
                          )}
                          {biz.review_count != null && (
                            <span className="text-[12px] text-muted">
                              {biz.review_count} yorum
                            </span>
                          )}
                        </div>
                      )}
                    </div>

                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted">
                      <path d="M9 18l6-6-6-6" />
                    </svg>
                  </Link>
                </li>
              );
            })}
          </ol>
        )}
      </div>
    </main>
  );
}
