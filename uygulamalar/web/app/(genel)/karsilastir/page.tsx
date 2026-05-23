import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export const revalidate = 300;

export const metadata: Metadata = {
  title: 'İşletme Karşılaştır | Yeedoy',
  description: 'İki işletmeyi fiyat, puan ve yorumlarla yan yana karşılaştır',
};

type BusinessRow = {
  id: string; name: string; slug: string; category: string | null;
  city: string | null; district: string | null; phone: string | null;
  description: string | null; is_verified: boolean | null; logo_url: string | null;
  avgRating: number | null; reviewCount: number | null; medianPrice: number | null;
};

function Winner({ a, b, higherBetter = true }: { a: number | null; b: number | null; higherBetter?: boolean }) {
  if (a == null && b == null) return null;
  if (a == null || b == null) return null;
  if (a === b) return null;
  const aWins = higherBetter ? a > b : a < b;
  return (
    <span className={`ml-1.5 inline-flex items-center rounded-full px-1.5 py-0.5 text-[10px] font-[900] ${aWins ? 'bg-success/15 text-success' : 'invisible'}`}>
      {aWins ? '✓ daha iyi' : ''}
    </span>
  );
}

function WinnerB({ a, b, higherBetter = true }: { a: number | null; b: number | null; higherBetter?: boolean }) {
  if (a == null && b == null) return null;
  if (a == null || b == null) return null;
  if (a === b) return null;
  const bWins = higherBetter ? b > a : b < a;
  return (
    <span className={`ml-1.5 inline-flex items-center rounded-full px-1.5 py-0.5 text-[10px] font-[900] ${bWins ? 'bg-success/15 text-success' : 'invisible'}`}>
      {bWins ? '✓ daha iyi' : ''}
    </span>
  );
}

