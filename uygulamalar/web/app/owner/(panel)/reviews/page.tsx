import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { ReviewsClient } from './reviews-client';
import type { ReviewRow } from './reviews-client';

export const metadata: Metadata = {
  title: 'Yorumlar | Owner Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ status?: string; rating?: string }> };

const STATUS_TABS = [
  { key: null,       label: 'Tümü' },
  { key: 'approved', label: 'Onaylı' },
  { key: 'pending',  label: 'Bekleyen' },
  { key: 'rejected', label: 'Reddedilen' },
];

export default async function OwnerReviewsPage({ searchParams }: Props) {
  const { status: statusParam, rating: ratingParam } = await searchParams;
  const statusFilter = STATUS_TABS.slice(1).some((t) => t.key === statusParam) ? statusParam : null;
  const ratingFilter = ratingParam ? parseInt(ratingParam, 10) : null;

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  // İşletme ID'lerini owner_claims'ten al
  const { data: claims } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved') as { data: { business_id: string }[] | null };

  const businessIds = (claims ?? []).map((c) => c.business_id);

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader eyebrow="Owner" title="Yorumlar" description="İşletme yorumları" />
        <PanelContentSurface className="pt-6">
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border bg-[#fafafa] py-20 text-center">
            <p className="text-base font-[800] text-textStrong">İşletme bulunamadı</p>
            <p className="mt-1 text-sm text-muted">Yorumları görmek için önce bir işletme talep edin.</p>
          </div>
        </PanelContentSurface>
      </div>
    );
  }

  // İşletme isimlerini al
  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .in('id', businessIds) as { data: { id: string; name: string }[] | null };
  const businessMap = Object.fromEntries((businesses ?? []).map((b) => [b.id, b.name]));

  // Her işletme için get_owner_reviews_v1 RPC çağrısı (reply verisi dahil)
  const rpcResults = await Promise.all(
    businessIds.map((bizId: string) =>
      (supabase as any).rpc('get_owner_reviews_v1', {
        p_business_id: bizId,
        p_sort: 'newest',
        p_limit: 500,
        p_offset: 0,
      })
    )
  );

  // Tüm yorumları birleştir, business_id ekle, tarihe göre sırala
  const allReviews: ReviewRow[] = rpcResults
    .flatMap((res, idx) =>
      ((res.data ?? []) as Omit<ReviewRow, 'business_id'>[]).map((r) => ({
        ...r,
        business_id: businessIds[idx],
      }))
    )
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  // İstatistikler
  const totalAll    = allReviews.length;
  const avgRating   = totalAll > 0 ? allReviews.reduce((s, r) => s + r.rating, 0) / totalAll : 0;
  const byRating    = [5, 4, 3, 2, 1].map((n) => ({ n, count: allReviews.filter((r) => r.rating === n).length }));
  const pendingCount = allReviews.filter((r) => r.status === 'pending').length;

  // Filtrele
  let filtered = allReviews;
  if (statusFilter) filtered = filtered.filter((r) => r.status === statusFilter);
  if (ratingFilter) filtered = filtered.filter((r) => r.rating === ratingFilter);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Yorumlar"
        description={`${totalAll} yorum${pendingCount > 0 ? ` · ${pendingCount} bekleyen` : ''}`}
      />
      <PanelContentSurface className="pt-6 flex flex-col gap-5">

        {/* KPI satırı */}
        {totalAll > 0 && (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <KpiBox label="Toplam Yorum" value={String(totalAll)} />
            <KpiBox label="Ortalama Puan" value={avgRating.toFixed(1)} sub="/ 5.0" accent />
            <KpiBox
              label="Onaylı"
              value={String(allReviews.filter((r) => r.status === 'approved').length)}
            />
            <KpiBox label="Bekleyen" value={String(pendingCount)} warn={pendingCount > 0} />
          </div>
        )}

        {/* Puan dağılımı + durum filtresi */}
        {totalAll > 0 && (
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            {/* Puan dağılımı */}
            <PanelSectionCard>
              <p className="mb-3 text-xs font-[800] uppercase tracking-wider text-muted">Puan Dağılımı</p>
              <div className="flex flex-col gap-2">
                {byRating.map(({ n, count }) => (
                  <Link
                    key={n}
                    href={ratingFilter === n ? '/owner/reviews' : `/owner/reviews?rating=${n}`}
                    className={`flex items-center gap-3 rounded-xl px-2 py-1.5 transition-colors hover:bg-zinc-50
                      ${ratingFilter === n ? 'bg-zinc-50 ring-1 ring-border' : ''}`}
                  >
                    <span className="w-3 shrink-0 text-right text-xs font-[800] text-textStrong">{n}</span>
                    <div className="flex shrink-0 gap-0.5">
                      {[1, 2, 3, 4, 5].map((s) => (
                        <svg key={s} width="10" height="10" viewBox="0 0 24 24"
                          fill={s <= n ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2"
                          className={s <= n ? 'text-amber-400' : 'text-zinc-300'}>
                          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                        </svg>
                      ))}
                    </div>
                    <div className="h-1.5 min-w-0 flex-1 overflow-hidden rounded-full bg-zinc-100">
                      <div
                        className="h-full rounded-full bg-amber-400 transition-all"
                        style={{ width: `${totalAll > 0 ? (count / totalAll) * 100 : 0}%` }}
                      />
                    </div>
                    <span className="w-5 shrink-0 text-right text-xs font-[600] text-muted">{count}</span>
                  </Link>
                ))}
              </div>
            </PanelSectionCard>

            {/* Durum filtresi */}
            <PanelSectionCard>
              <p className="mb-3 text-xs font-[800] uppercase tracking-wider text-muted">Durum Filtresi</p>
              <div className="flex flex-col gap-1">
                {STATUS_TABS.map((tab) => {
                  const isActive = statusFilter === tab.key;
                  const count = tab.key === null
                    ? totalAll
                    : allReviews.filter((r) => r.status === tab.key).length;
                  return (
                    <Link
                      key={tab.key ?? 'all'}
                      href={tab.key ? `/owner/reviews?status=${tab.key}` : '/owner/reviews'}
                      className={`flex items-center justify-between rounded-xl px-3 py-2.5 text-sm transition-colors
                        ${isActive
                          ? 'bg-[#7f1d1d]/8 font-[700] text-[#7f1d1d]'
                          : 'text-text hover:bg-zinc-50'}`}
                    >
                      <span>{tab.label}</span>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-[700]
                        ${isActive ? 'bg-[#7f1d1d] text-white' : 'bg-zinc-100 text-muted'}`}>
                        {count}
                      </span>
                    </Link>
                  );
                })}
              </div>
            </PanelSectionCard>
          </div>
        )}

        {/* Yorum listesi (client component — reply formu için) */}
        <ReviewsClient
          reviews={filtered}
          businessMap={businessMap}
          showBusinessName={businessIds.length > 1}
        />

      </PanelContentSurface>
    </div>
  );
}

function KpiBox({
  label, value, sub, accent, warn,
}: {
  label: string; value: string; sub?: string; accent?: boolean; warn?: boolean;
}) {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <p className="text-xs font-[700] text-muted">{label}</p>
      <p className={`mt-1 flex items-baseline gap-1 text-2xl font-[800]
        ${warn ? 'text-amber-600' : accent ? 'text-[#7f1d1d]' : 'text-textStrong'}`}>
        {value}
        {sub && <span className="text-sm font-[600] text-muted">{sub}</span>}
      </p>
    </div>
  );
}
