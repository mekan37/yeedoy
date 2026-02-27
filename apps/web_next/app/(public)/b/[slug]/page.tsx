import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PublicMenuClient } from '@/src/ui/sections/public-menu-client';

export const revalidate = 120;

type MenuSnapshot = {
  updated_at: string | null;
  confidence_score: number | null;
};

type PriceHistoryPoint = {
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
  const normalized = points
    .filter(
      (p): p is { price_cents: number; changed_at: string } =>
        typeof p.price_cents === 'number' &&
        p.price_cents > 0 &&
        typeof p.changed_at === 'string' &&
        p.changed_at.length > 0,
    )
    .sort((a, b) => Date.parse(a.changed_at) - Date.parse(b.changed_at));

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
