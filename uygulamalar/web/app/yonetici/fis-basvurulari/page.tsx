import type { Metadata } from 'next';
import Link from 'next/link';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import {
  listAdminFisGonderimleri,
  getAdminFisGonderimOzeti,
} from '@/src/lib/veri/admin/fis-gonderimleri';
import { FisTablosu } from './fis-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';

export const metadata: Metadata = {
  title: 'Fiş Başvuruları | Yönetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; status?: string; chain?: string; page?: string }> };
const PAGE_SIZE = 10;

const STATUS_OPTIONS = [
  { value: '', label: 'Durum: Tümü' },
  { value: 'pending', label: 'Bekliyor' },
  { value: 'needs_followup', label: 'Takip Gerekli' },
  { value: 'reviewed', label: 'İncelendi' },
];

export default async function FisBasvurulariSayfasi({ searchParams }: Props) {
  const yetkili = await hasPermission('page:fis-basvurulari');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Fiş Başvuruları" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Fiş Başvuruları" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', status = '', chain = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);

  const [{ list: allList, fetchError }, ozet] = await Promise.all([
    listAdminFisGonderimleri({ reviewStatus: 'all', limit: 300, offset: 0 }),
    getAdminFisGonderimOzeti(),
  ]);

  let filtered = allList;
  if (status) filtered = filtered.filter((r) => r.review_status === status);
  if (chain) filtered = filtered.filter((r) => r.chain_name === chain);
  if (q.trim()) {
    const needle = q.trim().toLocaleLowerCase('tr-TR');
    filtered = filtered.filter((r) =>
      [r.business_name, r.chain_name, r.submitter_display, r.city, r.district].filter(Boolean).join(' ').toLocaleLowerCase('tr-TR').includes(needle),
    );
  }

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const pageRows = filtered.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  const chains = Array.from(new Set(allList.map((r) => r.chain_name).filter((c): c is string => Boolean(c)))).sort((a, b) => a.localeCompare(b, 'tr-TR'));

  const durumSayilari = new Map<string, number>();
  for (const r of allList) durumSayilari.set(r.review_status, (durumSayilari.get(r.review_status) ?? 0) + 1);
  const donutHam: Array<[string, number, string]> = [
    ['Bekliyor', durumSayilari.get('pending') ?? 0, '#d97706'],
    ['Takip Gerekli', durumSayilari.get('needs_followup') ?? 0, '#2563eb'],
    ['İncelendi', durumSayilari.get('reviewed') ?? 0, '#059669'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const otuzGunOnce = Date.now() - 30 * 86400000;
  const gunlukSayim: Record<string, number> = {};
  for (const r of allList) {
    const t = new Date(r.created_at).getTime();
    if (t < otuzGunOnce) continue;
    const d = new Date(r.created_at);
    const gun = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    gunlukSayim[gun] = (gunlukSayim[gun] ?? 0) + 1;
  }
  const trendVerisi: { label: string; value: number }[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    const label = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    trendVerisi.push({ label, value: gunlukSayim[label] ?? 0 });
  }

  const queryBase = buildQueryString({ q, status, chain });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Fiş Başvuruları"
        description="Müşterilerin fiyat doğrulama için yüklediği fişleri inceleyin ve yönetin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        {fetchError ? (
          <PanelEmptyState icon={<FisIkonu />} title="Fiş başvuruları okunamadı" description="RPC erişimi veya yetki kontrolü başarısız oldu." />
        ) : (
          <div className="flex flex-col gap-6">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
              <MetricCard title="Tümü" value={ozet.total_count.toLocaleString('tr-TR')} subtitle="tüm başvurular" tone="blue" icon={<UsersIcon />} />
              <MetricCard title="Bekliyor" value={ozet.pending_count.toLocaleString('tr-TR')} subtitle={ozet.total_count > 0 ? `%${Math.round((ozet.pending_count / ozet.total_count) * 100)}` : undefined} tone="orange" icon={<ClockIcon />} />
              <MetricCard title="Takip Gerekli" value={ozet.needs_followup_count.toLocaleString('tr-TR')} subtitle={ozet.total_count > 0 ? `%${Math.round((ozet.needs_followup_count / ozet.total_count) * 100)}` : undefined} tone="purple" icon={<FlagIcon />} />
              <MetricCard title="İncelendi" value={ozet.reviewed_count.toLocaleString('tr-TR')} subtitle={ozet.total_count > 0 ? `%${Math.round((ozet.reviewed_count / ozet.total_count) * 100)}` : undefined} tone="green" icon={<CheckIcon />} />
              <MetricCard title="Eşleşmeyen" value={ozet.zero_match_count.toLocaleString('tr-TR')} subtitle="ürün bulunamadı" tone="pink" icon={<XIcon />} />
            </div>

            <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
              <div className="flex min-w-0 flex-col gap-4">
                <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                  <input name="page" value="1" type="hidden" />
                  <input
                    name="q"
                    defaultValue={q}
                    placeholder="İşletme, zincir veya kullanıcı ara..."
                    className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                  />
                  <select name="status" defaultValue={status} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                    {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                  </select>
                  <select name="chain" defaultValue={chain} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                    <option value="">Zincir: Tümü</option>
                    {chains.map((c) => <option key={c} value={c}>{c}</option>)}
                  </select>
                  <div className="flex gap-2 lg:col-span-4">
                    <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                    <Link href="/yonetici/fis-basvurulari" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                  </div>
                </form>

                {pageRows.length === 0 ? (
                  <PanelEmptyState
                    icon={<FisIkonu />}
                    title="Başvuru yok"
                    description={q || status || chain ? 'Bu filtrelerle eşleşen başvuru yok.' : 'Henüz fiş başvurusu alınmamış.'}
                  />
                ) : (
                  <PanelBolumKarti noPadding>
                    <FisTablosu rows={pageRows} />
                    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                      <p className="text-xs font-bold text-muted">Toplam {filtered.length.toLocaleString('tr-TR')} başvuru</p>
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
                  {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <DurumDonut veriler={donutVerisi} toplam={donutToplam} />}
                </PanelBolumKarti>

                <PanelBolumKarti title="Son 30 Gün Trend">
                  <TrendGrafik veriler={trendVerisi} />
                  <p className="mt-2 text-xs font-bold text-muted">Toplam {ozet.recent_24h_count.toLocaleString('tr-TR')} · son 24 saat</p>
                </PanelBolumKarti>

                <PanelBolumKarti title="Hızlı İşlemler">
                  <div className="flex flex-col gap-2">
                    <Link href="/yonetici/olaylar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                      <span>Olaylar<span className="block text-[10px] font-bold text-muted">Durum değişikliği geçmişi</span></span>
                      <ArrowIcon />
                    </Link>
                    <DisaAktarButonu rows={filtered} />
                  </div>
                </PanelBolumKarti>

                <div className="rounded-2xl border border-blue-200 bg-blue-50 p-4">
                  <p className="mb-2 text-sm font-black text-blue-900">Notlar</p>
                  <ul className="flex flex-col gap-1.5 text-xs text-blue-800">
                    <li>Kullanıcı kimliği gizlilik nedeniyle maskelenir.</li>
                    <li>Eşleşme sayısı 0 olan fişler menü ile eşleştirilemedi, öncelikli incelenmeli.</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function buildQueryString(input: Record<string, string>) {
  const params = new URLSearchParams();
  Object.entries(input).forEach(([key, value]) => { if (value) params.set(key, value); });
  return params.toString();
}

function TrendGrafik({ veriler }: { veriler: { label: string; value: number }[] }) {
  const W = 260, H = 90;
  const pad = { l: 4, r: 4, t: 8, b: 4 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;
  const maxVal = Math.max(...veriler.map((v) => v.value), 1);
  const stepX = innerW / Math.max(veriler.length - 1, 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;
  const linePath = veriler.map((v, i) => `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(v.value)}`).join(' ');

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="w-full">
      <path d={linePath} fill="none" stroke="#dc2626" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
    </svg>
  );
}

function DurumDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
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

function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>; }
function FlagIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function XIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
function FisIkonu() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /><line x1="16" y1="13" x2="8" y2="13" /><line x1="16" y1="17" x2="8" y2="17" /></svg>; }
