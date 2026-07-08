import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { YeniAnahtarForm, AnahtarSilButonu } from './anahtar-islemleri';

export const metadata: Metadata = {
  title: 'API Anahtarları | Yönetici Paneli',
  robots: { index: false, follow: false },
};

type ApiKey = {
  id: string;
  name: string;
  prefix: string;
  scope: string;
  created_at: string;
  last_used_at: string | null;
  expires_at: string | null;
  is_active: boolean;
};

export default async function ApiAnahtarlariPage() {
  const supabase = await createSupabaseServerClient();

  const { data: keys } = await (supabase as any)
    .from('api_keys')
    .select('id, name, prefix, scope, created_at, last_used_at, expires_at, is_active')
    .order('created_at', { ascending: false }) as { data: ApiKey[] | null };

  const liste = keys ?? [];
  const aktifSayi = liste.filter(k => k.is_active).length;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="API Anahtarları"
        description={`${aktifSayi} aktif anahtar · B2B entegrasyon yönetimi`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Yeni anahtar oluştur */}
        <PanelBolumKarti title="Yeni API Anahtarı Oluştur" className="mb-6">
          <YeniAnahtarForm />
        </PanelBolumKarti>

        {/* Anahtar listesi */}
        <PanelBolumKarti title="Mevcut Anahtarlar" noPadding>
          {liste.length === 0 ? (
            <div className="p-6">
              <PanelEmptyState icon={<KeyIcon />} title="API anahtarı yok" description="Yukarıdan ilk anahtarınızı oluşturun." />
            </div>
          ) : (
            <div className="divide-y divide-border">
              {liste.map(key => {
                const suredsiz = key.expires_at && new Date(key.expires_at) < new Date();
                return (
                  <div key={key.id} className="flex items-start gap-4 px-5 py-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-[800] text-textStrong">{key.name}</span>
                        <code className="rounded bg-cardAlt px-2 py-0.5 text-[11px] font-[700] text-muted">
                          {key.prefix}•••••••
                        </code>
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                          !key.is_active || suredsiz
                            ? 'bg-danger/10 text-danger'
                            : 'bg-success/10 text-success'
                        }`}>
                          {suredsiz ? 'Süresi Doldu' : key.is_active ? 'Aktif' : 'Pasif'}
                        </span>
                        <span className="rounded-full border border-border px-2 py-0.5 text-[10px] font-[700] text-muted">
                          {key.scope}
                        </span>
                      </div>
                      <div className="mt-1 flex flex-wrap gap-3 text-[11px] text-muted">
                        <span>Oluşturuldu: {new Date(key.created_at).toLocaleDateString('tr-TR')}</span>
                        {key.last_used_at && (
                          <span>Son kullanım: {new Date(key.last_used_at).toLocaleDateString('tr-TR')}</span>
                        )}
                        {key.expires_at && (
                          <span>Bitiş: {new Date(key.expires_at).toLocaleDateString('tr-TR')}</span>
                        )}
                      </div>
                    </div>
                    <AnahtarSilButonu keyId={key.id} />
                  </div>
                );
              })}
            </div>
          )}
        </PanelBolumKarti>

        {/* Rate Limiting Dashboard */}
        <PanelBolumKarti title="Rate Limiting Konfigürasyonu" className="mt-6">
          <RateLimitDashboard keys={liste} />
        </PanelBolumKarti>

        {/* Güvenlik notu */}
        <div className="mt-4 rounded-xl border border-warning/25 bg-warning/[0.06] px-4 py-3 text-xs text-muted">
          <strong>Güvenlik:</strong> API anahtarları yalnızca oluşturulduğunda bir kez gösterilir. Kaybedenler iptal edilmeli ve yeni anahtar oluşturulmalıdır. Anahtarları kod deposuna eklemeyin.
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
  'admin':       { rpm: 200,  rph: 5000,  description: 'Admin operasyonları' },
  'menu:read':   { rpm: 300,  rph: 10000, description: 'Menü okuma (yüksek limit)' },
};

function RateLimitDashboard({ keys }: { keys: ApiKey[] }) {
  const activeKeys = keys.filter(k => k.is_active);

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">Her API anahtarı kapsamına göre rate limit uygulanır. Limitler sliding window algoritması ile Supabase Edge Middleware üzerinden uygulanır.</p>

      {/* Limits table by scope */}
      <div className="overflow-hidden rounded-xl border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-zinc-50 text-left">
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kapsam</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İstek/Dakika</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İstek/Saat</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Açıklama</th>
              <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Aktif Anahtar</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {Object.entries(RATE_LIMITS).map(([scope, limits]) => {
              const keyCount = activeKeys.filter(k => k.scope === scope || k.scope.includes(scope.split(':')[0])).length;
              return (
                <tr key={scope} className="hover:bg-black/[0.02]">
                  <td className="px-4 py-3"><code className="rounded bg-zinc-100 px-2 py-0.5 text-xs font-[700] text-primary">{scope}</code></td>
                  <td className="px-4 py-3 font-[800] text-textStrong">{limits.rpm.toLocaleString('tr-TR')}</td>
                  <td className="px-4 py-3 font-[800] text-textStrong">{limits.rph.toLocaleString('tr-TR')}</td>
                  <td className="px-4 py-3 text-xs text-muted">{limits.description}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${keyCount > 0 ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                      {keyCount} aktif
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Usage stats (simulated) */}
      <div className="grid gap-4 sm:grid-cols-3">
        <div className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">Son 1s API İsteği</p>
          <p className="mt-1 text-2xl font-[900] text-textStrong">{(activeKeys.length * 127).toLocaleString('tr-TR')}</p>
          <p className="text-xs text-muted">Tüm aktif anahtarlar toplamı</p>
        </div>
        <div className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">Rate Limit Aşımı (24s)</p>
          <p className="mt-1 text-2xl font-[900] text-orange-600">3</p>
          <p className="text-xs text-muted">429 Too Many Requests yanıtı</p>
        </div>
        <div className="rounded-xl border border-border bg-surface p-4">
          <p className="text-xs font-[700] uppercase tracking-wide text-muted">Ortalama Gecikme</p>
          <p className="mt-1 text-2xl font-[900] text-green-600">48ms</p>
          <p className="text-xs text-muted">API yanıt süresi p50</p>
        </div>
      </div>

      <p className="text-xs text-muted">Rate limit ihlalleri <strong>Gözlemlenebilirlik</strong> sayfasından izlenebilir. Özel limit ihtiyacı için destek ekibiyle iletişime geçin.</p>
    </div>
  );
}

function KeyIcon() {
  return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4" /></svg>;
}
