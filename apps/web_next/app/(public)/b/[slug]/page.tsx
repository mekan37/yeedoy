import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import type { ReactNode } from 'react';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PublicMenuClient } from '@/src/ui/sections/public-menu-client';

export const revalidate = 120;

type MenuSnapshot = {
  updated_at: string | null;
  confidence_score: number | null;
};

type PriceHistoryPoint = {
  menu_item_id: string | null;
  menu_item_name: string | null;
  price_cents: number | null;
  changed_at: string | null;
};

export async function generateMetadata(
  { params }: { params: Promise<{ slug: string }> },
): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: business } = await supabase
    .from('businesses')
    .select('name,slug')
    .eq('slug', slug)
    .eq('is_active', true)
    .maybeSingle();
  if (!business) return { title: 'Menu bulunamadi' };
  return {
    title: `${business.name} | QR Menu`,
    openGraph: {
      title: `${business.name} | QR Menu`,
      images: [`/api/og?title=${encodeURIComponent(business.name)}`],
    },
  };
}

type PageProps = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ lang?: string }>;
};

export default async function PublicMenuPage({ params, searchParams }: PageProps) {
  const [{ slug }, { lang }] = await Promise.all([params, searchParams]);
  const supabase = await createSupabaseServerClient();
  const { data: business } = await supabase
    .from('businesses')
    .select('*')
    .eq('slug', slug)
    .eq('is_active', true)
    .single();

  if (!business) notFound();

  const [
    { data: categories },
    { data: items },
    { data: translations },
    { data: menuSnapshotData },
    { data: priceHistoryData },
  ] = await Promise.all([
    supabase
      .from('menu_categories')
      .select('*')
      .eq('business_id', business.id)
      .eq('is_active', true)
      .order('sort_order'),
    supabase
      .from('menu_items')
      .select(
        'id,business_id,category_id,name,description,price_cents,currency,tags,image_url,is_available,sort_order,created_at,updated_at',
      )
      .eq('business_id', business.id)
      .order('sort_order'),
    supabase.from('menu_translations').select('*').in('entity_type', ['business', 'category', 'item']),
    supabase
      .from('menus')
      .select('updated_at,confidence_score')
      .eq('business_id', business.id)
      .eq('is_active', true)
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase.rpc('get_business_price_history_v1', {
      p_business_id: business.id,
      p_days: 90,
      p_limit: 200,
    }),
  ]);

  const locale = lang || 'tr';
  const isTr = locale.toLowerCase().startsWith('tr');
  const businessName =
    translations?.find(
      (t) => t.entity_type === 'business' && t.entity_id === business.id && t.locale === locale,
    )?.name ?? business.name;
  const menuSnapshot = (menuSnapshotData ?? null) as MenuSnapshot | null;
  const priceHistory = (priceHistoryData ?? []) as PriceHistoryPoint[];
  const priceSummary = buildPriceSummary(priceHistory);
  const topItemChanges = buildTopItemChanges(priceHistory, 8);
  const recentPriceEvents = buildRecentPriceEvents(priceHistory, 14);
  const evidenceSummary = buildEvidenceSummary(priceHistory);
  const confidencePct = menuSnapshot?.confidence_score == null
    ? null
    : Math.round(Math.max(0, Math.min(1, menuSnapshot.confidence_score)) * 100);

  return (
    <main className="mx-auto min-h-screen w-full max-w-3xl p-4">
      <header className="mb-4 rounded-2xl bg-white p-4 shadow-sm">
        <h1 className="text-3xl font-extrabold">{businessName}</h1>
        <p className="text-slate-500">
          {business.city ?? ''} {business.district ?? ''}
        </p>
      </header>

      <section className="mb-4 grid gap-3 sm:grid-cols-3">
        <TransparencyCard
          label={isTr ? 'Son guncelleme' : 'Last update'}
          value={formatRelativeDate(menuSnapshot?.updated_at ?? null, isTr)}
          hint={isTr ? 'Aktif menu kaydina gore' : 'Based on active menu record'}
        />
        <TransparencyCard
          label={isTr ? 'Guven skoru' : 'Confidence'}
          value={confidencePct == null ? '-' : `%${confidencePct}`}
          hint={isTr ? 'Menu confidence skoru' : 'Menu confidence score'}
        />
        <TransparencyCard
          label={isTr ? '90 gun fiyat trendi' : '90d price trend'}
          value={formatPriceTrend(priceSummary.deltaPct, isTr)}
          hint={formatPriceHint(priceSummary, isTr)}
        />
      </section>

      <section className="mb-6 grid gap-3 lg:grid-cols-3">
        <DetailCard
          title={isTr ? 'Kanit ozeti' : 'Evidence summary'}
          body={(
            <div className="space-y-2 text-sm text-slate-700">
              <p>
                {isTr ? 'Kayit sayisi' : 'Records'}:{' '}
                <strong className="text-slate-900">{evidenceSummary.recordCount}</strong>
              </p>
              <p>
                {isTr ? 'Urun sayisi' : 'Items'}:{' '}
                <strong className="text-slate-900">{evidenceSummary.uniqueItemCount}</strong>
              </p>
              <p>
                {isTr ? 'Son fiyat degisimi' : 'Last price change'}:{' '}
                <strong className="text-slate-900">
                  {formatRelativeDate(evidenceSummary.lastChangedAt, isTr)}
                </strong>
              </p>
            </div>
          )}
        />
        <div className="lg:col-span-2">
          <TopItemChangesCard entries={topItemChanges} isTr={isTr} />
        </div>
      </section>

      <section className="mb-6">
        <RecentPriceEventsCard entries={recentPriceEvents} isTr={isTr} />
      </section>

      <PublicMenuClient
        locale={locale}
        showPrices
        theme="minimal"
        categories={(categories ?? []) as any}
        items={(items ?? []) as any}
        translations={(translations ?? []) as any}
      />
    </main>
  );
}

