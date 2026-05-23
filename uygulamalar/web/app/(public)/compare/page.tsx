import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabasePublicClient } from '@/src/lib/supabase/public';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';

export const revalidate = 300;

export const metadata: Metadata = {
  title: 'İşletme Karşılaştır | Yeedoy',
  description: 'İki işletmeyi yan yana karşılaştır',
};

type BusinessRow = {
  id: string; name: string; slug: string; category: string | null;
  city: string | null; district: string | null; phone: string | null;
  description: string | null; is_verified: boolean | null; logo_url: string | null;
};

const ROWS: { label: string; key: keyof BusinessRow }[] = [
  { label: 'Kategori', key: 'category' },
  { label: 'Şehir', key: 'city' },
  { label: 'İlçe', key: 'district' },
  { label: 'Telefon', key: 'phone' },
  { label: 'Açıklama', key: 'description' },
];

export default async function ComparePage({ searchParams }: { searchParams: Promise<{ a?: string; b?: string }> }) {
  const { a, b } = await searchParams;

  if (!a || !b) {
    return (
      <main className="min-h-screen bg-bg">
        <div className="mx-auto max-w-xl px-4 py-12">
          <AppSectionHeader title="İşletme Karşılaştır"
            subtitle="İki işletmenin slug bilgisini girerek yan yana karşılaştırın."
            className="mb-8" />
          <form method="get" className="flex flex-col gap-4">
            {[
              { id: 'a', label: '1. İşletme Slug', placeholder: 'ornek-kafe', def: a },
              { id: 'b', label: '2. İşletme Slug', placeholder: 'diger-restoran', def: b },
            ].map(({ id, label, placeholder, def }) => (
              <div key={id} className="flex flex-col gap-1.5">
                <label htmlFor={id} className="text-sm font-[700] text-textStrong">{label}</label>
                <input id={id} name={id} type="text" placeholder={placeholder} defaultValue={def ?? ''}
                  className="rounded-2xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
              </div>
            ))}
            <button type="submit"
              className="min-h-[52px] rounded-2xl text-base font-[900] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
              Karşılaştır
            </button>
          </form>
        </div>
      </main>
    );
  }

  const supabase = createSupabasePublicClient();
  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug, category, city, district, phone, description, is_verified, logo_url')
    .in('slug', [a, b]);

  const bizA = (businesses as BusinessRow[] | null)?.find((biz) => biz.slug === a) ?? null;
  const bizB = (businesses as BusinessRow[] | null)?.find((biz) => biz.slug === b) ?? null;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-4xl px-4 py-10">
        <div className="mb-6 flex items-center gap-4">
          <AppSectionHeader title="İşletme Karşılaştır" />
          <Link href="/compare"
            className="ml-auto shrink-0 text-sm font-[700] text-primary hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
            Yeniden ara
          </Link>
        </div>

        {!bizA && !bizB ? (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center">
            <p className="font-[900] text-textStrong">İşletme bulunamadı</p>
            <p className="mt-2 text-sm text-muted">Her iki slug da geçersiz.</p>
            <Link href="/compare" className="mt-4 inline-block text-sm font-[700] text-primary hover:underline">
              Tekrar dene →
            </Link>
          </div>
        ) : (
          <>
            {/* Business header cards */}
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
                          <Link href={`/b/${biz.slug}`}
                            className="block truncate font-[900] text-textStrong hover:text-primary transition-colors">
                            {biz.name}
                          </Link>
                          {biz.is_verified && (
                            <span className="inline-flex items-center gap-1 text-[11px] font-[800] text-success">
                              <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
                              Doğrulanmış
                            </span>
                          )}
                        </div>
                      </div>
                      <p className="text-xs text-muted">{[biz.category, biz.city].filter(Boolean).join(' · ')}</p>
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
                    <th className="w-28 px-5 py-3 text-left text-xs font-[900] uppercase tracking-wide text-muted">Özellik</th>
                    <th className="px-5 py-3 text-left font-[800] text-textStrong">
                      {bizA ? bizA.name : <span className="text-muted">—</span>}
                    </th>
                    <th className="px-5 py-3 text-left font-[800] text-textStrong">
                      {bizB ? bizB.name : <span className="text-muted">—</span>}
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {/* Verified row */}
                  <tr className="border-b border-border">
                    <td className="px-5 py-3 text-xs font-[700] text-muted">Doğrulama</td>
                    <td className="px-5 py-3">
                      {bizA ? (
                        bizA.is_verified
                          ? <span className="inline-flex items-center gap-1 text-xs font-[800] text-success"><svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-current" aria-hidden="true"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Doğrulanmış</span>
                          : <span className="text-xs text-muted">Doğrulanmamış</span>
                      ) : <span className="text-xs text-muted">—</span>}
                    </td>
                    <td className="px-5 py-3">
                      {bizB ? (
                        bizB.is_verified
                          ? <span className="inline-flex items-center gap-1 text-xs font-[800] text-success"><svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-current" aria-hidden="true"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Doğrulanmış</span>
                          : <span className="text-xs text-muted">Doğrulanmamış</span>
                      ) : <span className="text-xs text-muted">—</span>}
                    </td>
                  </tr>
                  {ROWS.map(({ label, key }) => (
                    <tr key={label} className="border-b border-border last:border-0 even:bg-cardAlt/40">
                      <td className="px-5 py-3 text-xs font-[700] text-muted">{label}</td>
                      <td className="px-5 py-3 text-sm text-textStrong">{bizA ? ((bizA[key] as string) ?? '—') : '—'}</td>
                      <td className="px-5 py-3 text-sm text-textStrong">{bizB ? ((bizB[key] as string) ?? '—') : '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* CTA links */}
            <div className="mt-6 grid grid-cols-2 gap-4">
              {[bizA, bizB].map((biz, i) => biz && (
                <Link key={i} href={`/b/${biz.slug}`}
                  className="inline-flex min-h-[44px] items-center justify-center rounded-2xl border border-border bg-card text-sm font-[800] text-textStrong transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                  {biz.name} sayfası →
                </Link>
              ))}
            </div>
          </>
        )}
      </div>
    </main>
  );
}
