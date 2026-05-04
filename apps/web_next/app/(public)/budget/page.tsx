import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const revalidate = 300;
export const metadata: Metadata = { title: 'Bütçe Kombolar | Yeedoy', description: 'Bütçenize uygun en iyi menü seçenekleri' };

type Props = { searchParams: Promise<{ max?: string; city?: string }> };

const BUDGET_OPTIONS = [
  { value: '2500', label: '25₺' },
  { value: '5000', label: '50₺' },
  { value: '10000', label: '100₺' },
  { value: '20000', label: '200₺' },
];

function formatPrice(cents: number, currency: string) {
  return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: currency || 'TRY', minimumFractionDigits: 0 }).format(cents / 100);
}

export default async function BudgetPage({ searchParams }: Props) {
  const { max = '5000', city = '' } = await searchParams;
  const maxCents = Math.max(100, parseInt(max, 10));
  const supabase = await createSupabaseServerClient();

  type ItemRow = { id: string; name: string; price_cents: number; currency: string; business_id: string; businesses: { name: string; slug: string; city: string | null } | null };
  let items: ItemRow[] = [];

  try {
    let q = (supabase as any)
      .from('menu_items')
      .select('id, name, price_cents, currency, business_id, businesses(name, slug, city)')
      .lte('price_cents', maxCents)
      .eq('is_available', true)
      .order('price_cents')
      .limit(40);
    const { data } = await q as { data: ItemRow[] | null };
    items = data ?? [];
  } catch {
    items = [];
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-3xl px-4 py-10">
        <h1 className="mb-2 text-3xl font-[900] text-textStrong">Bütçe Kombolar</h1>
        <p className="mb-6 text-sm text-muted">Bütçenize uygun menü ürünlerini keşfedin</p>

        <form method="get" className="mb-8 flex flex-wrap items-end gap-4">
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-[700] text-muted uppercase">Maksimum Fiyat</label>
            <select name="max" defaultValue={max} className="rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30 cursor-pointer">
              {BUDGET_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-[700] text-muted uppercase">Şehir</label>
            <input name="city" defaultValue={city} placeholder="Tüm şehirler" className="rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 w-36" />
          </div>
          <button type="submit" className="rounded-xl bg-primary px-5 py-2 text-sm font-[700] text-white cursor-pointer">Ara</button>
        </form>

        {items.length === 0 ? (
          <p className="text-sm text-muted">Bu bütçede ürün bulunamadı.</p>
        ) : (
          <div className="flex flex-col gap-3">
            {items.map((item) => (
              <Link
                key={item.id}
                href={item.businesses?.slug ? `/m/${item.businesses.slug}` : '#'}
                className="flex items-center justify-between rounded-2xl border border-border bg-card px-5 py-4 transition-colors hover:border-primary/30 cursor-pointer"
              >
                <div>
                  <p className="font-[700] text-textStrong">{item.name}</p>
                  {item.businesses && (
                    <p className="mt-0.5 text-[12px] text-muted">{item.businesses.name}{item.businesses.city ? ` · ${item.businesses.city}` : ''}</p>
                  )}
                </div>
                <span className="shrink-0 rounded-xl bg-primary/10 px-3 py-1.5 text-sm font-[800] text-primary">
                  {formatPrice(item.price_cents, item.currency)}
                </span>
              </Link>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
