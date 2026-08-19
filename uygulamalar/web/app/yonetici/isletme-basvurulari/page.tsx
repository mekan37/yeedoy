import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { BasvurularTablosu } from './basvurular-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { durumAnahtari, yuzdeDegisim, type BasvuruSatiri, type DurumAnahtari } from './basvurular-yardimcilari';

export const metadata: Metadata = {
  title: 'İşletme Talepleri | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; status?: string; date_from?: string; date_to?: string; page?: string }> };

const STATUS_OPTIONS: Array<{ value: DurumAnahtari | ''; label: string }> = [
  { value: '', label: 'Tüm Durumlar' },
  { value: 'pending', label: 'Beklemede' },
  { value: 'reviewing', label: 'İncelemede' },
  { value: 'approved', label: 'Onaylandı' },
  { value: 'rejected', label: 'Reddedildi' },
];
const PAGE_SIZE = 10;

export default async function AdminBusinessSubmissionsPage({ searchParams }: Props) {
  const { q = '', status = '', date_from = '', date_to = '', page = '1' } = await searchParams;
  const statusKey = STATUS_OPTIONS.some((o) => o.value === status) ? (status as DurumAnahtari | '') : '';
  const pageNum = Math.max(1, parseInt(page, 10) || 1);

  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const rpcStatus = statusKey === 'pending' || statusKey === 'reviewing' ? 'new' : statusKey || null;

  const buAyBasi = new Date(new Date().setDate(1)).toISOString();
  const gecenAyBasi = new Date(new Date(new Date().setDate(1)).setMonth(new Date().getMonth() - 1)).toISOString();

  const [
    listRes,
    toplamRes,
    bekleyenRes,
    onaylananRes,
    reddedilenRes,
    buAyRes,
    gecenAyRes,
  ] = await Promise.all([
    sb.rpc('admin_list_business_submissions_v2', {
      p_status: rpcStatus,
      p_limit: 200,
      p_offset: 0,
      p_q: q.trim() || null,
      p_date_from: date_from ? new Date(date_from).toISOString() : null,
      p_date_to: date_to ? new Date(date_to).toISOString() : null,
      p_sort_key: 'created_at',
      p_sort_ascending: false,
    }),
    sb.from('business_submissions').select('id', { count: 'exact', head: true }),
    sb.from('business_submissions').select('id', { count: 'exact', head: true }).eq('status', 'new').is('assigned_to', null),
    sb.from('business_submissions').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    sb.from('business_submissions').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
    sb.from('business_submissions').select('id', { count: 'exact', head: true }).gte('created_at', buAyBasi),
    sb.from('business_submissions').select('id', { count: 'exact', head: true }).gte('created_at', gecenAyBasi).lt('created_at', buAyBasi),
  ]);

  const rawList = (listRes.data ?? []) as Array<{
    id: string; submitted_by: string; name: string; city: string; district: string; category: string;
    status: string; created_at: string;
  }>;

  const userIds = Array.from(new Set(rawList.map((r) => r.submitted_by)));
  let nameByUser = new Map<string, string>();
  if (userIds.length > 0) {
    const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', userIds);
    nameByUser = new Map((profiles ?? []).map((p: any) => [p.user_id as string, (p.display_name as string) ?? '—']));
  }

  // assigned_to (İncelemede olanlar) için ayrı sorgu — RPC bu kolonu döndürmüyor
  const { data: assignedRows } = await sb.from('business_submissions').select('id, assigned_to').eq('status', 'new').not('assigned_to', 'is', null).in('id', rawList.map((r) => r.id));
  const assignedByOwn = new Map((assignedRows ?? []).map((a: any) => [a.id as string, a.assigned_to as string]));

  const allRows: BasvuruSatiri[] = rawList.map((r) => ({
    id: r.id, name: r.name, category: r.category, city: r.city, district: r.district,
    status: r.status, createdAt: r.created_at, submittedByName: nameByUser.get(r.submitted_by) ?? null,
    assignedToName: assignedByOwn.has(r.id) ? 'Bir yönetici' : null,
  }));

  const filtered = statusKey
    ? allRows.filter((r) => durumAnahtari(r) === statusKey)
    : allRows;
  const incelemedeSayisi = allRows.filter((r) => durumAnahtari(r) === 'reviewing').length;

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const pageRows = filtered.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  const toplam = toplamRes.count ?? 0;
  const bekleyen = bekleyenRes.count ?? 0;
  const onaylanan = onaylananRes.count ?? 0;
  const reddedilen = reddedilenRes.count ?? 0;

  const donutToplam = onaylanan + bekleyen + reddedilen + incelemedeSayisi;
  const donutVerisi: Array<[string, number, string]> = [
    ['Onaylandı', onaylanan, '#059669'],
    ['Beklemede', bekleyen, '#d97706'],
    ['Reddedildi', reddedilen, '#dc2626'],
    ['İncelemede', incelemedeSayisi, '#7c3aed'],
  ].filter(([, n]) => n > 0) as Array<[string, number, string]>;

  const queryBase = buildQueryString({ q, status: statusKey, date_from, date_to });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="İşletme Talepleri"
        description="Yeni başvuran işletme taleplerini görüntüleyin, onaylayın veya reddedin."
        actions={
          <div className="rounded-2xl border border-border bg-card px-4 py-3">
            <p className="text-[11px] font-bold text-muted">Toplam Talep</p>
            <p className="text-2xl font-black text-textStrong">{toplam.toLocaleString('tr-TR')}</p>
            <p className="text-[11px] font-bold text-emerald-600">
              {yuzdeDegisim(buAyRes.count ?? 0, gecenAyRes.count ?? 0) >= 0 ? '↑' : '↓'} %{Math.abs(yuzdeDegisim(buAyRes.count ?? 0, gecenAyRes.count ?? 0))} son 30 günde
            </p>
          </div>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <MetricCard title="Bekleyen" value={bekleyen.toLocaleString('tr-TR')} tone="orange" icon={<ClockIcon />} />
            <MetricCard title="Onaylanan" value={onaylanan.toLocaleString('tr-TR')} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Reddedilen" value={reddedilen.toLocaleString('tr-TR')} tone="pink" icon={<XIcon />} />
            <MetricCard title="İncelemede" value={incelemedeSayisi.toLocaleString('tr-TR')} tone="purple" icon={<EyeIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-5">
                <input name="page" value="1" type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="İşletme adı, başvuru no..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="status" defaultValue={statusKey} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <input type="date" name="date_from" defaultValue={date_from} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
                <input type="date" name="date_to" defaultValue={date_to} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
                <div className="flex gap-2 lg:col-span-5">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/isletme-basvurulari" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Sıfırla</Link>
                </div>
              </form>

              <div className="flex items-center justify-between">
                <p className="text-xs font-bold text-muted">İşletme Talepleri ({filtered.length})</p>
              </div>

              {pageRows.length === 0 ? (
                <PanelEmptyState icon={<InboxIcon />} title="Talep bulunamadı" description={q || statusKey ? 'Bu filtrelerle eşleşen talep yok.' : 'Henüz başvuru yapılmamış.'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <BasvurularTablosu rows={pageRows} />
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {filtered.length} kayıt</p>
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
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="grid grid-cols-1 gap-2">
                  <Link href="/yonetici/isletmeler/yeni" className="flex items-center justify-between rounded-xl px-3 py-2.5 text-xs font-extrabold text-white transition-opacity hover:opacity-90" style={{ background: 'linear-gradient(135deg, #dc2626, #991b1b)' }}>
                    Yeni İşletme Ekle <ArrowIcon />
                  </Link>
                  <Link href="#toplu-islemler" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Toplu İşlem Yap <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/zincirler/yeni" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Zincir Oluştur <ArrowIcon />
                  </Link>
                  <DisaAktarButonu rows={filtered} />
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Durum Dağılımı">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <StatusDonut veriler={donutVerisi} toplam={donutToplam} />}
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

function StatusDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
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

function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function XIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></svg>; }
function EyeIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>; }
function InboxIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12" /><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