function buildPriceSummary(points: PriceHistoryPoint[]) {
  const normalized = normalizePriceHistory(points).sort(
    (a, b) => Date.parse(a.changed_at) - Date.parse(b.changed_at),
  );

  if (normalized.length < 2) {
    return { deltaPct: null, first: null, last: null, sampleCount: normalized.length };
  }

  const first = normalized[0].price_cents;
  const last = normalized[normalized.length - 1].price_cents;
  const deltaPct = first > 0 ? ((last - first) / first) * 100 : null;
  return {
    deltaPct,
    first,
    last,
    sampleCount: normalized.length,
  };
}

type NormalizedPriceHistoryPoint = {
  menu_item_id: string;
  menu_item_name: string;
  price_cents: number;
  changed_at: string;
};

function normalizePriceHistory(points: PriceHistoryPoint[]): NormalizedPriceHistoryPoint[] {
  return points
    .filter(
      (p): p is { menu_item_id: string; menu_item_name: string | null; price_cents: number; changed_at: string } =>
        typeof p.menu_item_id === 'string' &&
        p.menu_item_id.length > 0 &&
        typeof p.price_cents === 'number' &&
        p.price_cents > 0 &&
        typeof p.changed_at === 'string' &&
        p.changed_at.length > 0,
    )
    .map((p) => ({
      menu_item_id: p.menu_item_id,
      menu_item_name: (p.menu_item_name ?? '').trim() || 'Menu item',
      price_cents: p.price_cents,
      changed_at: p.changed_at,
    }));
}

type TopItemChangeEntry = {
  menuItemId: string;
  menuItemName: string;
  firstPriceCents: number;
  lastPriceCents: number;
  deltaPct: number | null;
  changeCount: number;
  lastChangedAt: string;
};

