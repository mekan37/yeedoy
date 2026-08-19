import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { OzelRaporOlusturucu } from './ozel-rapor-istemci';
import { RaporlarTablosu } from './raporlar-tablosu';
import { yuzdeDegisim, DURUM_ETIKETLERI, HEDEF_ETIKETLERI, type RaporSatiri, type HedefTuru } from './raporlar-yardimcilari';

export const metadata: Metadata = {
  title: 'Raporlar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; status?: string; hedef?: string; page?: string }> };

const STATUS_OPTIONS = [
  { value: '', label: 'Tüm Durumlar' },
  { value: 'open', label: 'Beklemede' },
  { value: 'reviewing', label: 'İnceleniyor' },
  { value: 'closed', label: 'Kapatıldı' },
] as const;

const HEDEF_OPTIONS: Array<{ value: HedefTuru | ''; label: string }> = [
  { value: '', label: 'Tüm Kategoriler' },
  { value: 'business', label: 'İşletme' },
  { value: 'review', label: 'Yorum' },
  { value: 'menu_item_photo', label: 'Menü Fotoğrafı' },
];

const PAGE_SIZE = 10;

export default async function AdminReportsPage({ searchParams }: Props) {
  const { q = '', status = '', hedef = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const buAyBasi = new Date(new Date().setDate(1)).toISOString();
  const gecenAyBasi = new Date(new Date(new Date().setDate(1)).setMonth(new Date().getMonth() - 1)).toISOString();

  const [
    listRes,
    toplamRes,
    acikRes,
    incelenenRes,
    kapatilanRes,
    buAyRes,
    gecenAyRes,
  ] = await Promise.all([
    sb.rpc('admin_list_reports_v5', { p_status: status || null, p_limit: 200, p_offset: 0, p_q: q.trim() || null }),
    sb.from('reports').select('id', { count: 'exact', head: true }),
    sb.from('reports').select('id', { count: 'exact', head: true }).eq('status', 'open'),
    sb.from('reports').select('id', { count: 'exact', head: true }).eq('status', 'reviewing'),
    sb.from('reports').select('id', { count: 'exact', head: true }).eq('status', 'closed'),
    sb.from('reports').select('id', { count: 'exact', head: true }).gte('created_at', buAyBasi),
    sb.from('reports').select('id', { count: 'exact', head: true }).gte('created_at', gecenAyBasi).lt('created_at', buAyBasi),
  ]);

  let rawList = (listRes.data ?? []) as Array<{
    id: string; created_at: string; status: string; reason: string; details: string | null;
    user_id: string | null; business_id: string | null; review_id: string | null;
    target_type: string; age_hours: number; sla_breached: boolean;
  }>;

  if (hedef) rawList = rawList.filter((r) => r.target_type === hedef);

  const ids = rawList.map((r) => r.id);
  let reporterByReport = new Map<string, string>();
  if (ids.length > 0) {
    // reporter_user_id web'den (RLS insert), user_id mobilden (submit_report_v2 RPC) geliyor —
    // ikisi de "raporlayan" anlamına geliyor, codebase'de zaten coalesce(user_id, reporter_user_id) emsali var.
    const { data: reporterRows } = await sb.from('reports').select('id, reporter_user_id, user_id').in('id', ids);
    const reporterOfReport = new Map<string, string>(
      ((reporterRows ?? []) as any[])
        .map((r) => [r.id as string, (r.reporter_user_id ?? r.user_id) as string | null])
        .filter((entry): entry is [string, string] => Boolean(entry[1])),
    );
    const reporterUserIds = Array.from(new Set(reporterOfReport.values()));
    if (reporterUserIds.length > 0) {
      const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', reporterUserIds);
      const nameByUser = new Map<string, string>((profiles ?? []).map((p: any) => [p.user_id as string, (p.display_name as string) ?? '—']));
      for (const [reportId, userId] of reporterOfReport) {
        reporterByReport.set(reportId, nameByUser.get(userId) ?? '—');
      }
    }
  }

  const businessIds = Array.from(new Set(rawList.filter((r) => r.target_type === 'business' && r.business_id).map((r) => r.business_id as string)));
  const reviewIds = Array.from(new Set(rawList.filter((r) => r.target_type === 'review' && r.review_id).map((r) => r.review_id as string)));
  const [{ data: businessRows }, { data: reviewRows }] = await Promise.all([
    businessIds.length > 0 ? sb.from('businesses').select('id, name').in('id', businessIds) : Promise.resolve({ data: [] }),
    reviewIds.length > 0 ? sb.from('reviews').select('id, business_id').in('id', reviewIds) : Promise.resolve({ data: [] }),
  ]);
  const businessNameById = new Map<string, string>((businessRows ?? []).map((b: any) => [b.id as string, b.name as string]));
  const reviewBusinessId = new Map<string, string>((reviewRows ?? []).map((r: any) => [r.id as string, r.business_id as string]));

  function targetLabel(r: { target_type: string; business_id: string | null; review_id: string | null }): string | null {
    if (r.target_type === 'business' && r.business_id) return businessNameById.get(r.business_id) ?? null;
    if (r.target_type === 'review' && r.review_id) {
      const bizId = reviewBusinessId.get(r.review_id);
      return bizId ? (businessNameById.get(bizId) ?? 'Yorum') : 'Yorum';
    }
    if (r.target_type === 'menu_item_photo') return 'Menü Fotoğrafı';
    return null;
  }

  const allRows: RaporSatiri[] = rawList.map((r) => ({
    id: r.id, reason: r.reason, details: r.details, status: r.status, targetType: r.target_type,
    createdAt: r.created_at, reporterName: reporterByReport.get(r.id) ?? null,
    targetLabel: targetLabel(r), ageHours: r.age_hours, slaBreached: r.sla_breached,
  }));

  const totalPages = Math.max(1, Math.ceil(allRows.length / PAGE_SIZE));
  const pageRows = allRows.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  let sonGuncellemeler: Array<{ id: string; action: string; target_id: string | null; created_at: string; meta: any }> = [];
  try {
    const { data, error } = await sb
      .from('admin_audit_log')
      .select('id, action, target_id, created_at, meta')
      .eq('target_table', 'reports')
      .order('created_at', { ascending: false })
      .limit(5);
    if (!error) sonGuncellemeler = data ?? [];
  } catch {
    // admin_audit_log henüz mevcut değilse sessizce boş bırak
  }

  const hedefSayilari = new Map<string, number>();
  for (const r of allRows) hedefSayilari.set(r.targetType, (hedefSayilari.get(r.targetType) ?? 0) + 1);
  const donutToplam = Array.from(hedefSayilari.values()).reduce((a, b) => a + b, 0);
  const donutHam: Array<[string, number, string]> = [
    ['İşletme', hedefSayilari.get('business') ?? 0, '#dc2626'],
    ['Yorum', hedefSayilari.get('review') ?? 0, '#2563eb'],
    ['Menü Fotoğrafı', hedefSayilari.get('menu_item_photo') ?? 0, '#7c3aed'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);

  const queryBase = buildQueryString({ q, status, hedef });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Raporlar"
        description="Kullanıcı ve işletme raporlarını inceleyin ve yönetin."
        actions={
          <a
            href={`/sunucu/yonetici/raporlar-csv?status=${status || 'all'}&hedef=${hedef}`}
            className="inline-flex min-h-11 items-center gap-1.5 rounded-xl border border-border bg-card px-4 text-sm font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
          >
            <DownloadIcon /> Dışa Aktar
          </a>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <MetricCard title="Toplam Rapor" value={(toplamRes.count ?? 0).toLocaleString('tr-TR')} tone="pink" icon={<FlagIcon />}
              trend={{ value: yuzdeDegisim(buAyRes.count ?? 0, gecenAyRes.count ?? 0), label: 'önceki 30 güne göre' }} />
            <MetricCard title="Beklemede" value={(acikRes.count ?? 0).toLocaleString('tr-TR')} subtitle="inceleme bekliyor" tone="orange" icon={<ClockIcon />} />
            <MetricCard title="İnceleniyor" value={(incelenenRes.count ?? 0).toLocaleString('tr-TR')} subtitle="admin incelemesinde" tone="blue" icon={<EyeIcon />} />
            <MetricCard title="Kapatıldı" value={(kapatilanRes.count ?? 0).toLocaleString('tr-TR')} subtitle="çözüldü / reddedildi" tone="green" icon={<CheckIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <div className="flex gap-2 border-b border-border">
                {STATUS_OPTIONS.map((o) => (
                  <Link
                    key={o.value}
                    href={`/yonetici/raporlar?${buildQueryString({ q, status: o.value, hedef })}`}
                    className={`border-b-2 px-1 pb-3 text-sm font-extrabold transition-colors ${status === o.value ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong'}`}
                  >
                    {o.label}
                  </Link>
                ))}
              </div>

              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                <input name="page" value="1" type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Rapor ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="status" defaultValue={status} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <select name="hedef" defaultValue={hedef} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {HEDEF_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <div className="flex gap-2 lg:col-span-4">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/raporlar" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              {pageRows.length === 0 ? (
                <PanelEmptyState icon={<FlagIcon />} title="Rapor bulunamadı" description={q || status || hedef ? 'Bu filtrelerle eşleşen rapor yok.' : 'Henüz kullanıcı raporu yok.'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <RaporlarTablosu rows={pageRows} />
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {allRows.length} rapor</p>
                    {totalPages > 1 && (
                      <div className="flex items-center gap-1">
                        {pageNum > 1 && <Link href={`?${queryBase}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</Link>}
                        <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                        {pageNum < totalPages && <Link href={`?${queryBase}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</Link>}
                      </div>
                    )}
                  </div>
                </PanelBolumKarti>
              )}

              <PanelBolumKarti title="Özel Rapor Oluşturucu" description="Analitik raporları filtreleyip dışa aktarın">
                <OzelRaporOlusturucu />
              </PanelBolumKarti>
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Rapor Özeti" description="Hedef türüne göre kırılım">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <HedefDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="grid grid-cols-1 gap-2">
                  <Link href="#toplu-islemler" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Toplu İşlemler <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/analitik" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Rapor İstatistikleri <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/olaylar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    İşlem Geçmişi <ArrowIcon />
                  </Link>
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Son Güncellemeler">
                {sonGuncellemeler.length === 0 ? (
                  <p className="text-xs text-muted">Henüz kayıtlı güncelleme yok.</p>
                ) : (
                  <div className="flex flex-col gap-3">
                    {sonGuncellemeler.map((g) => (
                      <div key={g.id} className="flex items-center justify-between gap-2">
                        <p className="text-xs font-bold text-textStrong">
                          {g.action === 'report.bulk_update'
                            ? `${g.meta?.count ?? ''} rapor toplu güncellendi`
                            : `Rapor ${DURUM_ETIKETLERI[(g.meta?.status ?? 'open') as keyof typeof DURUM_ETIKETLERI] ?? g.meta?.status ?? ''}`}
                        </p>
                        <span className="shrink-0 text-[11px] text-muted">{new Date(g.created_at).toLocaleDateString('tr-TR')}</span>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => { if (value) params.set(key, value); });
  return params.toString();
}

function HedefDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label, , renk], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE}
              strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
          ))}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">{toplam.toLocaleString('tr-TR')}</text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">Toplam</text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, n, renk]) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: renk }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{Math.round((n / toplam) * 100)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function FlagIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>; }
function EyeIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
function DownloadIcon() { return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>; }
