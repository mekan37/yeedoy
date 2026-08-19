import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import {
  STATUS_MAP,
  PRIORITY_MAP,
  TABS,
  formatSure,
  trend,
  type DestekTalebi,
} from './musteri-destek-yardimcilari';
import { MusteriDestekTablosu } from './musteri-destek-tablosu';
import { DisaAktarButonu } from './disa-aktar-butonu';

export const metadata: Metadata = {
  title: 'Müşteri Destek | Admin Panel',
  robots: { index: false, follow: false },
};

const PAGE_SIZE = 10;
const FETCH_LIMIT = 5000;

type Props = {
  searchParams: Promise<{
    durum?: string;
    kategori?: string;
    oncelik?: string;
    tarih?: string;
    q?: string;
    page?: string;
  }>;
};

export default async function MusteriDestekPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:musteri-destek');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Müşteri Destek" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Müşteri Destek" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { durum = 'all', kategori = '', oncelik = '', tarih = '', q = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const { data: allTickets } = await sb
    .from('support_tickets')
    .select('id, subject, status, priority, category, created_at, updated_at, requester_name, requester_email')
    .order('created_at', { ascending: false })
    .limit(FETCH_LIMIT) as { data: Array<Omit<DestekTalebi, 'first_response_at'>> | null };

  const { data: agentMessages } = await sb
    .from('support_ticket_messages')
    .select('ticket_id, created_at')
    .eq('sender', 'agent')
    .order('created_at', { ascending: true })
    .limit(FETCH_LIMIT) as { data: Array<{ ticket_id: string; created_at: string }> | null };

  const firstResponseByTicket = new Map<string, string>();
  for (const m of agentMessages ?? []) {
    if (!firstResponseByTicket.has(m.ticket_id)) firstResponseByTicket.set(m.ticket_id, m.created_at);
  }

  const tickets: DestekTalebi[] = (allTickets ?? []).map((t) => ({
    ...t,
    first_response_at: firstResponseByTicket.get(t.id) ?? null,
  }));

  // ── Tarih filtresi sınırları ──
  const now = Date.now();
  const DAY = 86_400_000;
  const tarihSinir = tarih === '7g' ? now - 7 * DAY : tarih === '30g' ? now - 30 * DAY : tarih === '90g' ? now - 90 * DAY : null;

  // ── Filtreleme ──
  const qNorm = q.trim().toLocaleLowerCase('tr-TR');
  let filtered = tickets.filter((t) => {
    if (durum !== 'all' && t.status !== durum) return false;
    if (kategori && t.category !== kategori) return false;
    if (oncelik && t.priority !== oncelik) return false;
    if (tarihSinir && new Date(t.created_at).getTime() < tarihSinir) return false;
    if (qNorm) {
      const hay = `${t.id} ${t.subject} ${t.requester_name ?? ''} ${t.requester_email ?? ''}`.toLocaleLowerCase('tr-TR');
      if (!hay.includes(qNorm)) return false;
    }
    return true;
  });

  const totalFiltered = filtered.length;
  const totalPages = Math.max(1, Math.ceil(totalFiltered / PAGE_SIZE));
  const pageRows = filtered.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  // ── Sekme sayaçları (filtreler hariç, yalnız arama/kategori/öncelik/tarih uygulanmış hal üzerinden) ──
  const tabBase = tickets.filter((t) => {
    if (kategori && t.category !== kategori) return false;
    if (oncelik && t.priority !== oncelik) return false;
    if (tarihSinir && new Date(t.created_at).getTime() < tarihSinir) return false;
    if (qNorm) {
      const hay = `${t.id} ${t.subject} ${t.requester_name ?? ''} ${t.requester_email ?? ''}`.toLocaleLowerCase('tr-TR');
      if (!hay.includes(qNorm)) return false;
    }
    return true;
  });
  const tabCounts: Record<string, number> = { all: tabBase.length };
  for (const tab of TABS) if (tab.value !== 'all') tabCounts[tab.value] = tabBase.filter((t) => t.status === tab.value).length;

  // ── Üst istatistikler (tüm kayıtlar üzerinden, filtresiz — sayfa geneli durum) ──
  const total = tickets.length;
  const openCount = tickets.filter((t) => t.status === 'open').length;
  const pendingCount = tickets.filter((t) => t.status === 'in_progress').length;
  const resolvedOrClosed = tickets.filter((t) => t.status === 'resolved' || t.status === 'closed').length;
  const resolutionRate = total ? Math.round((resolvedOrClosed / total) * 100) : 0;

  const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
  const answeredToday = new Set(
    (agentMessages ?? []).filter((m) => new Date(m.created_at).getTime() >= todayStart.getTime()).map((m) => m.ticket_id),
  ).size;

  const responseHours = tickets
    .filter((t) => t.first_response_at)
    .map((t) => (new Date(t.first_response_at!).getTime() - new Date(t.created_at).getTime()) / 3_600_000)
    .filter((h) => h >= 0);
  const avgResponseHours = responseHours.length ? responseHours.reduce((s, h) => s + h, 0) / responseHours.length : null;

  // ── 7 günlük trendler (bu hafta vs önceki hafta oluşturulan talep sayısı) ──
  const weekAgo = now - 7 * DAY;
  const twoWeeksAgo = now - 14 * DAY;
  const thisWeekCount = tickets.filter((t) => new Date(t.created_at).getTime() >= weekAgo).length;
  const lastWeekCount = tickets.filter((t) => {
    const ts = new Date(t.created_at).getTime();
    return ts >= twoWeeksAgo && ts < weekAgo;
  }).length;

  // ── Kategori dağılımı (donut) ──
  const categoryEntries = Object.entries(
    tickets.reduce<Record<string, number>>((acc, t) => { acc[t.category] = (acc[t.category] ?? 0) + 1; return acc; }, {}),
  ).sort((a, b) => b[1] - a[1]);
  const DONUT_COLORS = ['#2563eb', '#7c3aed', '#f59e0b', '#059669', '#dc2626', '#94a3b8'];
  const donutVerileri: Array<[string, number, string]> = categoryEntries
    .slice(0, 5)
    .map(([label, n], i) => [label, n, DONUT_COLORS[i] ?? '#94a3b8']);
  const digerToplam = categoryEntries.slice(5).reduce((s, [, n]) => s + n, 0);
  if (digerToplam > 0) donutVerileri.push(['Diğer', digerToplam, DONUT_COLORS[5]]);

  // ── Öncelik dağılımı (bar) ──
  const oncelikSirasi = ['urgent', 'high', 'medium', 'low'];
  const oncelikDagilimi = oncelikSirasi
    .map((p) => ({ key: p, label: PRIORITY_MAP[p]?.label ?? p, count: tickets.filter((t) => t.priority === p).length }))
    .filter((r) => r.count > 0);
  const oncelikMax = Math.max(...oncelikDagilimi.map((r) => r.count), 1);

  const kategoriler = Array.from(new Set(tickets.map((t) => t.category))).sort((a, b) => a.localeCompare(b, 'tr'));

  const queryStr = (overrides: Record<string, string>) => {
    const params = new URLSearchParams({ durum, kategori, oncelik, tarih, q, ...overrides });
    for (const [k, v] of [...params.entries()]) if (!v) params.delete(k);
    return params.toString();
  };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Yönetim" title="Müşteri Destek" description="Tüm destek taleplerini yönetin ve yanıtlayın." />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Stat kartları */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam Talepler" value={total.toLocaleString('tr-TR')} tone="blue" icon={<HeadsetIcon />} />
            <MetricCard title="Açık Talepler" value={openCount.toLocaleString('tr-TR')} tone="orange" icon={<InboxIcon />} />
            <MetricCard title="Bekleyen Talepler" value={pendingCount.toLocaleString('tr-TR')} tone="pink" icon={<ClockIcon />} />
            <MetricCard title="Bugün Yanıtlanan" value={answeredToday.toLocaleString('tr-TR')} tone="green" icon={<CheckIcon />} />
            <MetricCard
              title="Ortalama Yanıt Süresi"
              value={avgResponseHours !== null ? formatSure(avgResponseHours) : '—'}
              subtitle={avgResponseHours === null ? 'Henüz yanıtlanan talep yok' : undefined}
              tone="purple"
              icon={<TimerIcon />}
            />
            <MetricCard
              title="Çözüm Oranı"
              value={`%${resolutionRate}`}
              trend={trend(thisWeekCount, lastWeekCount)}
              tone="primary"
              icon={<TrendIcon />}
            />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              {/* Arama + filtreler */}
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-5">
                <input type="hidden" name="durum" value={durum} />
                <input type="hidden" name="page" value="1" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Talep no, konu veya kullanıcı ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="kategori" defaultValue={kategori} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Kategoriler</option>
                  {kategoriler.map((k) => <option key={k} value={k}>{k}</option>)}
                </select>
                <select name="oncelik" defaultValue={oncelik} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Öncelikler</option>
                  {Object.entries(PRIORITY_MAP).map(([v, m]) => <option key={v} value={v}>{m.label}</option>)}
                </select>
                <select name="tarih" defaultValue={tarih} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Zamanlar</option>
                  <option value="7g">Son 7 Gün</option>
                  <option value="30g">Son 30 Gün</option>
                  <option value="90g">Son 90 Gün</option>
                </select>
                <div className="flex gap-2 md:col-span-5">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/musteri-destek" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                  <div className="ml-auto">
                    <DisaAktarButonu rows={filtered} />
                  </div>
                </div>
              </form>

              {/* Sekmeler */}
              <div className="flex flex-wrap gap-2 rounded-xl border border-border bg-card p-2">
                {TABS.map((t) => (
                  <a
                    key={t.value}
                    href={`?${queryStr({ durum: t.value, page: '1' })}`}
                    className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${durum === t.value ? 'bg-primary text-white' : 'text-muted hover:text-textStrong'}`}
                  >
                    {t.label} ({(tabCounts[t.value] ?? 0).toLocaleString('tr-TR')})
                  </a>
                ))}
              </div>

              {pageRows.length === 0 ? (
                <PanelEmptyState
                  icon={<HeadsetIcon />}
                  title={total === 0 ? 'Henüz destek talebi yok' : 'Sonuç bulunamadı'}
                  description={total === 0 ? 'Kullanıcılardan destek talebi geldiğinde burada görünecek.' : 'Seçili filtrelere uygun talep yok.'}
                />
              ) : (
                <MusteriDestekTablosu tickets={pageRows} />
              )}

              {totalPages > 1 && (
                <div className="flex items-center justify-between rounded-xl border border-border bg-card px-4 py-3">
                  <span className="text-xs text-muted">Toplam {totalFiltered.toLocaleString('tr-TR')} talep</span>
                  <div className="flex items-center gap-1">
                    {pageNum > 1 && <a href={`?${queryStr({ page: String(pageNum - 1) })}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</a>}
                    <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                    {pageNum < totalPages && <a href={`?${queryStr({ page: String(pageNum + 1) })}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</a>}
                  </div>
                </div>
              )}
            </div>

            {/* Sağ sidebar */}
            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Talep Dağılımı">
                {donutVerileri.length === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <KategoriDonut veriler={donutVerileri} toplam={total} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Öncelik Dağılımı">
                {oncelikDagilimi.length === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-3">
                    {oncelikDagilimi.map((r) => (
                      <div key={r.key} className="flex flex-col gap-1">
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-bold text-textStrong">{r.label}</span>
                          <span className="font-extrabold text-muted">{r.count.toLocaleString('tr-TR')} (%{Math.round((r.count / total) * 100)})</span>
                        </div>
                        <div className="h-2 overflow-hidden rounded-full bg-black/8">
                          <div
                            className={`h-full rounded-full ${r.key === 'urgent' || r.key === 'high' ? 'bg-red-500' : r.key === 'medium' ? 'bg-amber-400' : 'bg-emerald-500'}`}
                            style={{ width: `${(r.count / oncelikMax) * 100}%` }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Ortalama Yanıt Süresi">
                <p className="text-2xl font-black text-textStrong">{avgResponseHours !== null ? formatSure(avgResponseHours) : '—'}</p>
                <p className="mt-1 text-xs text-muted">{responseHours.length} yanıtlanmış talep üzerinden</p>
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <HizliIslemButonu label="Toplu Yanıt Gönder" description="Tablodan talep seçince orada çıkan çubuktan gönderilir" icon={<SendIcon />} disabled title="Tablodaki onay kutularını işaretleyin — seçim çubuğu tablonun üstünde belirir" />
                  <HizliIslemButonu label="Yeni Talep Oluştur" description="Kullanıcı adına talep oluşturun" icon={<PlusIcon />} disabled title="Henüz uygulanmadı — ayrı bir iş olarak planlanabilir" />
                  <HizliIslemButonu label="Talep İçe Aktar" description="Harici sistemden talepleri içe aktarın" icon={<UploadIcon />} disabled title="Henüz uygulanmadı — ayrı bir iş olarak planlanabilir" />
                </div>
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

// ─── Bileşenler ───────────────────────────────────────────────────────────────

function HizliIslemButonu({ label, description, icon, disabled, title }: { label: string; description: string; icon: React.ReactNode; disabled?: boolean; title?: string }) {
  return (
    <button
      type="button"
      disabled={disabled}
      title={title}
      className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors enabled:hover:border-primary/30 enabled:hover:bg-black/2 disabled:cursor-not-allowed disabled:opacity-50"
    >
      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-(--yd-color-primary)">{icon}</div>
      <div className="min-w-0">
        <p className="text-xs font-extrabold text-textStrong">{label}</p>
        <p className="truncate text-[10px] text-muted">{description}</p>
      </div>
    </button>
  );
}

function KategoriDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
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

function HeadsetIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 18v-6a9 9 0 0 1 18 0v6" /><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" /></svg>; }
function InboxIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12" /><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><polyline points="12 7 12 12 15 15" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function TimerIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="10" y1="2" x2="14" y2="2" /><line x1="12" y1="14" x2="15" y2="11" /><circle cx="12" cy="14" r="8" /></svg>; }
function TrendIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18" /><polyline points="17 6 23 6 23 12" /></svg>; }
function SendIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" /></svg>; }
function PlusIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>; }
function UploadIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="17 8 12 3 7 8" /><line x1="12" y1="3" x2="12" y2="15" /></svg>; }
