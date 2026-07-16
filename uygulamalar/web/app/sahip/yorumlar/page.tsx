import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { YorumlarIstemcisi } from './yorumlar-istemcisi';
import type { YorumSatiriVeri } from './yorumlar-istemcisi';

export const metadata: Metadata = {
  title: 'Yorumlar | Sahip Paneli',
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
  const statusFilter = STATUS_TABS.slice(1).some((t) => t.key === statusParam) ? (statusParam ?? null) : null;
  const ratingFilter = ratingParam ? parseInt(ratingParam, 10) : null;

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b: { id: string }) => b.id);
  const businessMap = Object.fromEntries(businesses.map((b: { id: string; name: string }) => [b.id, b.name]));

  const { data: reviews } = businessIds.length > 0
    ? await (supabase as any)
        .from('reviews')
        .select('id, business_id, user_id, rating, title, content, helpful_count, status, created_at, owner_reply, owner_replied_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(500)
    : { data: [] };

  const list = (reviews ?? []) as Array<{
    id: string;
    business_id: string;
    user_id: string | null;
    rating: number;
    title: string | null;
    content: string | null;
    helpful_count: number;
    status: string;
    created_at: string;
    owner_reply: string | null;
    owner_replied_at: string | null;
  }>;

  const userIds = Array.from(new Set(list.map((review) => review.user_id).filter((id): id is string => Boolean(id))));
  const { data: profiles } = userIds.length > 0
    ? await (supabase as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url')
        .in('user_id', userIds)
    : { data: [] };

  const profileMap = new Map(
    ((profiles ?? []) as Array<{ user_id: string; display_name: string | null; avatar_url: string | null }>)
      .map((profile) => [profile.user_id, profile] as const),
  );

  const showBusinessName = businessIds.length > 1;

  const allRows: YorumSatiriVeri[] = list.map((r) => ({
    id: r.id,
    businessId: r.business_id,
    rating: r.rating,
    title: r.title,
    content: r.content,
    helpfulCount: r.helpful_count,
    status: r.status,
    createdAt: r.created_at,
    displayName: r.user_id ? (profileMap.get(r.user_id)?.display_name ?? null) : null,
    avatarUrl: r.user_id ? (profileMap.get(r.user_id)?.avatar_url ?? null) : null,
    ownerReply: r.owner_reply,
    ownerRepliedAt: r.owner_replied_at,
  }));

  // İstatistikler (filtre uygulanmadan önce, tüm yorumlar üzerinden)
  const totalAll = allRows.length;
  const avgRating = totalAll > 0 ? allRows.reduce((s, r) => s + r.rating, 0) / totalAll : 0;
  const byRating = [5, 4, 3, 2, 1].map((n) => ({ n, count: allRows.filter((r) => r.rating === n).length }));
  const pendingCount = allRows.filter((r) => r.status === 'pending').length;

  let filteredRows = allRows;
  if (statusFilter) filteredRows = filteredRows.filter((r) => r.status === statusFilter);
  if (ratingFilter) filteredRows = filteredRows.filter((r) => r.rating === ratingFilter);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Yorumlar"
        description={
          pendingCount > 0
            ? `${totalAll} yorum · ${pendingCount} bekleyen`
            : `${totalAll} yorum`
        }
      />
      <PanelIcerikYuzeyi className="pt-6 flex flex-col gap-5">
        {totalAll === 0 ? (
          <PanelEmptyState
            icon={<StarIcon />}
            title="Henüz yorum yok"
            description="İşletmenize yapılan yorumlar burada görünür."
          />
        ) : (
          <>
            {/* KPI satırı */}
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <KpiBox label="Toplam Yorum" value={String(totalAll)} />
              <KpiBox label="Ortalama Puan" value={avgRating.toFixed(1)} sub="/ 5.0" accent />
              <KpiBox
                label="Onaylı"
                value={String(allRows.filter((r) => r.status === 'approved').length)}
              />
              <KpiBox label="Bekleyen" value={String(pendingCount)} warn={pendingCount > 0} />
            </div>

            {/* Puan dağılımı + durum filtresi */}
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
              <PanelBolumKarti>
                <p className="mb-3 text-xs font-[800] uppercase tracking-wider text-muted">Puan Dağılımı</p>
                <div className="flex flex-col gap-2">
                  {byRating.map(({ n, count }) => (
                    <Link
                      key={n}
                      href={ratingFilter === n ? '/sahip/yorumlar' : `/sahip/yorumlar?rating=${n}`}
                      className={`flex items-center gap-3 rounded-xl px-2 py-1.5 transition-colors hover:bg-bg
                        ${ratingFilter === n ? 'bg-bg ring-1 ring-border' : ''}`}
                    >
                      <span className="w-3 shrink-0 text-right text-xs font-[800] text-textStrong">{n}</span>
                      <div className="flex shrink-0 gap-0.5">
                        {[1, 2, 3, 4, 5].map((s) => (
                          <svg key={s} width="10" height="10" viewBox="0 0 24 24"
                            fill={s <= n ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2"
                            className={s <= n ? 'text-amber-400' : 'text-muted'}>
                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                          </svg>
                        ))}
                      </div>
                      <div className="h-1.5 min-w-0 flex-1 overflow-hidden rounded-full bg-bg">
                        <div
                          className="h-full rounded-full bg-amber-400 transition-all"
                          style={{ width: `${totalAll > 0 ? (count / totalAll) * 100 : 0}%` }}
                        />
                      </div>
                      <span className="w-5 shrink-0 text-right text-xs font-[600] text-muted">{count}</span>
                    </Link>
                  ))}
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti>
                <p className="mb-3 text-xs font-[800] uppercase tracking-wider text-muted">Durum Filtresi</p>
                <div className="flex flex-col gap-1">
                  {STATUS_TABS.map((tab) => {
                    const isActive = statusFilter === tab.key;
                    const count = tab.key === null
                      ? totalAll
                      : allRows.filter((r) => r.status === tab.key).length;
                    return (
                      <Link
                        key={tab.key ?? 'all'}
                        href={tab.key ? `/sahip/yorumlar?status=${tab.key}` : '/sahip/yorumlar'}
                        className={`flex items-center justify-between rounded-xl px-3 py-2.5 text-sm transition-colors
                          ${isActive
                            ? 'bg-primary/8 font-[700] text-primary'
                            : 'text-text hover:bg-bg'}`}
                      >
                        <span>{tab.label}</span>
                        <span className={`rounded-full px-2 py-0.5 text-xs font-[700]
                          ${isActive ? 'bg-primary text-white' : 'bg-bg text-muted'}`}>
                          {count}
                        </span>
                      </Link>
                    );
                  })}
                </div>
              </PanelBolumKarti>
            </div>

            {filteredRows.length === 0 ? (
              <PanelEmptyState
                icon={<StarIcon />}
                title="Bu filtreye uyan yorum yok"
                description="Farklı bir durum veya puan filtresi deneyin."
              />
            ) : (
              <PanelBolumKarti noPadding>
                <YorumlarIstemcisi
                  reviews={filteredRows}
                  businessMap={businessMap}
                  showBusinessName={showBusinessName}
                />
              </PanelBolumKarti>
            )}
          </>
        )}
      </PanelIcerikYuzeyi>
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
        ${warn ? 'text-amber-600' : accent ? 'text-primary' : 'text-textStrong'}`}>
        {value}
        {sub && <span className="text-sm font-[600] text-muted">{sub}</span>}
      </p>
    </div>
  );
}

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
