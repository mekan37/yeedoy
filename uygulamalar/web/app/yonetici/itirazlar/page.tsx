import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { ItirazlarTablosu } from './itirazlar-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { itirazDurumu, yuzdeDegisim, KAYNAK_ETIKETLERI, type ItirazSatiri, type KaynakTuru } from './itirazlar-yardimcilari';

export const metadata: Metadata = {
  title: 'İtirazlar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; status?: string; kaynak?: string; page?: string }> };
const PAGE_SIZE = 10;

const STATUS_OPTIONS = [
  { value: '', label: 'Durum: Tümü' },
  { value: 'pending', label: 'Beklemede' },
  { value: 'reviewing', label: 'İnceleniyor' },
  { value: 'approved', label: 'Onaylandı' },
  { value: 'rejected', label: 'Reddedildi' },
];

export default async function AdminAppealsPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:itirazlar');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="İtirazlar" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="İtirazlar" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { q = '', status = '', kaynak = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const buAyBasi = new Date(new Date().setDate(1)).toISOString();
  const gecenAyBasi = new Date(new Date(new Date().setDate(1)).setMonth(new Date().getMonth() - 1)).toISOString();
  const otuzGunOnce = new Date(Date.now() - 30 * 86400000).toISOString();

  const [
    { data: allRaw },
    toplamRes,
    beklemedeRes,
    onaylandiRes,
    reddedildiRes,
    buAyRes,
    gecenAyRes,
    trendRes,
  ] = await Promise.all([
    sb.from('moderation_appeals').select('id, source_type, source_id, reason, details, status, created_at, decided_at, appellant_user_id, assigned_to').order('created_at', { ascending: false }).limit(500),
    sb.from('moderation_appeals').select('id', { count: 'exact', head: true }),
    sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).eq('status', 'pending').is('assigned_to', null),
    sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
    sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).gte('created_at', buAyBasi),
    sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).gte('created_at', gecenAyBasi).lt('created_at', buAyBasi),
    sb.from('moderation_appeals').select('created_at').gte('created_at', otuzGunOnce).limit(3000),
  ]);

  const allRows = (allRaw ?? []) as Array<{
    id: string; source_type: string; source_id: string; reason: string; details: string | null;
    status: string; created_at: string; decided_at: string | null; appellant_user_id: string; assigned_to: string | null;
  }>;

  const incelenenSayisi = allRows.filter((r) => r.status === 'pending' && r.assigned_to).length;

  const userIds = Array.from(new Set([
    ...allRows.map((r) => r.appellant_user_id),
    ...allRows.filter((r) => r.assigned_to).map((r) => r.assigned_to as string),
  ]));
  const { data: profileRows } = userIds.length > 0
    ? await sb.from('user_profiles').select('user_id, display_name').in('user_id', userIds)
    : { data: [] };
  const nameByUser = new Map<string, string>((profileRows ?? []).map((p: any) => [p.user_id as string, p.display_name]));

  // reporter e-postası için auth listesi gerekiyor ama kapsamı büyütmemek için sadece display_name gösteriyoruz.

  const businessIds = Array.from(new Set(allRows.filter((r) => r.source_type === 'business').map((r) => r.source_id)));
  const reviewIds = Array.from(new Set(allRows.filter((r) => r.source_type === 'review').map((r) => r.source_id)));
  const [{ data: businessRows }, { data: reviewRows }] = await Promise.all([
    businessIds.length > 0 ? sb.from('businesses').select('id, name').in('id', businessIds) : Promise.resolve({ data: [] }),
    reviewIds.length > 0 ? sb.from('reviews').select('id, business_id, content').in('id', reviewIds) : Promise.resolve({ data: [] }),
  ]);
  const businessNameById = new Map<string, string>((businessRows ?? []).map((b: any) => [b.id as string, b.name as string]));
  const reviewById = new Map<string, { businessId: string; content: string }>((reviewRows ?? []).map((r: any) => [r.id as string, { businessId: r.business_id, content: r.content }]));

  function contentLabel(sourceType: string, sourceId: string): string | null {
    if (sourceType === 'business') return businessNameById.get(sourceId) ?? null;
    if (sourceType === 'review') {
      const rv = reviewById.get(sourceId);
      if (!rv) return null;
      return businessNameById.get(rv.businessId) ?? rv.content.slice(0, 40);
    }
    if (sourceType === 'user') return nameByUser.get(sourceId) ?? null;
    return null;
  }

  let mapped: ItirazSatiri[] = allRows.map((r) => ({
    id: r.id, sourceType: r.source_type, sourceId: r.source_id, reason: r.reason, details: r.details,
    status: r.status, createdAt: r.created_at, decidedAt: r.decided_at,
    appellantName: nameByUser.get(r.appellant_user_id) ?? null, appellantEmail: null,
    contentLabel: contentLabel(r.source_type, r.source_id),
    assignedToName: r.assigned_to ? nameByUser.get(r.assigned_to) ?? 'Bir yönetici' : null,
  }));

  if (status) mapped = mapped.filter((r) => itirazDurumu(r) === status);
  if (kaynak) mapped = mapped.filter((r) => r.sourceType === kaynak);
  if (q.trim()) {
    const needle = q.trim().toLocaleLowerCase('tr-TR');
    mapped = mapped.filter((r) => [r.reason, r.details, r.contentLabel, r.appellantName].filter(Boolean).join(' ').toLocaleLowerCase('tr-TR').includes(needle));
  }

  const totalPages = Math.max(1, Math.ceil(mapped.length / PAGE_SIZE));
  const pageRows = mapped.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  const toplam = toplamRes.count ?? 0;
  const beklemede = beklemedeRes.count ?? 0;
  const onaylandi = onaylandiRes.count ?? 0;
  const reddedildi = reddedildiRes.count ?? 0;

  const donutHam: Array<[string, number, string]> = [
    ['Beklemede', beklemede, '#d97706'],
    ['İnceleniyor', incelenenSayisi, '#2563eb'],
    ['Onaylandı', onaylandi, '#059669'],
    ['Reddedildi', reddedildi, '#dc2626'],
  ];
  const donutVerisi = donutHam.filter(([, n]) => n > 0);
  const donutToplam = donutVerisi.reduce((s, [, n]) => s + n, 0);

  const kaynakSayilari = new Map<string, number>();
  for (const r of allRows) kaynakSayilari.set(r.source_type, (kaynakSayilari.get(r.source_type) ?? 0) + 1);

  const trendData = (trendRes.data ?? []) as Array<{ created_at: string }>;
  const gunlukSayim: Record<string, number> = {};
  for (const t of trendData) {
    const d = new Date(t.created_at);
    const gun = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    gunlukSayim[gun] = (gunlukSayim[gun] ?? 0) + 1;
  }
  const trendVerisi: { label: string; value: number }[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    const label = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    trendVerisi.push({ label, value: gunlukSayim[label] ?? 0 });
  }

  const queryBase = buildQueryString({ q, status, kaynak });

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="İtirazlar"
        description="Platform kararlarına veya içeriklere yapılan itirazları inceleyin ve yönetin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <MetricCard title="Tümü" value={toplam.toLocaleString('tr-TR')} subtitle="tüm itirazlar" tone="blue" icon={<UsersIcon />} />
            <MetricCard title="Beklemede" value={beklemede.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((beklemede / toplam) * 100)}` : undefined} tone="orange" icon={<ShieldIcon />} />
            <MetricCard title="İnceleniyor" value={incelenenSayisi.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((incelenenSayisi / toplam) * 100)}` : undefined} tone="purple" icon={<EyeIcon />} />
            <MetricCard title="Onaylandı" value={onaylandi.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((onaylandi / toplam) * 100)}` : undefined} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Reddedildi" value={reddedildi.toLocaleString('tr-TR')} subtitle={toplam > 0 ? `%${Math.round((reddedildi / toplam) * 100)}` : undefined} tone="pink" icon={<XIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-2 lg:grid-cols-4">
                <input name="page" value="1" type="hidden" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="İtiraz içeriğinde ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 lg:col-span-2"
                />
                <select name="status" defaultValue={status} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <select name="kaynak" defaultValue={kaynak} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">İlgili Tür: Tümü</option>
                  {Object.entries(KAYNAK_ETIKETLERI).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                </select>
                <div className="flex gap-2 lg:col-span-4">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/itirazlar" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              {pageRows.length === 0 ? (
                <PanelEmptyState icon={<FlagIcon />} title="İtiraz bulunamadı" description={q || status || kaynak ? 'Bu filtrelerle eşleşen itiraz yok.' : 'Henüz itiraz yok.'} />
              ) : (
                <PanelBolumKarti noPadding>
                  <ItirazlarTablosu rows={pageRows} />
                  <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
                    <p className="text-xs font-bold text-muted">Toplam {mapped.length.toLocaleString('tr-TR')} itiraz</p>
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
              <PanelBolumKarti title="İtiraz Özeti">
                {donutToplam === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <DurumDonut veriler={donutVerisi} toplam={donutToplam} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="İlgili Türlere Göre">
                {allRows.length === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-2">
                    {(Object.keys(KAYNAK_ETIKETLERI) as Array<KaynakTuru>).map((k) => {
                      const adet = kaynakSayilari.get(k) ?? 0;
                      if (adet === 0) return null;
                      return (
                        <div key={k} className="flex items-center justify-between text-xs">
                          <span className="font-bold text-textStrong">{KAYNAK_ETIKETLERI[k]}</span>
                          <span className="font-extrabold text-muted">{adet}</span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Son 30 Gün Trend">
                <TrendGrafik veriler={trendVerisi} />
                <p className="mt-2 text-xs font-bold text-muted">
                  Toplam {trendData.length.toLocaleString('tr-TR')} · {yuzdeDegisim(buAyRes.count ?? 0, gecenAyRes.count ?? 0) >= 0 ? '↑' : '↓'} %{Math.abs(yuzdeDegisim(buAyRes.count ?? 0, gecenAyRes.count ?? 0))} önceki 30 güne göre
                </p>
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <Link href="/yonetici/kuyruklar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Kuyruklar <ArrowIcon />
                  </Link>
                  <Link href="/yonetici/olaylar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                    Olaylar <ArrowIcon />
                  </Link>
                  <DisaAktarButonu rows={mapped} />
                </div>
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
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
function EyeIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function XIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></svg>; }
function FlagIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" y1="22" x2="4" y2="15" /></svg>; }
function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
