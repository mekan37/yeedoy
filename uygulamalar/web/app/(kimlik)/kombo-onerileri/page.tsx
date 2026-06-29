import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Bütçe-Dostu Kombolar | Yeedoy',
  robots: { index: false, follow: false },
};

const BUTCE_SECENEKLERI = [
  { value: '20000', label: '₺200 altı' },
  { value: '40000', label: '₺200 – ₺400' },
  { value: '60000', label: '₺400 – ₺600' },
  { value: '100000', label: '₺600 – ₺1.000' },
  { value: '200000', label: '₺1.000 üzeri' },
] as const;

function fmtCents(cents: number): string {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    maximumFractionDigits: 0,
  }).format(Math.floor(cents / 100));
}

type Oneri = {
  business_id: string;
  business_name: string;
  image_url: string | null;
  cuisine: string | null;
  rating: number | null;
  review_count: number | null;
  distance_km: number | null;
  estimated_minutes: number | null;
  total_cents: number;
  original_total_cents: number | null;
  discount_pct: number | null;
  slug?: string;
};

type SearchParams = { city?: string; kisi?: string; butce?: string };

export default async function KomboOnerileriPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const params = await searchParams;
  const city = params.city?.trim() ?? '';
  const kisi = Math.min(8, Math.max(1, Number.parseInt(params.kisi ?? '2', 10) || 2));
  const butce = Number.parseInt(params.butce ?? '60000', 10) || 60000;

  const supabase = await createSupabaseServerClient();

  let oneriList: Oneri[] = [];
  let fetchError: string | null = null;

  try {
    const { data, error: rpcError } = await (supabase as any).rpc(
      'get_smart_recommendations_v1',
      {
        p_city: city,
        p_district: '',
        p_party_size: kisi,
        p_budget_max_cents: butce,
        p_limit: 10,
      },
    );

    if (rpcError) throw rpcError;

    const items = (data as Oneri[]) ?? [];

    if (items.length > 0) {
      const ids = items.map((i) => i.business_id);
      const { data: slugRows } = await (supabase as any)
        .from('businesses')
        .select('id, slug')
        .in('id', ids);
      const slugMap = Object.fromEntries(
        ((slugRows ?? []) as { id: string; slug: string }[]).map((r) => [r.id, r.slug]),
      );
      oneriList = items.map((i) => ({ ...i, slug: slugMap[i.business_id] ?? undefined }));
    }
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : (e as { message?: string })?.message;
    fetchError = msg ?? 'Öneriler yüklenemedi.';
  }

  const butceLabel = BUTCE_SECENEKLERI.find((b) => b.value === String(butce))?.label ?? '';

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 pb-20 pt-10">

        {/* Geri */}
        <Link
          href="/kesif"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary"
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" />
          </svg>
          Keşfe Dön
        </Link>

        {/* Başlık */}
        <div className="mb-6">
          <p className="mb-1 text-xs font-[700] uppercase tracking-wide text-muted">Keşif</p>
          <h1 className="text-2xl font-[900] text-textStrong">Bütçe-Dostu Kombolar</h1>
          <p className="mt-1 text-sm text-muted">Damak tadına ve bütçene uygun öneriler</p>
        </div>

        {/* Filtre formu */}
        <form
          method="get"
          action="/kombo-onerileri"
          className="mb-8 rounded-2xl border border-border bg-card p-5"
        >
          <div className="flex flex-col gap-4">
            <div>
              <label htmlFor="city" className="mb-1.5 block text-xs font-[700] text-muted">
                Şehir (isteğe bağlı)
              </label>
              <input
                type="text"
                id="city"
                name="city"
                defaultValue={city}
                placeholder="İstanbul, Ankara..."
                className="w-full rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="kisi" className="mb-1.5 block text-xs font-[700] text-muted">
                  Kişi Sayısı
                </label>
                <select
                  id="kisi"
                  name="kisi"
                  defaultValue={String(kisi)}
                  className="w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                >
                  {[1, 2, 3, 4, 5, 6, 7, 8].map((n) => (
                    <option key={n} value={String(n)}>
                      {n} kişi
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="butce" className="mb-1.5 block text-xs font-[700] text-muted">
                  Toplam Bütçe
                </label>
                <select
                  id="butce"
                  name="butce"
                  defaultValue={String(butce)}
                  className="w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                >
                  {BUTCE_SECENEKLERI.map((b) => (
                    <option key={b.value} value={b.value}>
                      {b.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <button
              type="submit"
              className="min-h-[44px] w-full rounded-2xl text-sm font-[800] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{
                background: 'var(--yd-gradient-primary)',
                boxShadow: 'var(--yd-shadow-primary)',
              }}
            >
              Önerileri Getir
            </button>
          </div>
        </form>

        {/* Sonuçlar */}
        {fetchError ? (
          <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-center">
            <p className="text-sm font-[700] text-red-700">{fetchError}</p>
          </div>
        ) : oneriList.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[var(--yd-color-primary-soft)]">
              <svg
                viewBox="0 0 24 24"
                className="h-7 w-7 fill-none stroke-current text-primary"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <circle cx="11" cy="11" r="8" />
                <path d="m21 21-4.35-4.35" />
                <path d="M8 11h6M11 8v6" />
              </svg>
            </div>
            <p className="mb-2 font-[900] text-textStrong">Bu kriterlere uygun öneri bulunamadı</p>
            <p className="text-sm text-muted">Şehir veya bütçe aralığını değiştirip tekrar deneyin.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            <p className="text-xs text-muted">
              {[city && `${city}'da`, butceLabel, `${kisi} kişi`]
                .filter(Boolean)
                .join(' · ')}{' '}
              için {oneriList.length} öneri
            </p>
            {oneriList.map((item) => (
              <OneriKarti key={item.business_id} item={item} kisi={kisi} />
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

function OneriKarti({ item, kisi }: { item: Oneri; kisi: number }) {
  const href = item.slug ? `/isletme/${item.slug}` : null;

  const inner = (
    <div className="flex gap-4 rounded-2xl border border-border bg-card p-4 transition-all hover:-translate-y-0.5 hover:border-primary/20 hover:shadow-yd2">
      {/* Küçük resim */}
      <div className="h-[72px] w-[72px] shrink-0 overflow-hidden rounded-xl bg-cardAlt">
        {item.image_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={item.image_url}
            alt={item.business_name}
            className="h-full w-full object-cover"
            loading="lazy"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center">
            <svg viewBox="0 0 24 24" className="h-8 w-8 fill-current text-border" aria-hidden="true">
              <path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z" />
            </svg>
          </div>
        )}
      </div>

      {/* İçerik */}
      <div className="min-w-0 flex-1">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <p className="truncate font-[900] text-textStrong">{item.business_name}</p>
            {item.cuisine && <p className="mt-0.5 text-xs text-muted">{item.cuisine}</p>}
          </div>
          {item.discount_pct != null && (
            <span className="shrink-0 rounded-lg bg-red-50 px-2 py-0.5 text-[11px] font-[800] text-red-600">
              %{item.discount_pct} indirim
            </span>
          )}
        </div>

        <div className="mt-2 flex items-center gap-3 text-xs text-muted">
          {item.rating != null && (
            <span className="flex items-center gap-1">
              <span className="text-amber-400">★</span>
              <span className="font-[700] text-textStrong">{item.rating.toFixed(1)}</span>
              {item.review_count != null && <span>({item.review_count})</span>}
            </span>
          )}
          {item.distance_km != null && <span>{item.distance_km.toFixed(1)} km</span>}
          {item.estimated_minutes != null && <span>{item.estimated_minutes} dk</span>}
        </div>

        <div className="mt-3 flex items-center justify-between gap-2">
          <span className="text-xs text-muted">{kisi} kişi toplam</span>
          <div className="flex items-center gap-2">
            {item.original_total_cents != null && (
              <span className="text-xs text-muted line-through">
                {fmtCents(item.original_total_cents)}
              </span>
            )}
            <span className="rounded-xl bg-[var(--yd-color-primary-soft)] px-3 py-1 text-sm font-[900] text-primary">
              {fmtCents(item.total_cents)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );

  return href ? <Link href={href}>{inner}</Link> : <div>{inner}</div>;
}
