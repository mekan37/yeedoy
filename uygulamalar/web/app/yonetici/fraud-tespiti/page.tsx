import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { DURUM_ETIKETLERI, HEDEF_ETIKETLERI, type HedefTuru } from '../raporlar/raporlar-yardimcilari';
import { trend, type FraudRaporu, type SuphelKullanici } from './fraud-yardimcilari';
import { FraudTablosu } from './fraud-tablosu';

export const metadata: Metadata = {
  title: 'Fraud Tespiti | Yönetici Paneli',
  robots: { index: false, follow: false },
};

const PAGE_SIZE = 10;
const FETCH_LIMIT = 5000;
const DAY = 86_400_000;

type Props = {
  searchParams: Promise<{ durum?: string; hedef?: string; tarih?: string; q?: string; page?: string }>;
};

export default async function FraudTespitiPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:fraud-tespiti');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Fraud Tespiti" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Fraud Tespiti" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { durum = '', hedef = '', tarih = '', q = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const now = Date.now();
  const yediGunOnce = new Date(now - 7 * DAY).toISOString();

  async function detectSpamReviews() {
    try {
      return await sb.rpc('detect_spam_reviews_v1', { p_days: 7, p_min_count: 5 });
    } catch {
      return { data: [] };
    }
  }

  const [{ data: allReports }, spamRes, yeniKayitRes] = await Promise.all([
    sb.from('reports')
      .select('id, target_type, target_id, reason, details, status, created_at, admin_note')
      .order('created_at', { ascending: false })
      .limit(FETCH_LIMIT) as Promise<{ data: FraudRaporu[] | null }>,
    detectSpamReviews(),
    sb.from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', yediGunOnce),
  ]);

  const reports: FraudRaporu[] = allReports ?? [];
  const suphelKullanicilar: SuphelKullanici[] = (spamRes.data ?? []) as SuphelKullanici[];

  // ── Tarih filtresi ──
  const tarihSinir = tarih === '7g' ? now - 7 * DAY : tarih === '30g' ? now - 30 * DAY : tarih === '90g' ? now - 90 * DAY : null;

  const qNorm = q.trim().toLocaleLowerCase('tr-TR');
  const filtered = reports.filter((r) => {
    if (durum && r.status !== durum) return false;
    if (hedef && r.target_type !== hedef) return false;
    if (tarihSinir && new Date(r.created_at).getTime() < tarihSinir) return false;
    if (qNorm) {
      const hay = `${r.id} ${r.reason ?? ''} ${r.details ?? ''}`.toLocaleLowerCase('tr-TR');
      if (!hay.includes(qNorm)) return false;
    }
    return true;
  });
  const totalFiltered = filtered.length;
  const totalPages = Math.max(1, Math.ceil(totalFiltered / PAGE_SIZE));
  const pageRows = filtered.slice((pageNum - 1) * PAGE_SIZE, pageNum * PAGE_SIZE);

  // ── Üst istatistikler (tüm kayıtlar, filtresiz) ──
  const total = reports.length;
  const openCount = reports.filter((r) => r.status === 'open').length;
  const reviewingCount = reports.filter((r) => r.status === 'reviewing').length;
  const closedCount = reports.filter((r) => r.status === 'closed').length;
  const resolutionRate = total ? Math.round((closedCount / total) * 100) : 0;

  const thisWeekCount = reports.filter((r) => new Date(r.created_at).getTime() >= now - 7 * DAY).length;
  const lastWeekCount = reports.filter((r) => {
    const ts = new Date(r.created_at).getTime();
    return ts >= now - 14 * DAY && ts < now - 7 * DAY;
  }).length;

  // ── Duruma göre dağılım (donut) ──
  const durumDagilimi: Array<[string, number, string]> = [
    ['Beklemede', openCount, '#f59e0b'],
    ['İnceleniyor', reviewingCount, '#2563eb'],
    ['Kapatıldı', closedCount, '#94a3b8'],
  ].filter(([, n]) => (n as number) > 0) as Array<[string, number, string]>;

  // ── Türe göre dağılım (bar) ──
  const turDagilimi = (['review', 'business', 'menu_item_photo'] as HedefTuru[])
    .map((t) => ({ key: t, label: HEDEF_ETIKETLERI[t], count: reports.filter((r) => r.target_type === t).length }))
    .filter((r) => r.count > 0);
  const turMax = Math.max(...turDagilimi.map((r) => r.count), 1);

  // ── 14 günlük olay trendi ──
  const trendVerisi: Array<{ label: string; count: number }> = [];
  for (let i = 13; i >= 0; i--) {
    const gunBaslangic = new Date(now - i * DAY); gunBaslangic.setHours(0, 0, 0, 0);
    const gunBitis = gunBaslangic.getTime() + DAY;
    const count = reports.filter((r) => {
      const ts = new Date(r.created_at).getTime();
      return ts >= gunBaslangic.getTime() && ts < gunBitis;
    }).length;
    trendVerisi.push({ label: `${gunBaslangic.getDate()}/${gunBaslangic.getMonth() + 1}`, count });
  }

  const queryStr = (overrides: Record<string, string>) => {
    const params = new URLSearchParams({ durum, hedef, tarih, q, ...overrides });
    for (const [k, v] of [...params.entries()]) if (!v) params.delete(k);
    return params.toString();
  };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Yönetim" title="Fraud Tespiti" description="Şüpheli aktiviteleri tespit edin, inceleyin ve önleyin." />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam Rapor" value={total.toLocaleString('tr-TR')} tone="blue" icon={<ShieldIcon />} />
            <MetricCard title="Beklemede" value={openCount.toLocaleString('tr-TR')} tone="orange" icon={<AlertIcon />} />
            <MetricCard title="İnceleniyor" value={reviewingCount.toLocaleString('tr-TR')} tone="purple" icon={<SearchIcon />} />
            <MetricCard title="Şüpheli Kullanıcı" value={suphelKullanicilar.length.toLocaleString('tr-TR')} subtitle="7 günde 5+ yorum" tone="pink" icon={<UserAlertIcon />} />
            <MetricCard title="Yeni Kayıt (7g)" value={(yeniKayitRes.count ?? 0).toLocaleString('tr-TR')} tone="green" icon={<UserPlusIcon />} />
            <MetricCard title="Çözüm Oranı" value={`%${resolutionRate}`} trend={trend(thisWeekCount, lastWeekCount)} tone="primary" icon={<TrendIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              {suphelKullanicilar.length > 0 && (
                <div id="suphelKullanicilar" className="scroll-mt-6">
                  <PanelBolumKarti title="Şüpheli Kullanıcılar" description="7 günde 5+ yorum" noPadding>
                    <div className="flex flex-wrap gap-2 p-4">
                      {suphelKullanicilar.slice(0, 8).map((u) => (
                        <Link
                          key={u.user_id}
                          href={`/yonetici/kullanicilar?id=${u.user_id}`}
                          className="flex items-center gap-2 rounded-full border border-red-200 bg-red-50 py-1 pl-1 pr-3 text-xs font-bold text-red-700 hover:bg-red-100"
                        >
                          <span className="flex h-6 w-6 items-center justify-center rounded-full bg-red-100 text-[10px] font-extrabold">
                            {u.display_name?.[0]?.toUpperCase() ?? '?'}
                          </span>
                          {u.display_name ?? 'Anonim'} · {u.review_count} yorum
                        </Link>
                      ))}
                    </div>
                  </PanelBolumKarti>
                </div>
              )}

              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-5">
                <input type="hidden" name="page" value="1" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Kullanıcı, ID veya neden ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="durum" defaultValue={durum} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Durumlar</option>
                  {Object.entries(DURUM_ETIKETLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
                <select name="hedef" defaultValue={hedef} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Türler</option>
                  {Object.entries(HEDEF_ETIKETLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
                <select name="tarih" defaultValue={tarih} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Zamanlar</option>
                  <option value="7g">Son 7 Gün</option>
                  <option value="30g">Son 30 Gün</option>
                  <option value="90g">Son 90 Gün</option>
                </select>
                <div className="flex gap-2 md:col-span-5">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/fraud-tespiti" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                  <a
                    href={`/sunucu/yonetici/raporlar-csv?${new URLSearchParams({ status: durum || 'all', hedef }).toString()}`}
                    className="ml-auto flex min-h-11 items-center gap-2 rounded-xl border border-border px-4 text-xs font-extrabold text-textStrong hover:border-primary/30 hover:text-primary"
                  >
                    <DownloadIcon /> Dışa Aktar
                  </a>
                </div>
              </form>

              {pageRows.length === 0 ? (
                <PanelEmptyState
                  icon={<ShieldIcon />}
                  title={total === 0 ? 'Henüz rapor yok' : 'Sonuç bulunamadı'}
                  description={total === 0 ? 'Kullanıcılar işletme/yorum/fotoğraf raporladığında burada görünecek.' : 'Seçili filtrelere uygun rapor yok.'}
                />
              ) : (
                <FraudTablosu reports={pageRows} />
              )}

              {totalPages > 1 && (
                <div className="flex items-center justify-between rounded-xl border border-border bg-card px-4 py-3">
                  <span className="text-xs text-muted">Toplam {totalFiltered.toLocaleString('tr-TR')} rapor</span>
                  <div className="flex items-center gap-1">
                    {pageNum > 1 && <a href={`?${queryStr({ page: String(pageNum - 1) })}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</a>}
                    <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                    {pageNum < totalPages && <a href={`?${queryStr({ page: String(pageNum + 1) })}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</a>}
                  </div>
                </div>
              )}

              <PanelBolumKarti title="Tespit Kuralları">
                <div className="grid gap-3 sm:grid-cols-2">
                  <KuralKart baslik="Hız Limiti Kuralı" aciklama="Kullanıcı 7 günde 5+ yorum → otomatik inceleme kuyruğuna girer" aktif />
                  <KuralKart baslik="IP Bazlı Tespit" aciklama="Aynı IP'den 24s içinde 10+ istek → geçici engel" aktif />
                  <KuralKart baslik="Yeni Hesap Koruma" aciklama="Kayıttan 24 saat içinde yorum → ekstra doğrulama" aktif={false} />
                  <KuralKart baslik="AI İçerik Analizi" aciklama="GPT-4o ile spam/toksik içerik otomatik tespiti" aktif={false} />
                </div>
              </PanelBolumKarti>
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Duruma Göre Dağılım">
                {durumDagilimi.length === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <DurumDonut veriler={durumDagilimi} toplam={total} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Türe Göre Dağılım">
                {turDagilimi.length === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-3">
                    {turDagilimi.map((r) => (
                      <div key={r.key} className="flex flex-col gap-1">
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-bold text-textStrong">{r.label}</span>
                          <span className="font-extrabold text-muted">{r.count.toLocaleString('tr-TR')} (%{Math.round((r.count / total) * 100)})</span>
                        </div>
                        <div className="h-2 overflow-hidden rounded-full bg-black/8">
                          <div className="h-full rounded-full bg-primary" style={{ width: `${(r.count / turMax) * 100}%` }} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Rapor Sayısı Trendi" description="Son 14 gün">
                <TrendCizgisi veriler={trendVerisi} />
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <a href="#suphelKullanicilar" className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors hover:border-primary/30 hover:bg-black/2">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-(--yd-color-primary)"><UserAlertIcon /></div>
                    <div className="min-w-0">
                      <p className="text-xs font-extrabold text-textStrong">Şüpheli Kullanıcıları İncele</p>
                      <p className="truncate text-[10px] text-muted">Yüksek riskli kullanıcı hesaplarını görüntüleyin</p>
                    </div>
                  </a>
                  <HizliIslemButonu label="Toplu İşlem" description="Tablodan rapor seçince orada çıkan çubuktan uygulanır" icon={<CheckSquareIcon />} disabled title="Tablodaki onay kutularını işaretleyin — seçim çubuğu tablonun üstünde belirir" />
                  <HizliIslemButonu label="Kural Yönetimi" description="Fraud tespit kurallarını yönetin" icon={<SettingsIcon />} disabled title="Henüz uygulanmadı — Tespit Kuralları şu an salt bilgilendirme amaçlı" />
                  <HizliIslemButonu label="IP / Cihaz Analizi" description="Şüpheli IP ve cihazları analiz edin" icon={<DeviceIcon />} disabled title="Altyapı var (user_device_fingerprints) ama hiç veri yazılmıyor — ayrı bir iş" />
                  <HizliIslemButonu label="Engellenen Listesi" description="Engellenen kullanıcı ve IP listesi" icon={<BlockIcon />} disabled title="Henüz bir engelleme mekanizması yok — ayrı bir iş olarak planlanabilir" />
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

function KuralKart({ baslik, aciklama, aktif }: { baslik: string; aciklama: string; aktif: boolean }) {
  return (
    <div className={`rounded-xl border p-4 ${aktif ? 'border-success/30 bg-success/4' : 'border-border bg-card opacity-60'}`}>
      <div className="flex items-center gap-2">
        <span className={`h-2 w-2 rounded-full ${aktif ? 'bg-success' : 'bg-muted'}`} />
        <span className="font-extrabold text-sm text-textStrong">{baslik}</span>
      </div>
      <p className="mt-1 text-xs text-muted">{aciklama}</p>
    </div>
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

function TrendCizgisi({ veriler }: { veriler: Array<{ label: string; count: number }> }) {
  const W = 260, H = 100, PAD = 16;
  const maxVal = Math.max(...veriler.map((v) => v.count), 1);
  const stepX = (W - PAD * 2) / Math.max(1, veriler.length - 1);
  const points = veriler.map((v, i) => {
    const x = PAD + i * stepX;
    const y = H - PAD - (v.count / maxVal) * (H - PAD * 2);
    return [x, y] as const;
  });
  const path = points.map(([x, y], i) => `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`).join(' ');
  const toplam = veriler.reduce((s, v) => s + v.count, 0);

  if (toplam === 0) return <p className="text-xs text-muted">Bu dönemde rapor yok.</p>;

  return (
    <div className="flex flex-col gap-2">
      <svg viewBox={`0 0 ${W} ${H}`} width="100%" height={H} role="img" aria-label="Son 14 günde rapor sayısı trendi">
        <path d={path} fill="none" stroke="var(--yd-color-primary, #7f1d1d)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        {points.map(([x, y], i) => <circle key={i} cx={x} cy={y} r="2.5" fill="var(--yd-color-primary, #7f1d1d)" />)}
      </svg>
      <div className="flex justify-between text-[9px] font-bold text-muted">
        <span>{veriler[0]?.label}</span>
        <span>{veriler[veriler.length - 1]?.label}</span>
      </div>
    </div>
  );
}

function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
function AlertIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>; }
function SearchIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>; }
function UserAlertIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><line x1="19" y1="8" x2="19" y2="14" /><line x1="19" y1="17" x2="19.01" y2="17" /></svg>; }
function UserPlusIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><line x1="20" y1="8" x2="20" y2="14" /><line x1="23" y1="11" x2="17" y2="11" /></svg>; }
function TrendIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18" /><polyline points="17 6 23 6 23 12" /></svg>; }
function CheckSquareIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 11 12 14 22 4" /><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" /></svg>; }
function SettingsIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></svg>; }
function DeviceIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="5" y="2" width="14" height="20" rx="2" /><line x1="12" y1="18" x2="12.01" y2="18" /></svg>; }
function BlockIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><line x1="4.93" y1="4.93" x2="19.07" y2="19.07" /></svg>; }
function DownloadIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>; }
