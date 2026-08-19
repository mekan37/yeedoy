import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import {
  anahtarDurum, DURUM_ETIKETLERI, scopeEtiket, trend,
  type ApiKey,
} from './api-anahtarlari-yardimcilari';
import { AnahtarTablosu } from './anahtar-tablosu';
import { YeniAnahtarButonu } from './yeni-anahtar-modal';
import { DisaAktarButonu } from './disa-aktar-butonu';

export const metadata: Metadata = {
  title: 'API Anahtarları | Yönetici Paneli',
  robots: { index: false, follow: false },
};

const DAY = 86_400_000;

type Props = {
  searchParams: Promise<{ q?: string; scope?: string; durum?: string }>;
};

export default async function ApiAnahtarlariPage({ searchParams }: Props) {
  const { q = '', scope = '', durum = '' } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const sb = supabase as any;

  const { data: rawKeys } = await sb
    .from('api_keys')
    .select('id, name, prefix, scope, created_by, created_at, updated_at, last_used_at, expires_at, is_active')
    .order('created_at', { ascending: false }) as { data: ApiKey[] | null };

  const keys = rawKeys ?? [];

  const creatorIds = Array.from(new Set(keys.map((k) => k.created_by).filter((v): v is string => !!v)));
  const nameByUserId = new Map<string, string>();
  if (creatorIds.length > 0) {
    const { data: profiles } = await sb.from('user_profiles').select('user_id, display_name').in('user_id', creatorIds);
    for (const p of (profiles ?? []) as Array<{ user_id: string; display_name: string | null }>) {
      if (p.display_name) nameByUserId.set(p.user_id, p.display_name);
    }
  }
  const withNames: ApiKey[] = keys.map((k) => ({ ...k, created_by_name: k.created_by ? nameByUserId.get(k.created_by) ?? null : null }));

  // ── Filtreleme ──
  const qNorm = q.trim().toLocaleLowerCase('tr-TR');
  const filtered = withNames.filter((k) => {
    if (scope && k.scope !== scope) return false;
    if (durum && anahtarDurum(k) !== durum) return false;
    if (qNorm) {
      const hay = `${k.name} ${k.prefix}`.toLocaleLowerCase('tr-TR');
      if (!hay.includes(qNorm)) return false;
    }
    return true;
  });

  // ── Stat kartları (tüm anahtarlar, filtresiz) ──
  const total = withNames.length;
  const activeCount = withNames.filter((k) => anahtarDurum(k) === 'active').length;
  const expiringCount = withNames.filter((k) => anahtarDurum(k) === 'expiring').length;
  const expiredCount = withNames.filter((k) => anahtarDurum(k) === 'expired').length;
  const inactiveCount = withNames.filter((k) => anahtarDurum(k) === 'inactive').length;
  const unusedCount = withNames.filter((k) => k.is_active && !k.last_used_at).length;

  const now = Date.now();
  const thisWeek = withNames.filter((k) => new Date(k.created_at).getTime() >= now - 7 * DAY).length;
  const lastWeek = withNames.filter((k) => {
    const ts = new Date(k.created_at).getTime();
    return ts >= now - 14 * DAY && ts < now - 7 * DAY;
  }).length;

  // ── Kapsam dağılımı ──
  const scopeDagilimi = Object.entries(
    withNames.reduce<Record<string, number>>((acc, k) => {
      acc[k.scope] = (acc[k.scope] ?? 0) + 1;
      return acc;
    }, {}),
  ).sort((a, b) => b[1] - a[1]);

  // ── Süresi yaklaşan anahtarlar (sidebar listesi) ──
  const yaklasanlar = withNames
    .filter((k) => anahtarDurum(k) === 'expiring')
    .sort((a, b) => new Date(a.expires_at!).getTime() - new Date(b.expires_at!).getTime())
    .slice(0, 5);

  const scopeSecenekleri = Array.from(new Set(withNames.map((k) => k.scope)));

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="API Anahtarları"
        description={`${activeCount} aktif anahtar · B2B entegrasyon yönetimi`}
        actions={<YeniAnahtarButonu />}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Toplam Anahtar" value={total.toLocaleString('tr-TR')} tone="blue" icon={<KeyIcon />} trend={trend(thisWeek, lastWeek)} />
            <MetricCard title="Aktif Anahtar" value={activeCount.toLocaleString('tr-TR')} subtitle={total ? `%${Math.round((activeCount / total) * 100)}` : undefined} tone="green" icon={<CheckIcon />} />
            <MetricCard title="Süresi Yaklaşan" value={expiringCount.toLocaleString('tr-TR')} subtitle="7 gün içinde" tone="orange" icon={<ClockIcon />} />
            <MetricCard title="Süresi Dolmuş" value={expiredCount.toLocaleString('tr-TR')} tone="pink" icon={<AlertIcon />} />
            <MetricCard title="Pasif / İptal Edilen" value={inactiveCount.toLocaleString('tr-TR')} subtitle={total ? `%${Math.round((inactiveCount / total) * 100)}` : undefined} tone="purple" icon={<CircleIcon />} />
            <MetricCard title="Hiç Kullanılmayan" value={unusedCount.toLocaleString('tr-TR')} subtitle="Aktif ama hiç çağrılmamış" tone="primary" icon={<PulseIcon />} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
            <div className="flex min-w-0 flex-col gap-4">
              <form method="get" className="grid gap-3 rounded-xl border border-border bg-card p-3 md:grid-cols-4">
                <input
                  name="q"
                  defaultValue={q}
                  placeholder="Anahtar adı veya öneki ara..."
                  className="min-h-11 rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30 md:col-span-2"
                />
                <select name="scope" defaultValue={scope} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Kapsamlar</option>
                  {scopeSecenekleri.map((s) => <option key={s} value={s}>{scopeEtiket(s)}</option>)}
                </select>
                <select name="durum" defaultValue={durum} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30">
                  <option value="">Tüm Durumlar</option>
                  {Object.entries(DURUM_ETIKETLERI).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
                <div className="flex gap-2 md:col-span-4">
                  <button type="submit" className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90">Filtrele</button>
                  <Link href="/yonetici/api-anahtarlari" className="flex min-h-11 items-center rounded-xl border border-border px-4 text-sm font-bold text-muted hover:bg-black/4">Temizle</Link>
                  <div className="ml-auto">
                    <DisaAktarButonu rows={filtered} />
                  </div>
                </div>
              </form>

              {filtered.length === 0 ? (
                <PanelEmptyState
                  icon={<KeyIcon />}
                  title={total === 0 ? 'Henüz API anahtarı yok' : 'Sonuç bulunamadı'}
                  description={total === 0 ? '"Yeni API Anahtarı" ile ilk anahtarınızı oluşturun.' : 'Seçili filtrelere uygun anahtar yok.'}
                />
              ) : (
                <AnahtarTablosu keys={filtered} />
              )}

              {/* Rate Limiting Dashboard */}
              <div id="rate-limit-config">
                <PanelBolumKarti title="Rate Limiting Konfigürasyonu">
                  <RateLimitDashboard keys={withNames} />
                </PanelBolumKarti>
              </div>

              <div className="rounded-xl border border-warning/25 bg-warning/6 px-4 py-3 text-xs text-muted">
                <strong>Güvenlik:</strong> API anahtarları yalnızca oluşturulduğunda bir kez gösterilir. Kaybedenler iptal edilmeli ve yeni anahtar oluşturulmalıdır. Anahtarları kod deposuna eklemeyin.
              </div>
            </div>

            <div className="flex flex-col gap-4">
              <PanelBolumKarti title="Kapsam Dağılımı">
                {scopeDagilimi.length === 0 ? (
                  <p className="text-xs text-muted">Veri yok.</p>
                ) : (
                  <div className="flex flex-col gap-3">
                    {scopeDagilimi.map(([key, n]) => (
                      <div key={key} className="flex flex-col gap-1">
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-bold text-textStrong">{scopeEtiket(key)}</span>
                          <span className="font-extrabold text-muted">{n} (%{Math.round((n / total) * 100)})</span>
                        </div>
                        <div className="h-2 overflow-hidden rounded-full bg-black/8">
                          <div className="h-full rounded-full bg-primary" style={{ width: `${(n / total) * 100}%` }} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Süresi Yaklaşan Anahtarlar">
                {yaklasanlar.length === 0 ? (
                  <p className="text-xs text-muted">Süresi 7 gün içinde dolacak anahtar yok.</p>
                ) : (
                  <div className="flex flex-col gap-2.5">
                    {yaklasanlar.map((k) => (
                      <div key={k.id} className="flex items-center justify-between gap-2 text-xs">
                        <span className="min-w-0 truncate font-bold text-textStrong">{k.name}</span>
                        <span className="shrink-0 font-extrabold text-amber-700">
                          {Math.max(0, Math.ceil((new Date(k.expires_at!).getTime() - now) / DAY))} gün
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </PanelBolumKarti>

              <PanelBolumKarti title="Hızlı İşlemler">
                <div className="flex flex-col gap-2">
                  <YeniAnahtarButonu variant="list" />
                  <Link
                    href="/yonetici/api-anahtarlari?durum=expiring"
                    className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors hover:border-primary/30 hover:bg-black/2"
                  >
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-amber-50 text-amber-600"><ClockIcon /></div>
                    <div className="min-w-0">
                      <p className="text-xs font-extrabold text-textStrong">Süresi Yaklaşanları Görüntüle</p>
                      <p className="truncate text-[10px] text-muted">7 gün içinde dolacak anahtarları filtrele</p>
                    </div>
                  </Link>
                  <a
                    href="#rate-limit-config"
                    className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left transition-colors hover:border-primary/30 hover:bg-black/2"
                  >
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-blue-50 text-blue-600"><ShieldIcon /></div>
                    <div className="min-w-0">
                      <p className="text-xs font-extrabold text-textStrong">Yetki Seviyeleri / Rate Limit</p>
                      <p className="truncate text-[10px] text-muted">Kapsam bazlı limit konfigürasyonuna git</p>
                    </div>
                  </a>
                </div>
              </PanelBolumKarti>
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

// Rate Limit Scope → limits
const RATE_LIMITS: Record<string, { rpm: number; rph: number; description: string }> = {
  'read':        { rpm: 100,  rph: 3000,  description: 'Okuma operasyonları' },
  'write':       { rpm: 20,   rph: 500,   description: 'Yazma operasyonları' },
  'read,write':  { rpm: 60,   rph: 1500,  description: 'Okuma + yazma' },
  'read_write':  { rpm: 60,   rph: 1500,  description: 'Okuma + yazma' },
  'admin':       { rpm: 200,  rph: 5000,  description: 'Admin operasyonları' },
  'menu:read':   { rpm: 300,  rph: 10000, description: 'Menü okuma (yüksek limit)' },
  'read:businesses': { rpm: 150, rph: 4000, description: 'İşletme okuma' },
  'read:menus':  { rpm: 300,  rph: 10000, description: 'Menü okuma' },
};

function RateLimitDashboard({ keys }: { keys: ApiKey[] }) {
  const activeKeys = keys.filter((k) => k.is_active);

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">Her API anahtarı kapsamına göre rate limit uygulanır. Limitler sliding window algoritması ile Supabase Edge Middleware üzerinden uygulanır.</p>

      <div className="overflow-hidden rounded-xl border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-zinc-50 text-left">
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kapsam</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İstek/Dakika</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İstek/Saat</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Açıklama</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Aktif Anahtar</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {Object.entries(RATE_LIMITS).map(([scope, limits]) => {
              const keyCount = activeKeys.filter((k) => k.scope === scope).length;
              return (
                <tr key={scope} className="hover:bg-black/2">
                  <td className="px-4 py-3"><code className="rounded bg-zinc-100 px-2 py-0.5 text-xs font-bold text-primary">{scope}</code></td>
                  <td className="px-4 py-3 font-extrabold text-textStrong">{limits.rpm.toLocaleString('tr-TR')}</td>
                  <td className="px-4 py-3 font-extrabold text-textStrong">{limits.rph.toLocaleString('tr-TR')}</td>
                  <td className="px-4 py-3 text-xs text-muted">{limits.description}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold ${keyCount > 0 ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                      {keyCount} aktif
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <p className="text-xs text-muted">Rate limit ihlalleri <strong>Gözlemlenebilirlik</strong> sayfasından izlenebilir. Özel limit ihtiyacı için destek ekibiyle iletişime geçin.</p>
    </div>
  );
}

function KeyIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4" /></svg>; }
function CheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>; }
function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
function AlertIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>; }
function CircleIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="8" width="18" height="8" rx="4" /></svg>; }
function PulseIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>; }
function ShieldIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
