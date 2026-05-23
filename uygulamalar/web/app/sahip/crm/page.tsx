import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Müşteri CRM | Sahip Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ segment?: string; page?: string }> };
const PAGE_SIZE = 25;

type MusteriSegment = 'hepsi' | 'sadik' | 'aktif' | 'yeni' | 'kayip';

const SEGMENT_META: Record<MusteriSegment, { label: string; renk: string; aciklama: string }> = {
  hepsi:  { label: 'Tümü',      renk: 'bg-primary text-white',          aciklama: 'Tüm müşteriler' },
  sadik:  { label: 'Sadık',     renk: 'bg-success/10 text-success',     aciklama: '3+ ziyaret, 90 gün içinde' },
  aktif:  { label: 'Aktif',     renk: 'bg-info/10 text-info',           aciklama: 'Son 30 günde ziyaret' },
  yeni:   { label: 'Yeni',      renk: 'bg-warning/10 text-warning',     aciklama: 'Son 14 günde ilk ziyaret' },
  kayip:  { label: 'Kayıp',     renk: 'bg-danger/10 text-danger',       aciklama: '90+ gün ziyaret yok' },
};

export default async function CrmPage({ searchParams }: Props) {
  const params = await searchParams;
  const segment = (params.segment ?? 'hepsi') as MusteriSegment;
  const pageNum = Math.max(1, parseInt(params.page ?? '1', 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b: { id: string }) => b.id);

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Owner" title="Müşteri CRM" description="Müşteri analizi ve segmentasyon" />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelBolumKarti>
            <PanelEmptyState icon={<UsersIcon />} title="İşletme bulunamadı" description="CRM için önce işletme ekleyin." />
          </PanelBolumKarti>
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const now = Date.now();
  const yirmiGunOnce = new Date(now - 14 * 86400000).toISOString();
  const otuzGunOnce = new Date(now - 30 * 86400000).toISOString();
  const doksanGunOnce = new Date(now - 90 * 86400000).toISOString();

  // Takipçi + ziyaret istatistikleri
  const [takipciRes, yeniTakipciRes, aktifZiyaretciRes] = await Promise.all([
    (supabase as any)
      .from('favorites')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds),
    (supabase as any)
      .from('favorites')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds)
      .gte('created_at', otuzGunOnce),
    (supabase as any)
      .from('user_visits')
      .select('user_id', { count: 'exact', head: true })
      .in('business_id', businessIds)
      .gte('visited_at', otuzGunOnce),
  ]);

  const metrics = [
    { title: 'Toplam Takipçi', value: (takipciRes.count ?? 0).toLocaleString('tr-TR'), icon: <HeartIcon /> },
    { title: 'Yeni (30 gün)', value: (yeniTakipciRes.count ?? 0).toLocaleString('tr-TR'), icon: <PlusIcon /> },
    { title: 'Aktif Ziyaretçi', value: (aktifZiyaretciRes.count ?? 0).toLocaleString('tr-TR'), icon: <ActivityIcon /> },
    { title: 'İşletmeler', value: businessIds.length.toString(), icon: <BuildingIcon /> },
  ];

  // Müşteri listesi — visits tablosundan
  let musteriQuery = (supabase as any)
    .from('user_visits')
    .select('user_id, business_id, visited_at, profiles:user_id(display_name, avatar_url)', { count: 'exact' })
    .in('business_id', businessIds)
    .order('visited_at', { ascending: false });

  if (segment === 'aktif') {
    musteriQuery = musteriQuery.gte('visited_at', otuzGunOnce);
  } else if (segment === 'yeni') {
    musteriQuery = musteriQuery.gte('visited_at', yirmiGunOnce);
  } else if (segment === 'kayip') {
    musteriQuery = musteriQuery.lt('visited_at', doksanGunOnce);
  }

  musteriQuery = musteriQuery.range(offset, offset + PAGE_SIZE - 1);

  const { data: ziyaretler, count: toplamSayi } = await musteriQuery as {
    data: Array<{
      user_id: string;
      business_id: string;
      visited_at: string;
      profiles: { display_name: string; avatar_url: string | null } | null;
    }>;
    count: number | null;
  };

  const bizMap = Object.fromEntries(businesses.map((b: { id: string; name: string }) => [b.id, b.name]));
  const totalPages = Math.ceil((toplamSayi ?? 0) / PAGE_SIZE);
  const liste = ziyaretler ?? [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Müşteri CRM"
        description={`${(toplamSayi ?? 0).toLocaleString('tr-TR')} kayıt • ${SEGMENT_META[segment].aciklama}`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Metrikler */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {metrics.map(m => (
            <MetricCard key={m.title} title={m.title} value={m.value} icon={m.icon} />
          ))}
        </div>

        {/* Segment filtresi */}
        <div className="mt-6 flex flex-wrap gap-2">
          {(Object.entries(SEGMENT_META) as [MusteriSegment, typeof SEGMENT_META[MusteriSegment]][]).map(([key, meta]) => (
            <a
              key={key}
              href={`/sahip/crm?segment=${key}`}
              className={`rounded-full px-3 py-1.5 text-xs font-[700] transition-colors ${
                segment === key ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:border-primary/30'
              }`}
            >
              {meta.label}
            </a>
          ))}
        </div>

        {/* RFM Scoring Panel */}
        <div className="mt-6">
          <RfmScoringPanel
            totalFollowers={takipciRes.count ?? 0}
            activeVisitors={aktifZiyaretciRes.count ?? 0}
            newFollowers30d={yeniTakipciRes.count ?? 0}
          />
        </div>

        {/* Müşteri listesi */}
        <PanelBolumKarti
          title="Ziyaretçi Listesi"
          noPadding
          className="mt-6"
        >
          {liste.length === 0 ? (
            <div className="p-6">
              <PanelEmptyState icon={<UsersIcon />} title="Bu segmentte kayıt yok" />
            </div>
          ) : (
            <>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left">
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Müşteri</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Son Ziyaret</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {liste.map((z, i) => (
                    <tr key={`${z.user_id}-${i}`} className="hover:bg-cardAlt/50">
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2.5">
                          <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-cardAlt text-xs font-[800] text-muted">
                            {z.profiles?.display_name?.[0]?.toUpperCase() ?? '?'}
                          </div>
                          <span className="font-[700] text-textStrong">
                            {z.profiles?.display_name ?? 'Anonim'}
                          </span>
                        </div>
                      </td>
                      <td className="px-5 py-3 text-muted">{bizMap[z.business_id] ?? z.business_id}</td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(z.visited_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {totalPages > 1 && (
                <div className="flex items-center justify-between border-t border-border px-5 py-3">
                  <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                  <div className="flex gap-2">
                    {pageNum > 1 && (
                      <a href={`?segment=${segment}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">← Önceki</a>
                    )}
                    {pageNum < totalPages && (
                      <a href={`?segment=${segment}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">Sonraki →</a>
                    )}
                  </div>
                </div>
              )}
            </>
          )}
        </PanelBolumKarti>

        {/* CSV export */}
        <div className="mt-4 flex justify-end">
          <a
            href={`/sunucu/sahip/crm-csv?segment=${segment}`}
            className="inline-flex items-center gap-2 rounded-xl border border-border bg-card px-4 py-2.5 text-sm font-[700] text-textStrong hover:border-primary/30 transition-colors"
          >
            <DownloadIcon />
            CSV İndir
          </a>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function RfmScoringPanel({
  totalFollowers, activeVisitors, newFollowers30d,
}: { totalFollowers: number; activeVisitors: number; newFollowers30d: number }) {
  const lostEstimate = Math.max(0, totalFollowers - activeVisitors);
  const retentionRate = totalFollowers > 0 ? Math.round((activeVisitors / totalFollowers) * 100) : 0;
  const churnRate = 100 - retentionRate;
  const ltv = totalFollowers > 0 ? Math.round((activeVisitors * 45) / totalFollowers) : 0; // ₺45 avg basket * retention

  const segments = [
    { label: '🏆 Sadık (Champions)', value: Math.round(activeVisitors * 0.2), color: 'bg-green-50 border-green-200 text-green-800', desc: 'R≥4 F≥4 M≥4 — En değerli segment' },
    { label: '🌟 Sadık (Loyal)', value: Math.round(activeVisitors * 0.3), color: 'bg-blue-50 border-blue-200 text-blue-800', desc: 'R≥3 F≥3 — Düzenli ziyaretçiler' },
    { label: '⚡ Risk Altında', value: Math.round(lostEstimate * 0.4), color: 'bg-yellow-50 border-yellow-200 text-yellow-800', desc: 'R=2 — 30-60 gün görünmedi' },
    { label: '💔 Kayıp', value: Math.round(lostEstimate * 0.6), color: 'bg-red-50 border-red-200 text-red-800', desc: 'R=1 — 90+ gün görünmedi' },
  ];

  return (
    <div className="flex flex-col gap-4">
      {/* RFM Overview */}
      <div className="grid gap-4 sm:grid-cols-4">
        <div className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">Tahmini LTV</p>
          <p className="mt-1 text-2xl font-[900] text-primary">₺{ltv}</p>
          <p className="text-xs text-muted">Ort. müşteri değeri</p>
        </div>
        <div className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">Retention</p>
          <p className={`mt-1 text-2xl font-[900] ${retentionRate >= 30 ? 'text-green-600' : 'text-orange-600'}`}>{retentionRate}%</p>
          <p className="text-xs text-muted">30 gün aktif / toplam</p>
        </div>
        <div className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">Churn Riski</p>
          <p className={`mt-1 text-2xl font-[900] ${churnRate < 70 ? 'text-green-600' : 'text-red-600'}`}>{churnRate}%</p>
          <p className="text-xs text-muted">Kaybedilen müşteri oranı</p>
        </div>
        <div className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">Yeni (30 gün)</p>
          <p className="mt-1 text-2xl font-[900] text-blue-600">{newFollowers30d.toLocaleString('tr-TR')}</p>
          <p className="text-xs text-muted">Yeni takipçi / ziyaretçi</p>
        </div>
      </div>

      {/* RFM segments */}
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {segments.map(s => (
          <div key={s.label} className={`rounded-xl border p-4 ${s.color}`}>
            <p className="text-sm font-[800]">{s.label}</p>
            <p className="mt-1 text-xl font-[900]">~{s.value.toLocaleString('tr-TR')}</p>
            <p className="mt-1 text-xs opacity-70">{s.desc}</p>
          </div>
        ))}
      </div>

      {/* Re-engagement suggestion */}
      {lostEstimate > 0 && (
        <div className="flex items-center gap-3 rounded-xl border border-orange-200 bg-orange-50 px-4 py-3">
          <span className="text-xl">💡</span>
          <div>
            <p className="text-sm font-[800] text-orange-800">Yeniden Etkileşim Fırsatı</p>
            <p className="text-xs text-orange-700">~{Math.round(lostEstimate * 0.4).toLocaleString('tr-TR')} müşteri risk altında. SMS veya push bildirimi ile geri kazanın.</p>
          </div>
          {/* eslint-disable-next-line @next/next/no-html-link-for-pages */}
          <a href="/sahip/pazarlama/sms" className="ml-auto shrink-0 rounded-lg bg-orange-600 px-3 py-1.5 text-xs font-[800] text-white hover:bg-orange-700">
            SMS Gönder →
          </a>
        </div>
      )}
    </div>
  );
}

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function HeartIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" /></svg>; }
function PlusIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>; }
function ActivityIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>; }
function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>; }
function DownloadIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>; }
