import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

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

type ItemRow = {
  id: string; name: string; price_cents: number; currency: string;
  business_id: string;
  businesses: { name: string; slug: string; city: string | null; category: string | null } | null;
};

type BusinessGroup = {
  slug: string;
  name: string;
  city: string | null;
  category: string | null;
  items: ItemRow[];
  totalCents: number;
  currency: string;
};

type Props = { searchParams: Promise<{ max?: string; city?: string }> };

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
      .limit(60);
    if (city) q = q.eq('businesses.city', city);
    const { data } = await q as { data: ItemRow[] | null };
    items = (data ?? []).filter((i) => i.businesses != null);
  } catch { items = []; }

  // Group by business
  const grouped = new Map<string, BusinessGroup>();
  for (const item of items) {
    const biz = item.businesses!;
    const existing = grouped.get(biz.slug) ?? {
      slug: biz.slug,
      name: biz.name,
      city: biz.city,
      category: biz.category,
      items: [],
      totalCents: 0,
      currency: item.currency,
    };
    existing.items.push(item);
    existing.totalCents += item.price_cents;
    grouped.set(biz.slug, existing);
  }

  // Sort by item count descending (more choices = better combo)
  const groups = Array.from(grouped.values())
    .sort((a, b) => b.items.length - a.items.length)
    .slice(0, 12);

  const selectedBudget = BUDGET_OPTIONS.find((o) => o.value === max) ?? BUDGET_OPTIONS[1];

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-10">
        <h1 className="mb-1 text-2xl font-[900] text-textStrong">Bütçe Kombolar</h1>
        <p className="mb-8 text-sm text-muted">Bütçenize uygun işletmeler ve menü seçenekleri</p>

        {/* Filter */}
        <form method="get" className="mb-8 flex flex-wrap items-end gap-3">
          <div className="flex flex-col gap-1.5">
            <span className="text-xs font-[900] uppercase tracking-wide text-muted">Maksimum Fiyat</span>
            <div className="flex flex-wrap gap-1.5">
              {BUDGET_OPTIONS.map((o) => (
                <Link key={o.value}
                  href={`?max=${o.value}${city ? `&city=${city}` : ''}`}
                  className={`inline-flex min-h-[40px] items-center rounded-full border px-3.5 py-1 text-sm font-[800] transition-all ${max === o.value ? 'bg-[var(--yd-color-primary-soft)] border-primary/40 text-primary' : 'bg-cardAlt border-border text-textStrong hover:border-primary/30'}`}>
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
                className="min-h-[40px] rounded-2xl px-4 text-sm font-[800] text-white"
                style={{ background: 'var(--yd-gradient-primary)' }}>
                Filtrele
              </button>
            </div>
          </div>
        </form>

        <div className="mb-5 flex items-center justify-between gap-3">
          <p className="text-sm font-[900] text-textStrong">{selectedBudget.label} altı — {groups.length} işletme</p>
          {groups.length > 0 && (() => {
            const best = groups[0];
            const shareText = encodeURIComponent(
              `${city || 'Yakınımda'} ${selectedBudget.label} altında yemek: ${best.name} (${best.items.length} seçenek 🍽️)\nyeedoy.com/butce?max=${max}${city ? `&city=${encodeURIComponent(city)}` : ''}`
            );
            return (
              <a
                href={`whatsapp://send?text=${shareText}`}
                className="flex shrink-0 items-center gap-1.5 rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-muted hover:bg-border/40 transition-colors"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
                  <path d="M12 0C5.373 0 0 5.373 0 12c0 2.122.552 4.112 1.512 5.84L0 24l6.336-1.494A11.928 11.928 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 21.818a9.797 9.797 0 0 1-5.028-1.384l-.36-.214-3.732.879.894-3.63-.235-.373A9.796 9.796 0 0 1 2.182 12C2.182 6.573 6.573 2.182 12 2.182S21.818 6.573 21.818 12 17.427 21.818 12 21.818z"/>
                </svg>
                Paylaş
              </a>
            );
          })()}
        </div>

        {/* En İyi Değer — en çok seçenek sunan işletme */}
        {groups.length > 0 && (() => {
          const best = groups.reduce((a, b) => a.items.length > b.items.length ? a : b);
          return (
            <div className="mb-5 flex items-center gap-3 rounded-2xl border border-success/25 bg-success/[0.07] px-5 py-4">
              <span className="text-xl">🏆</span>
              <div className="min-w-0 flex-1">
                <p className="text-xs font-[900] uppercase tracking-wide text-success">En İyi Değer</p>
                <p className="font-[900] text-textStrong">{best.name}</p>
                <p className="text-xs text-muted">{best.items.length} seçenek · en ucuk {fmtPrice(best.items[0].price_cents, best.items[0].currency)}</p>
              </div>
              <Link href={`/m/${best.slug}`} className="shrink-0 rounded-xl bg-success px-3 py-1.5 text-[11px] font-[900] text-white">Menü</Link>
            </div>
          );
        })()}

        {groups.length === 0 ? (
          <div className="rounded-[20px] border border-border bg-card px-5 py-14 text-center">
            <p className="font-[900] text-textStrong">Bu bütçede ürün bulunamadı</p>
            <p className="mt-2 text-sm text-muted">Bütçenizi artırmayı veya şehir filtresini kaldırmayı deneyin.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {groups.map((group) => (
              <div key={group.slug} className="rounded-[20px] border border-border bg-cardAlt shadow-yd1">
                {/* Business header */}
                <div className="flex items-center gap-3 border-b border-border px-5 py-4">
                  <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                    <Link href={`/isletme/${group.slug}`} className="font-[900] text-textStrong hover:text-primary">
                      {group.name}
                    </Link>
                    <p className="text-xs text-muted">
                      {[group.category, group.city].filter(Boolean).join(' · ')}
                    </p>
                  </div>
                  <div className="shrink-0 text-right">
                    <p className="text-[11px] text-muted">{group.items.length} seçenek</p>
                    <p className="text-xs font-[900] text-primary">
                      {group.items.length > 1 ? `En ucuz: ${fmtPrice(group.items[0].price_cents, group.items[0].currency)}` : fmtPrice(group.items[0].price_cents, group.items[0].currency)}
                    </p>
                  </div>
                </div>

                {/* Items */}
                <div className="grid gap-0 divide-y divide-border">
                  {group.items.slice(0, 5).map((item) => (
                    <div key={item.id} className="flex items-center justify-between gap-4 px-5 py-3">
                      <span className="min-w-0 flex-1 truncate text-sm text-textStrong">{item.name}</span>
                      <span className="shrink-0 rounded-full border border-primary/20 bg-[var(--yd-color-primary-soft)] px-2.5 py-0.5 text-xs font-[900] text-primary">
                        {fmtPrice(item.price_cents, item.currency)}
                      </span>
                    </div>
                  ))}
                  {group.items.length > 5 && (
                    <div className="px-5 py-3 text-xs text-muted">+{group.items.length - 5} ürün daha…</div>
                  )}
                </div>

                {/* Footer CTA */}
                <div className="flex items-center justify-between gap-3 border-t border-border px-5 py-3">
                  <p className="text-xs text-muted">Tüm menüyü görmek için</p>
                  <Link href={`/m/${group.slug}`}
                    className="text-sm font-[900] text-primary hover:underline">
                    Menüyü Aç →
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
