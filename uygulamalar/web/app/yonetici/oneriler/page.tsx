import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { OneriSatiriRow } from './oneri-satiri';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { yuzdeDegisim, durumAnahtari, type OneriSatiri, type DurumAnahtari } from './oneriler-yardimcilari';

export const metadata: Metadata = {
  title: 'Öneriler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; durum?: string; kategori?: string; sirala?: string; page?: string }> };
const PAGE_SIZE = 20;

const DURUM_SEKMELERI: Array<{ value: DurumAnahtari | ''; label: string }> = [
  { value: '', label: 'Tümü' },
  { value: 'pending', label: 'Bekleyen' },
  { value: 'approved', label: 'Değerlendirilen' },
  { value: 'rejected', label: 'Reddedilen' },
];

export default async function AdminSuggestionsPage({ searchParams }: Props) {
  const { q = '', durum = '', kategori = '', sirala = 'yeni', page = '1' } = await searchParams;
  const durumKey = DURUM_SEKMELERI.some((o) => o.value === durum) ? (durum as DurumAnahtari | '') : '';
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = (createSupabaseServiceClient() ?? supabase) as any;

  const buAyBasi = new Date(new Date().setDate(1)).toISOString();
  const gecenAyBasi = new Date(new Date(new Date().setDate(1)).setMonth(new Date().getMonth() - 1)).toISOString();

  const [
    { data: allRaw }, toplamRes, bekleyenRes, degerlendirilenRes, reddedilenRes,
    buAyRes, gecenAyRes, sonIslemlerRes,
  ] = await Promise.all([
    sb.from('business_suggestions').select('id, user_id, name, category, city, district, notes, status, created_at').order('created_at', { ascending: false }).limit(2000),
    sb.from('business_suggestions').select('id', { count: 'exact', head: true }),
    sb.from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    sb.from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    sb.from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
    sb.from('business_suggestions').select('id', { count: 'exact', head: true }).gte('created_at', buAyBasi),
    sb.from('business_suggestions').select('id', { count: 'exact', head: true }).gte('created_at', gecenAyBasi).lt('created_at', buAyBasi),
    sb.from('admin_audit_log').select('id, action, target_id, created_at').eq('target_table', 'business_suggestions').order('created_at', { ascending: false }).limit(6).then((r: any) => r).catch(() => ({ data: [] })),
  ]);

  const allRows = (allRaw ?? []) as Array<{
    id: string; user_id: string; name: string; category: string | null; city: string | null;
    district: string | null; notes: string | null; status: string; created_at: string;
  }>;

  const userIds = Array.from(new Set(allRows.map((r) => r.user_id).filter(Boolean)));
  const nameByUser = new Map<string, string>();
  if (userIds.length > 0) {
    const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', userIds);
    for (const p of (profiles ?? []) as Array<{ user_id: string; display_name: string | null }>) {
      nameByUser.set(p.user_id, p.display_name ?? '—');
    }
  }

  let rows: OneriSatiri[] = allRows.map((r) => ({
    id: r.id, name: r.name, category: r.category, city: r.city, district: r.district,
    note: r.notes, status: r.status, createdAt: r.created_at, submitterName: nameByUser.get(r.user_id) ?? null,
  }));

  if (durumKey) rows = rows.filter((r) => durumAnahtari(r.status) === durumKey);
  if (kategori) rows = rows.filter((r) => r.category === kategori);
  if (q.trim()) {
    const needle = q.trim().toLocaleLowerCase('tr-TR');
    rows = rows.filter((r) => [r.name, r.note, r.submitterName].filter(Boolean).join(' ').toLocaleLowerCase('tr-TR').includes(needle));
  }
  rows.sort((a, b) => sirala === 'eski' ? new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime() : new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  const totalPages = Math.max(1, Math.ceil(rows.length / PAGE_SIZE));
  const pageRows = rows.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  const toplam = toplamRes.count ?? 0;
  const bekleyen = bekleyenRes.count ?? 0;
  const degerlendirilen = degerlendirilenRes.count ?? 0;
  const reddedilen = reddedilenRes.count ?? 0;

  const kategoriler = Array.from(new Set(allRows.map((r) => r.category).filter(Boolean))).sort((a, b) => (a as string).localeCompare(b as string, 'tr-TR')) as string[];

  const donutHam: Array<[string, number, string]> = [
    ['Değerlendirilen', degerlendirilen, '#059669'],
    ['Bekleyen', bekleyen, '#d97706'],
    ['Reddedilen', reddedilen, '#dc2626'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const sonIslemler = (sonIslemlerRes?.data ?? []) as Array<{ id: string; action: string; target_id: string; created_at: string }>;
  const suggestionNameById = new Map(allRows.map((r) => [r.id, r.name]));

  const queryBase = buildQueryString({ q, durum: durumKey, kategori, sirala });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Öneriler"
        description="Kullanıcıların gönderdiği yeni işletme önerilerini görüntüleyin, onaylayın veya reddedin."
        actions={
          <div className="rounded-2xl border border-border bg-card px-4 py-3">
            <p className="text-[11px] font-bold text-muted">Toplam Öneri</p>
            <p className="text-2xl font-black text-textStrong">{toplam.toLocaleString('tr-TR')}</p>
            <p className="text-[11px] font-bold text-muted">Tüm zamanlar</p>
          </div>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <MetricCard title="Değerlendirilen" value={degerlendirilen.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((degerlendirilen / toplam) * 100)}` : undefined} tone="green" icon={<CheckIcon />} trend={{ value: yuzdeDegisim(buAyRes.count ?? 0, gecenAyRes.count ?? 0), label: 'Son 30 gün' }} />
            <MetricCard title="Bekleyen" value={bekleyen.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((bekleyen / toplam) * 100)}` : undefined} tone="orange" icon={<ClockIcon />} />
            <MetricCard title="Reddedilen" value={reddedilen.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((reddedilen / toplam) * 100)}` : undefined} tone="pink" icon={<XIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <div className="flex gap-2">
                {DURUM_SEKMELERI.map((o) => (
                  <Link
                    key={o.value}
                    href={`?${buildQueryString({ q, durum: o.value, kategori, sirala })}`}
                    className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${durumKey === o.value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'}`}
                  >
                    {o.label}
                  </Link>
                ))}
              </div>

              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-3">
                <input type="hidden" name="durum" value={durumKey} />
                <input type="hidden" name="page" value="1" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Öneri başlığı, not, kullanıcı ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                <select name="kategori" defaultValue={kategori} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Kategori: Tümü</option>
                  {kategoriler.map((k) => <option key={k} value={k}>{k}</option>)}
                </select>
                <select name="sirala" defaultValue={sirala} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="yeni">En Yeni</option>
                  <option value="eski">En Eski</option>
                </select>
                <div className="flex gap-2 md:col-span-3">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/oneriler" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Sıfırla</Link>
                </div>
              </form>

              {pageRows.length === 0 ? (
                <PanelEmptyState icon={<LightbulbIcon />} title="Öneri bulunamadı" description={q || durumKey || kategori ? 'Bu filtrelerle eşleşen öneri yok.' : 'Henüz gönderilmiş öneri yok.'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-border text-left">
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Öneri</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kategori</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
                          <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                          <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border">
                        {pageRows.map((r) => <OneriSatiriRow key={r.id} row={r} />)}
                      </tbody>
                    </table>
                  </div>
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {rows.length.toLocaleString('tr-TR')} kayıt</p>
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
              <PanelBolumKarti title="Durum Dağılımı">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <StatusDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Son İşlemler">
                {sonIslemler.length === 0 ? (
                  <p className="text-xs text-muted">Henüz kayıtlı işlem yok.</p>
                ) : (
                  <div className="flex flex-col gap-2.5">
                    {sonIslemler.map((a) => (
                      <div key={a.id} className="flex flex-col gap-0.5 text-xs">
                        <span className="font-bold text-textStrong">
                          {a.action === 'suggestion.approve' ? 'Onaylandı' : a.action === 'suggestion.reject' ? 'Reddedildi' : a.action} — {suggestionNameById.get(a.target_id) ?? `#${a.target_id.slice(0, 6)}`}
                        </span>
                        <span className="text-[11px] text-muted">{new Date(a.created_at).toLocaleString('tr-TR')}</span>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <Link href="/yonetici/isletmeler" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    İşletmeler <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/olaylar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Olaylar <ArrowIcon />
                  </Link>
                  <DisaAktarButonu rows={rows} />
                </div>
              </PanelBolumKarti>

              <PanelBolumKarti title="Bilgilendirme">
                <ul className="flex flex-col gap-2 text-xs text-muted">
                  <li>• Bu sayfa yalnızca yeni işletme önerilerini kapsar. Özellik/içerik önerisi için ayrı bir gerçek gönderim mekanizması şu an yok.</li>
                  <li>• Bir öneri onaylandığında gerçek bir işletme kaydı otomatik oluşturulur.</li>
                </ul>
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
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE} strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
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
function LightbulbIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="9" y1="18" x2="15" y2="18" /><line x1="10" y1="22" x2="14" y2="22" /><path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1 .23 2.23 1.5 3.5A4.61 4.61 0 0 1 8.91 14" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