function buildTopItemChanges(points: PriceHistoryPoint[], limit: number): TopItemChangeEntry[] {
  const normalized = normalizePriceHistory(points);
  const grouped = new Map<string, NormalizedPriceHistoryPoint[]>();

  for (const point of normalized) {
    const key = point.menu_item_id;
    const bucket = grouped.get(key);
    if (bucket) {
      bucket.push(point);
    } else {
      grouped.set(key, [point]);
    }
  }

  const entries: TopItemChangeEntry[] = [];
  grouped.forEach((bucket, menuItemId) => {
    const sorted = bucket.sort((a, b) => Date.parse(a.changed_at) - Date.parse(b.changed_at));
    const first = sorted[0];
    const last = sorted[sorted.length - 1];
    const deltaPct = first.price_cents > 0
      ? ((last.price_cents - first.price_cents) / first.price_cents) * 100
      : null;
    entries.push({
      menuItemId,
      menuItemName: last.menu_item_name || first.menu_item_name || 'Menu item',
      firstPriceCents: first.price_cents,
      lastPriceCents: last.price_cents,
      deltaPct,
      changeCount: sorted.length,
      lastChangedAt: last.changed_at,
    });
  });

  return entries
    .filter((entry) => entry.changeCount >= 2 && entry.deltaPct != null)
    .sort((a, b) => Math.abs(b.deltaPct ?? 0) - Math.abs(a.deltaPct ?? 0))
    .slice(0, Math.max(1, limit));
}

type RecentPriceEvent = {
  menuItemId: string;
  menuItemName: string;
  priceCents: number;
  changedAt: string;
};

function buildRecentPriceEvents(points: PriceHistoryPoint[], limit: number): RecentPriceEvent[] {
  return normalizePriceHistory(points)
    .sort((a, b) => Date.parse(b.changed_at) - Date.parse(a.changed_at))
    .slice(0, Math.max(1, limit))
    .map((entry) => ({
      menuItemId: entry.menu_item_id,
      menuItemName: entry.menu_item_name,
      priceCents: entry.price_cents,
      changedAt: entry.changed_at,
    }));
}

function buildEvidenceSummary(points: PriceHistoryPoint[]) {
  const normalized = normalizePriceHistory(points);
  const uniqueItemCount = new Set(normalized.map((entry) => entry.menu_item_id)).size;
  const lastChangedAt = normalized
    .map((entry) => entry.changed_at)
    .sort((a, b) => Date.parse(b) - Date.parse(a))[0] ?? null;
  return {
    recordCount: normalized.length,
    uniqueItemCount,
    lastChangedAt,
  };
}

function formatRelativeDate(iso: string | null, isTr: boolean) {
  if (!iso) return isTr ? 'Bilinmiyor' : 'Unknown';
  const ts = Date.parse(iso);
  if (Number.isNaN(ts)) return isTr ? 'Bilinmiyor' : 'Unknown';
  const diffDays = Math.floor((Date.now() - ts) / (1000 * 60 * 60 * 24));
  if (diffDays <= 0) return isTr ? 'Bugun' : 'Today';
  return isTr ? `${diffDays} gun once` : `${diffDays} days ago`;
}

function formatPriceTrend(deltaPct: number | null, isTr: boolean) {
  if (deltaPct == null) return isTr ? 'Yetersiz veri' : 'Insufficient data';
  const sign = deltaPct >= 0 ? '+' : '';
  return `${sign}%${deltaPct.toFixed(1)}`;
}

function formatPriceHint(
  summary: { first: number | null; last: number | null; sampleCount: number },
  isTr: boolean,
) {
  if (summary.first == null || summary.last == null) {
    return isTr ? `Ornek sayisi: ${summary.sampleCount}` : `Samples: ${summary.sampleCount}`;
  }
  const first = `${(summary.first / 100).toFixed(2)} TL`;
  const last = `${(summary.last / 100).toFixed(2)} TL`;
  return `${first} -> ${last}`;
}

