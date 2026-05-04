import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';

export const revalidate = 120;
export const metadata: Metadata = {
  title: 'Bütçe Kombolar | Yeedoy',
  description: 'Bütçenize uygun en iyi menü seçenekleri',
};

const BUDGET_OPTIONS = [
  { value: '2500', label: '25₺' },
  { value: '5000', label: '50₺' },
  { value: '7500', label: '75₺' },
  { value: '10000', label: '100₺' },
  { value: '15000', label: '150₺' },
  { value: '20000', label: '200₺' },
];

function fmtPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 0,
  }).format(cents / 100);
}

type Props = { searchParams: Promise<{ max?: string; city?: string }> };

type ItemRow = {
  id: string; name: string; price_cents: number; currency: string;
  business_id: string;
  businesses: { name: string; slug: string; city: string | null; category: string | null } | null;
};

export default async function BudgetPage({ searchParams }: Props) {
  const { max = '5000', city = '' } = await searchParams;
  const maxCents = Math.max(100, parseInt(max, 10));
  const supabase = await createSupabaseServerClient();

  let items: ItemRow[] = [];
  try {
    let q = (supabase as any)
      .from('menu_items')
      .select('id, name, price_cents, currency, business_id, businesses(name, slug, city, category)')
      .lte('price_cents', maxCents)
      .gt('price_cents', 0)
      .eq('is_available', true)
      .order('price_cents')
      .limit(40);
    if (city) q = q.eq('businesses.city', city);
    const { data } = await q as { data: ItemRow[] | null };
    items = (data ?? []).filter((i) => i.businesses != null);
  } catch { items = []; }

  const selectedBudget = BUDGET_OPTIONS.find((o) => o.value === max) ?? BUDGET_OPTIONS[1];

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-10">

        <AppSectionHeader
          title="Bütçe Kombolar"
          subtitle="Bütçenize uygun menü ürünlerini keşfedin"
          className="mb-8"
        />

        {/* Filter form */}
        <form method="get" className="mb-8 flex flex-wrap items-end gap-3">
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-[900] uppercase tracking-wide text-muted">Maksimum Fiyat</label>
            <div className="flex flex-wrap gap-1.5">
              {BUDGET_OPTIONS.map((o) => (
                <Link key={o.value}
                  href={`?max=${o.value}${city ? `&city=${city}` : ''}`}
                  className={`inline-flex min-h-[40px] items-center rounded-full border px-3.5 py-1 text-sm font-[800] transition-all duration-[150ms] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 ${max === o.value ? 'bg-[var(--yd-color-primary-soft)] border-primary/40 text-primary' : 'bg-cardAlt border-border text-textStrong hover:border-primary/30'}`}>
                  {o.label}
                </Link>
              ))}
            </div>
          </div>
          <div className="flex flex-col gap-1.5">
            <label htmlFor="city-input" className="text-xs font-[900] uppercase tracking-wide text-muted">Şehir</label>
            <div className="flex gap-2">
              <input id="city-input" name="city" defaultValue={city} placeholder="Tüm şehirler"
                className="w-36 rounded-2xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
              <input type="hidden" name="max" value={max} />
              <button type="submit"
                className="min-h-[40px] rounded-2xl px-4 text-sm font-[800] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
                style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
                Filtrele
              </button>
            </div>
          </div>
        </form>

        {/* Results */}
        <div className="mb-4 flex items-center justify-between">
          <AppSectionHeader title={`${selectedBudget.label} altı ürünler`} />
          <span className="text-sm text-muted">{items.length} ürün</span>
        </div>

        {items.length === 0 ? (
          <div className="rounded-[20px] border border-border bg-card px-5 py-14 text-center">
            <p className="font-[900] text-textStrong">Bu bütçede ürün bulunamadı</p>
            <p className="mt-2 text-sm text-muted">Bütçenizi artırmayı veya şehir filtresini kaldırmayı deneyin.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {items.map((item) => (
              <Link key={item.id}
                href={item.businesses?.slug ? `/m/${item.businesses.slug}` : '#'}
                className="flex items-center gap-4 rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-yd2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                  <span className="font-[800] text-textStrong">{item.name}</span>
                  {item.businesses && (
                    <span className="text-xs text-muted">
                      {item.businesses.name}
                      {item.businesses.category && ` · ${item.businesses.category}`}
                      {item.businesses.city && ` · ${item.businesses.city}`}
                    </span>
                  )}
                </div>
                <span className="shrink-0 rounded-2xl border border-primary/20 bg-[var(--yd-color-primary-soft)] px-3 py-1.5 text-sm font-[900] text-primary">
                  {fmtPrice(item.price_cents, item.currency)}
                </span>
              </Link>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