export default async function ComparePage({ searchParams }: { searchParams: Promise<{ a?: string; b?: string }> }) {
  const { a, b } = await searchParams;

  if (!a || !b) {
    return (
      <main className="min-h-screen bg-bg">
        <div className="mx-auto max-w-xl px-4 py-12">
          <h1 className="mb-2 text-2xl font-[900] text-textStrong">İki İşletmeyi Karşılaştır</h1>
          <p className="mb-8 text-sm text-muted">Puan, fiyat ve yorumları yan yana görün.</p>
          <form method="get" className="flex flex-col gap-4">
            {[
              { id: 'a', label: '1. İşletme', placeholder: 'ör: bistro-moda', def: a },
              { id: 'b', label: '2. İşletme', placeholder: 'ör: kahve-atelier', def: b },
            ].map(({ id, label, placeholder, def }) => (
              <div key={id} className="flex flex-col gap-1.5">
                <label htmlFor={id} className="text-sm font-[700] text-textStrong">{label}</label>
                <input id={id} name={id} type="text" placeholder={placeholder} defaultValue={def ?? ''}
                  className="rounded-2xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
              </div>
            ))}
            <button type="submit"
              className="min-h-[52px] rounded-2xl text-base font-[900] text-white"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
              Karşılaştır
            </button>
          </form>
        </div>
      </main>
    );
  }

  const supabase = createSupabasePublicClient();
  const { data: rawBiz } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug, category, city, district, phone, description, is_verified, logo_url')
    .in('slug', [a, b]) as { data: Omit<BusinessRow, 'avgRating' | 'reviewCount' | 'medianPrice'>[] | null };

  const bizList = rawBiz ?? [];
  const bizABase = bizList.find((biz) => biz.slug === a) ?? null;
  const bizBBase = bizList.find((biz) => biz.slug === b) ?? null;

  // Enrich with ratings and prices
  async function enrich(biz: Omit<BusinessRow, 'avgRating' | 'reviewCount' | 'medianPrice'> | null): Promise<BusinessRow | null> {
    if (!biz) return null;
    const [reviewRes, priceRes] = await Promise.all([
      (supabase as any)
        .from('business_reviews')
        .select('rating')
        .eq('business_id', biz.id)
        .eq('is_visible', true) as Promise<{ data: { rating: number }[] | null }>,
      (supabase as any)
        .from('regional_price_index')
        .select('median_price_cents')
        .eq('business_id', biz.id)
        .maybeSingle() as Promise<{ data: { median_price_cents: number } | null }>,
    ]).catch(() => [{ data: null }, { data: null }] as const);

    const ratings = reviewRes.data ?? [];
    const avgRating = ratings.length > 0
      ? ratings.reduce((s, r) => s + Number(r.rating), 0) / ratings.length
      : null;

    return {
      ...biz,
      avgRating: avgRating ? Math.round(avgRating * 10) / 10 : null,
      reviewCount: ratings.length > 0 ? ratings.length : null,
      medianPrice: priceRes.data?.median_price_cents ?? null,
    };
  }

  const [bizA, bizB] = await Promise.all([enrich(bizABase), enrich(bizBBase)]);

  function fmtPrice(cents: number | null) {
    if (!cents) return null;
    return `₺${(cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 0 })}`;
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-4xl px-4 py-10">
        <div className="mb-6 flex items-center gap-4">
          <h1 className="text-2xl font-[900] text-textStrong">İşletme Karşılaştır</h1>
          <Link href="/karsilastir" className="ml-auto shrink-0 text-sm font-[700] text-primary hover:underline">
            Yeniden ara
          </Link>
        </div>

        {!bizA && !bizB ? (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center">
            <p className="font-[900] text-textStrong">İşletme bulunamadı</p>
            <Link href="/karsilastir" className="mt-4 inline-block text-sm font-[700] text-primary hover:underline">← Tekrar dene</Link>
          </div>
        ) : (
          <>
            {/* Header cards */}
            <div className="mb-6 grid grid-cols-2 gap-4">
              {[bizA, bizB].map((biz, i) => (
                <div key={i} className="rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1">
                  {biz ? (
                    <>
                      <div className="mb-2 flex items-center gap-3">
                        {biz.logo_url ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={biz.logo_url} alt={biz.name} className="h-10 w-10 shrink-0 rounded-xl border border-border object-cover" loading="lazy" />
                        ) : (
                          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-base font-[900] text-primary">
                            {biz.name[0]}
                          </div>
                        )}
                        <div className="min-w-0">
                          <Link href={`/isletme/${biz.slug}`} className="block truncate font-[900] text-textStrong hover:text-primary">
                            {biz.name}
                          </Link>
                          <p className="truncate text-xs text-muted">{[biz.category, biz.city].filter(Boolean).join(' · ')}</p>
                        </div>
                      </div>
                    </>
                  ) : (
                    <p className="text-sm text-muted">Bulunamadı: <code className="rounded bg-border px-1 text-xs">{i === 0 ? a : b}</code></p>
                  )}
                </div>
              ))}
            </div>

            {/* Comparison table */}
            <div className="overflow-hidden rounded-[20px] border border-border shadow-yd1">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-cardAlt">
                    <th className="w-32 px-5 py-3 text-left text-xs font-[900] uppercase tracking-wide text-muted">Özellik</th>
                    <th className="px-5 py-3 text-left font-[800] text-textStrong">{bizA?.name ?? <span className="text-muted">—</span>}</th>
                    <th className="px-5 py-3 text-left font-[800] text-textStrong">{bizB?.name ?? <span className="text-muted">—</span>}</th>
                  </tr>
                </thead>
                <tbody>
                  {/* Rating */}
                  <tr className="border-b border-border bg-[var(--yd-color-primary-soft)]/20">
                    <td className="px-5 py-3 text-xs font-[700] text-muted">Puan</td>
                    <td className="px-5 py-3">
                      {bizA?.avgRating
                        ? <><span className="font-[900] text-textStrong">⭐ {bizA.avgRating.toFixed(1)}</span><Winner a={bizA.avgRating} b={bizB?.avgRating ?? null} /></>
                        : <span className="text-muted text-xs">—</span>}
                    </td>
                    <td className="px-5 py-3">
                      {bizB?.avgRating
                        ? <><span className="font-[900] text-textStrong">⭐ {bizB.avgRating.toFixed(1)}</span><WinnerB a={bizA?.avgRating ?? null} b={bizB.avgRating} /></>
                        : <span className="text-muted text-xs">—</span>}
                    </td>
                  </tr>
                  {/* Review count */}
                  <tr className="border-b border-border">
                    <td className="px-5 py-3 text-xs font-[700] text-muted">Yorum</td>
                    <td className="px-5 py-3">
                      {bizA?.reviewCount
                        ? <><span className="font-[900] text-textStrong">{bizA.reviewCount.toLocaleString('tr-TR')}</span><Winner a={bizA.reviewCount} b={bizB?.reviewCount ?? null} /></>
                        : <span className="text-muted text-xs">—</span>}
                    </td>
                    <td className="px-5 py-3">
                      {bizB?.reviewCount
                        ? <><span className="font-[900] text-textStrong">{bizB.reviewCount.toLocaleString('tr-TR')}</span><WinnerB a={bizA?.reviewCount ?? null} b={bizB.reviewCount} /></>
                        : <span className="text-muted text-xs">—</span>}
                    </td>
                  </tr>
                  {/* Median price */}
                  <tr className="border-b border-border bg-[var(--yd-color-primary-soft)]/10">
                    <td className="px-5 py-3 text-xs font-[700] text-muted">Ort. Fiyat</td>
                    <td className="px-5 py-3">
                      {bizA?.medianPrice
                        ? <><span className="font-[900] text-textStrong">{fmtPrice(bizA.medianPrice)}</span><Winner a={bizA.medianPrice} b={bizB?.medianPrice ?? null} higherBetter={false} /></>
                        : <span className="text-muted text-xs">—</span>}
                    </td>
                    <td className="px-5 py-3">
                      {bizB?.medianPrice
                        ? <><span className="font-[900] text-textStrong">{fmtPrice(bizB.medianPrice)}</span><WinnerB a={bizA?.medianPrice ?? null} b={bizB.medianPrice} higherBetter={false} /></>
                        : <span className="text-muted text-xs">—</span>}
                    </td>
                  </tr>
                  {/* Verified */}
                  <tr className="border-b border-border">
                    <td className="px-5 py-3 text-xs font-[700] text-muted">Doğrulama</td>
                    <td className="px-5 py-3">
                      {bizA ? (bizA.is_verified
                        ? <span className="text-xs font-[800] text-success">✓ Doğrulanmış</span>
                        : <span className="text-xs text-muted">Doğrulanmamış</span>) : '—'}
                    </td>
                    <td className="px-5 py-3">
                      {bizB ? (bizB.is_verified
                        ? <span className="text-xs font-[800] text-success">✓ Doğrulanmış</span>
                        : <span className="text-xs text-muted">Doğrulanmamış</span>) : '—'}
                    </td>
                  </tr>
                  {/* Category / location */}
                  {[
                    { label: 'Kategori', ka: bizA?.category, kb: bizB?.category },
                    { label: 'Konum', ka: [bizA?.district, bizA?.city].filter(Boolean).join(', '), kb: [bizB?.district, bizB?.city].filter(Boolean).join(', ') },
                  ].map(({ label, ka, kb }) => (
                    <tr key={label} className="border-b border-border last:border-0 even:bg-cardAlt/30">
                      <td className="px-5 py-3 text-xs font-[700] text-muted">{label}</td>
                      <td className="px-5 py-3 text-sm text-textStrong">{ka || '—'}</td>
                      <td className="px-5 py-3 text-sm text-textStrong">{kb || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Özet: Hangisi Daha İyi? */}
            {bizA && bizB && (bizA.avgRating || bizA.reviewCount || bizA.medianPrice) && (() => {
              let aScore = 0; let bScore = 0;
              if (bizA.avgRating && bizB.avgRating) { if (bizA.avgRating > bizB.avgRating) aScore++; else if (bizB.avgRating > bizA.avgRating) bScore++; }
              if (bizA.reviewCount && bizB.reviewCount) { if (bizA.reviewCount > bizB.reviewCount) aScore++; else if (bizB.reviewCount > bizA.reviewCount) bScore++; }
              if (bizA.medianPrice && bizB.medianPrice) { if (bizA.medianPrice < bizB.medianPrice) aScore++; else if (bizB.medianPrice < bizA.medianPrice) bScore++; }
              if (bizA.is_verified && !bizB.is_verified) aScore++;
              if (bizB.is_verified && !bizA.is_verified) bScore++;
              const winner = aScore > bScore ? bizA : bScore > aScore ? bizB : null;
              return (
                <div className="mt-6 flex items-start gap-4 rounded-2xl border border-border bg-cardAlt p-5">
                  <span className="text-2xl">🏆</span>
                  <div>
                    <p className="text-xs font-[900] uppercase tracking-wide text-muted">Genel Değerlendirme</p>
                    {winner ? (
                      <p className="mt-0.5 font-[900] text-textStrong">
                        <span className="text-primary">{winner.name}</span> puan, yorum ve fiyat kriterlerinde öne çıkıyor.
                      </p>
                    ) : (
                      <p className="mt-0.5 font-[900] text-textStrong">İki işletme birbirine çok yakın — her ikisi de değerlendirilebilir.</p>
                    )}
                  </div>
                </div>
              );
            })()}

            {/* CTA */}
            <div className="mt-4 grid grid-cols-2 gap-4">
              {[bizA, bizB].map((biz, i) => biz && (
                <Link key={i} href={`/isletme/${biz.slug}`}
                  className="inline-flex min-h-[44px] items-center justify-center rounded-2xl border border-border bg-card text-sm font-[800] text-textStrong hover:border-primary/40">
                  {biz.name} →
                </Link>
              ))}
            </div>
          </>
        )}
      </div>
    </main>
  );
}