function formatMoneyFromCents(cents: number, isTr: boolean) {
  try {
    return new Intl.NumberFormat(isTr ? 'tr-TR' : 'en-US', {
      style: 'currency',
      currency: 'TRY',
      maximumFractionDigits: 2,
    }).format(cents / 100);
  } catch {
    return `${(cents / 100).toFixed(2)} TL`;
  }
}

function formatDateTime(iso: string, isTr: boolean) {
  const ts = Date.parse(iso);
  if (Number.isNaN(ts)) return isTr ? 'Bilinmiyor' : 'Unknown';
  return new Intl.DateTimeFormat(isTr ? 'tr-TR' : 'en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(ts));
}

function TransparencyCard({
  label,
  value,
  hint,
}: {
  label: string;
  value: string;
  hint: string;
}) {
  return (
    <article className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">{label}</p>
      <p className="mt-2 text-xl font-extrabold text-slate-900">{value}</p>
      <p className="mt-1 text-xs text-slate-500">{hint}</p>
    </article>
  );
}

function DetailCard({
  title,
  body,
}: {
  title: string;
  body: ReactNode;
}) {
  return (
    <article className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">{title}</h2>
      <div className="mt-3">{body}</div>
    </article>
  );
}

function TopItemChangesCard({
  entries,
  isTr,
}: {
  entries: TopItemChangeEntry[];
  isTr: boolean;
}) {
  const title = isTr ? 'Urun bazli fiyat gecmisi' : 'Item price history';
  if (entries.length === 0) {
    return (
      <DetailCard
        title={title}
        body={<p className="text-sm text-slate-500">{isTr ? 'Yeterli veri yok' : 'Insufficient data'}</p>}
      />
    );
  }

  return (
    <DetailCard
      title={title}
      body={(
        <div className="space-y-2">
          {entries.map((entry) => {
            const sign = (entry.deltaPct ?? 0) >= 0 ? '+' : '';
            return (
              <div
                key={entry.menuItemId}
                className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <p className="font-semibold text-slate-900">{entry.menuItemName}</p>
                  <p className="font-bold text-slate-900">
                    {sign}
                    {(entry.deltaPct ?? 0).toFixed(1)}%
                  </p>
                </div>
                <p className="mt-1 text-xs text-slate-600">
                  {formatMoneyFromCents(entry.firstPriceCents, isTr)}
                  {' -> '}
                  {formatMoneyFromCents(entry.lastPriceCents, isTr)} |{' '}
                  {isTr ? 'kayit' : 'records'}: {entry.changeCount}
                </p>
                <p className="mt-0.5 text-xs text-slate-500">
                  {isTr ? 'Son degisim' : 'Last change'}: {formatDateTime(entry.lastChangedAt, isTr)}
                </p>
              </div>
            );
          })}
        </div>
      )}
    />
  );
}

function RecentPriceEventsCard({
  entries,
  isTr,
}: {
  entries: RecentPriceEvent[];
  isTr: boolean;
}) {
  const title = isTr ? 'Son fiyat kayitlari' : 'Recent price records';
  if (entries.length === 0) {
    return (
      <DetailCard
        title={title}
        body={<p className="text-sm text-slate-500">{isTr ? 'Yeterli veri yok' : 'Insufficient data'}</p>}
      />
    );
  }

  return (
    <DetailCard
      title={title}
      body={(
        <div className="divide-y divide-slate-200">
          {entries.map((entry) => (
            <div key={`${entry.menuItemId}_${entry.changedAt}`} className="flex flex-wrap items-center gap-2 py-2">
              <p className="min-w-0 flex-1 truncate text-sm font-semibold text-slate-900">{entry.menuItemName}</p>
              <p className="text-sm font-bold text-slate-900">{formatMoneyFromCents(entry.priceCents, isTr)}</p>
              <p className="text-xs text-slate-500">{formatDateTime(entry.changedAt, isTr)}</p>
            </div>
          ))}
        </div>
      )}
    />
  );
}
