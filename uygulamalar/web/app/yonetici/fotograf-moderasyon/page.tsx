import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { trend, type ModerasyonFotografi } from './fotograf-moderasyon-yardimcilari';
import { FotografModerasyon } from './fotograf-moderasyon-istemci';

export const metadata: Metadata = {
  title: 'Fotoğraf Moderasyon | Admin Panel',
  robots: { index: false, follow: false },
};

const PAGE_SIZE = 24;
const DAY = 86_400_000;
const KATEGORILER = ['Restoran', 'Kafe', 'Kahvaltı', 'Balık / Et', 'Tatlıcı', 'Mekan'];

type Props = {
  searchParams: Promise<{ durum?: string; tur?: string; kategori?: string; q?: string; page?: string }>;
};

export default async function FotografModerasyonPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:fotograf-moderasyon');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Fotoğraf Moderasyon" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Fotoğraf Moderasyon" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { durum = 'pending', tur = '', kategori = '', q = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const now = Date.now();
  const yediGunOnce = new Date(now - 7 * DAY).toISOString();
  const ondortGunOnce = new Date(now - 14 * DAY).toISOString();

  const [totalRes, pendingRes, approvedRes, rejectedRes, hiddenRes, thisWeekRes, lastWeekRes] = await Promise.all([
    sb.from('business_media').select('id', { count: 'exact', head: true }),
    sb.from('business_media').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    sb.from('business_media').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    sb.from('business_media').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
    sb.from('business_media').select('id', { count: 'exact', head: true }).eq('is_hidden', true),
    sb.from('business_media').select('id', { count: 'exact', head: true }).gte('created_at', yediGunOnce),
    sb.from('business_media').select('id', { count: 'exact', head: true }).gte('created_at', ondortGunOnce).lt('created_at', yediGunOnce),
  ]);

  const total = totalRes.count ?? 0;
  const pendingCount = pendingRes.count ?? 0;
  const approvedCount = approvedRes.count ?? 0;
  const rejectedCount = rejectedRes.count ?? 0;
  const hiddenCount = hiddenRes.count ?? 0;

  // ── İçerik türüne göre dağılım (kind gerçek değerleri: logo/cover/hero/gallery) ──
  const [logoRes, coverRes, galleryRes] = await Promise.all([
    sb.from('business_media').select('id', { count: 'exact', head: true }).eq('kind', 'logo'),
    sb.from('business_media').select('id', { count: 'exact', head: true }).in('kind', ['cover', 'hero']),
    sb.from('business_media').select('id', { count: 'exact', head: true }).eq('kind', 'gallery'),
  ]);
  const bilinenTurToplam = (logoRes.count ?? 0) + (coverRes.count ?? 0) + (galleryRes.count ?? 0);
  const digerTurSayisi = Math.max(0, total - bilinenTurToplam);
  const turDagilimi: Array<[string, number, string]> = [
    ['Galeri', galleryRes.count ?? 0, '#2563eb'],
    ['Logo', logoRes.count ?? 0, '#7c3aed'],
    ['Kapak', coverRes.count ?? 0, '#059669'],
    ['Diğer', digerTurSayisi, '#94a3b8'],
  ].filter(([, n]) => n > 0) as Array<[string, number, string]>;

  // ── Ana liste sorgusu (server-side filtre + sayfalama) ──
  let query = sb
    .from('business_media')
    .select('id, business_id, created_by, url, url_thumb, kind, status, is_hidden, created_at, businesses!inner(name, category)', { count: 'exact' })
    .order('created_at', { ascending: false });

  if (durum === 'pending') query = query.eq('status', 'pending');
  else if (durum === 'approved') query = query.eq('status', 'approved');
  else if (durum === 'rejected') query = query.eq('status', 'rejected');
  else if (durum === 'hidden') query = query.eq('is_hidden', true);
  // durum === 'all' → filtre yok

  if (tur === 'logo') query = query.eq('kind', 'logo');
  else if (tur === 'cover') query = query.in('kind', ['cover', 'hero']);
  else if (tur === 'gallery') query = query.eq('kind', 'gallery');

  if (kategori) query = query.eq('businesses.category', kategori);
  if (q.trim()) query = query.ilike('businesses.name', `%${q.trim()}%`);

  const from = (pageNum - 1) * PAGE_SIZE;
  const { data: rows, count: filteredCount } = await query.range(from, from + PAGE_SIZE - 1);

  const photos: ModerasyonFotografi[] = ((rows ?? []) as any[]).map((r) => ({
    id: r.id,
    business_id: r.business_id,
    created_by: r.created_by,
    url: r.url,
    url_thumb: r.url_thumb,
    kind: r.kind,
    status: r.status,
    is_hidden: r.is_hidden,
    created_at: r.created_at,
    business_name: r.businesses?.name ?? null,
    business_category: r.businesses?.category ?? null,
  }));

  const totalFiltered = filteredCount ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalFiltered / PAGE_SIZE));

  const TABS = [
    { value: 'pending', label: 'Bekleyen', count: pendingCount },
    { value: 'all', label: 'Tümü', count: total },
    { value: 'approved', label: 'Onaylanan', count: approvedCount },
    { value: 'rejected', label: 'Reddedilen', count: rejectedCount },
    { value: 'hidden', label: 'Gizlenen', count: hiddenCount },
  ] as const;

  const queryStr = (overrides: Record<string, string>) => {
    const params = new URLSearchParams({ durum, tur, kategori, q, ...overrides });
    for (const [k, v] of [...params.entries()]) if (!v) params.delete(k);
    return params.toString();
  };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Yönetim" title="Fotoğraf Moderasyonu" description="Yüklenen fotoğrafları inceleyin, uygun olmayan içerikleri yönetin." />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam Fotoğraf" value={total.toLocaleString('tr-TR')} tone="blue" icon={<ImageIcon />} />
            <MetricCard title="Bekleyen İnceleme" value={pendingCount.toLocaleString('tr-TR')} tone="orange" icon={<ClockIcon />} />
            <MetricCard title="Onaylanan" value={approvedCount.toLocaleString('tr-TR')} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Reddedilen" value={rejectedCount.toLocaleString('tr-TR')} tone="pink" icon={<XIcon />} />
            <MetricCard title="Gizlenen" value={hiddenCount.toLocaleString('tr-TR')} tone="purple" icon={<HideIcon />} />
            <MetricCard title="Bu Hafta Yüklenen" value={(thisWeekRes.count ?? 0).toLocaleString('tr-TR')} trend={trend(thisWeekRes.count ?? 0, lastWeekRes.count ?? 0)} tone="primary" icon={<UploadIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-4">
                <input type="hidden" name="durum" value={durum} />
                <input type="hidden" name="page" value="1" />
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="İşletme adına göre ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="tur" defaultValue={tur} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm İçerik Türleri</option>
                  <option value="gallery">Galeri</option>
                  <option value="logo">Logo</option>
                  <option value="cover">Kapak</option>
                </select>
                <select name="kategori" defaultValue={kategori} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Kategoriler</option>
                  {KATEGORILER.map((k) => <option key={k} value={k}>{k}</option>)}
                </select>
                <div className="flex gap-2 md:col-span-4">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/fotograf-moderasyon" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                </div>
              </form>

              <div className="flex flex-wrap gap-2 rounded-xl border border-border bg-card p-2">
                {TABS.map((t) => (
                  <a
                    key={t.value}
                    href={`?${queryStr({ durum: t.value, page: '1' })}`}
                    className={`rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${durum === t.value ? 'bg-primary text-white' : 'text-muted hover:text-textStrong'}`}
                  >
                    {t.label} ({t.count.toLocaleString('tr-TR')})
                  </a>
                ))}
              </div>

              {photos.length === 0 ? (
                <PanelEmptyState
                  icon={<ImageIcon />}
                  title={total === 0 ? 'Henüz fotoğraf yok' : 'Bu filtrede fotoğraf yok'}
                  description={total === 0 ? 'İşletmeler/kullanıcılar fotoğraf yüklediğinde burada görünecek.' : 'Seçili filtrelere uygun fotoğraf yok.'}
                />
              ) : (
                <FotografModerasyon photos={photos} />
              )}

              {totalPages > 1 && (
                <div className="flex items-center justify-between rounded-xl border border-border bg-card px-4 py-3">
                  <span className="text-xs text-muted">Toplam {totalFiltered.toLocaleString('tr-TR')} kayıt</span>
                  <div className="flex items-center gap-1">
                    {pageNum > 1 && <a href={`?${queryStr({ page: String(pageNum - 1) })}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">←</a>}
                    <span className="px-2 text-xs font-bold text-muted">Sayfa {pageNum} / {totalPages}</span>
                    {pageNum < totalPages && <a href={`?${queryStr({ page: String(pageNum + 1) })}`} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold hover:bg-black/4">→</a>}
                  </div>
                </div>
              )}
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="İçerik Türüne Göre Dağılım">
                {turDagilimi.length === 0 ? <p className="text-xs text-muted">Veri yok.</p> : <TurDonut veriler={turDagilimi} toplam={total} />}
              </PanelBolumKarti>

              <PanelBolumKarti title="Duruma Göre Dağılım">
                {total === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-3">
                    {[
                      { label: 'Onaylanan', count: approvedCount, renk: 'bg-emerald-500' },
                      { label: 'Bekleyen', count: pendingCount, renk: 'bg-amber-400' },
                      { label: 'Reddedilen', count: rejectedCount, renk: 'bg-red-500' },
                    ].filter((r) => r.count > 0).map((r) => (
                      <div key={r.label} className="flex flex-col gap-1">
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-bold text-textStrong">{r.label}</span>
                          <span className="font-extrabold text-muted">{r.count.toLocaleString('tr-TR')} (%{Math.round((r.count / total) * 100)})</span>
                        </div>
                        <div className="h-2 overflow-hidden rounded-full bg-black/8">
                          <div className={`h-full rounded-full ${r.renk}`} style={{ width: `${(r.count / total) * 100}%` }} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <p className="rounded-xl border border-border px-3 py-2.5 text-[10px] text-muted">
                    Toplu onayla/reddet için ızgaradan fotoğraf seçin — seçim çubuğu orada belirir.
                  </p>
                  <HizliIslemButonu label="Otomatik Moderasyon Ayarları" description="Yapay zeka filtrelerini yönetin" icon={<SettingsIcon />} disabled title="Henüz bir AI içerik analizi sistemi yok — ayrı bir iş olarak planlanabilir" />
                  <HizliIslemButonu label="İçerik Politikaları" description="Topluluk kurallarını görüntüleyin" icon={<DocIcon />} disabled title="Henüz uygulanmadı" />
                </div>
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

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

function TurDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
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

function ImageIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><polyline points="12 7 12 12 15 15" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></svg>; }
function XIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" /></svg>; }
function HideIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" /><line x1="1" y1="1" x2="23" y2="23" /></svg>; }
function UploadIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="17 8 12 3 7 8" /><line x1="12" y1="3" x2="12" y2="15" /></svg>; }
function SettingsIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></svg>; }
function DocIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>; }
