import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';

export const metadata: Metadata = {
  title: 'Geliştirici Araçları | Yonetici Paneli',
  robots: { index: false, follow: false },
};

function formatBytes(bytes: number): string {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(0)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
}

export default async function AdminDevToolsPage() {
  const yetkili = await hasPermission('page:gelistirme-araclari');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Geliştirici Araçları" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Geliştirici Araçları" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();

  // DB yanıt süresi: bu RPC çağrısının gidiş-dönüş süresi — dürüst bir "ping" ölçümü.
  const pingStart = Date.now();
  const dbHealthRpc = await supabase.rpc('admin_db_health_v1' as never);
  const dbPingMs = Date.now() - pingStart;

  const [queueRpc, slaRpc] = await Promise.all([
    supabase.rpc('admin_get_queues_counts_v1' as never),
    supabase.rpc('admin_sla_metrics_v1' as never),
  ]);

  const queueCounts = (queueRpc.data as any) ?? {};
  const slaCounts = (slaRpc.data as any) ?? {};
  const dbHealthRow = Array.isArray(dbHealthRpc.data) ? dbHealthRpc.data[0] : null;
  const activeConnections = (dbHealthRow as any)?.active_connections ?? null;
  const dbSizeBytes = (dbHealthRow as any)?.db_size_bytes ?? null;
  const dbReachable = !dbHealthRpc.error;

  const totalPendingQueue = Object.values(queueCounts).reduce<number>((sum, v) => sum + (typeof v === 'number' ? v : 0), 0);

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const [{ count: tempUploadsCount }, { count: rateLimitToday }] = await Promise.all([
    (supabase as any).from('temp_uploads').select('id', { count: 'exact', head: true }),
    (supabase as any).from('edge_rate_limit_events').select('id', { count: 'exact', head: true }).gte('created_at', today.toISOString()),
  ]);

  const now = new Date();

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Geliştirici Araçları"
        description="Platform debug bilgilerini ve gerçek sistem durumunu görüntüleyin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <MetricCard title="Şu An" value={now.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })} subtitle={now.toLocaleDateString('tr-TR')} icon={<ClockIcon />} />
            <MetricCard title="DB Yanıt Süresi" value={`${dbPingMs} ms`} subtitle={dbReachable ? 'Erişilebilir' : 'Hata'} icon={<PulseIcon />} />
            <MetricCard title="DB Aktif Bağlantı" value={activeConnections !== null ? activeConnections.toLocaleString('tr-TR') : '—'} icon={<PlugIcon />} />
            <MetricCard title="DB Boyutu" value={dbSizeBytes !== null ? formatBytes(dbSizeBytes) : '—'} icon={<DatabaseIcon />} />
            <MetricCard title="Bekleyen Kuyruk" value={totalPendingQueue.toLocaleString('tr-TR')} icon={<QueueIcon />} />
            <MetricCard title="Rate Limit (Bugün)" value={(rateLimitToday ?? 0).toLocaleString('tr-TR')} icon={<ShieldIcon />} />
          </div>

          {/* Hizmet durumu — yalnızca gerçekten ölçülen tek hizmet: veritabanı */}
          <PanelBolumKarti title="Hizmet Durumu" description="Bu platform serverless (Vercel + Supabase) üzerinde çalışıyor — izlenebilecek tek gerçek 'hizmet' veritabanı bağlantısıdır. Ayrı sunucu/konteyner/Redis/S3 altyapısı yok.">
            <div className="overflow-hidden rounded-xl border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-zinc-50 text-left">
                    <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Hizmet</th>
                    <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                    <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Yanıt Süresi</th>
                    <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Son Kontrol</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  <tr>
                    <td className="px-4 py-3 font-bold text-textStrong">Veritabanı (Supabase Postgres)</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold ${dbReachable && dbPingMs < 1000 ? 'bg-emerald-50 text-emerald-700' : dbReachable ? 'bg-amber-50 text-amber-700' : 'bg-red-50 text-red-700'}`}>
                        {dbReachable && dbPingMs < 1000 ? 'Sağlıklı' : dbReachable ? 'Yavaş' : 'Erişilemiyor'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-textStrong">{dbPingMs} ms</td>
                    <td className="px-4 py-3 text-xs text-muted">{now.toLocaleTimeString('tr-TR')}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </PanelBolumKarti>

          {/* Environment */}
          <PanelBolumKarti title="Ortam">
            <dl className="grid grid-cols-1 gap-3 sm:grid-cols-2 text-sm">
              <div>
                <dt className="text-xs font-bold uppercase tracking-wide text-muted">Node Env</dt>
                <dd className="mt-0.5 font-mono text-xs text-textStrong">{process.env.NODE_ENV}</dd>
              </div>
              <div>
                <dt className="text-xs font-bold uppercase tracking-wide text-muted">Supabase URL</dt>
                <dd className="mt-0.5 font-mono text-xs text-textStrong">
                  {process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/https?:\/\//, '').split('.')[0] ?? '—'}...
                </dd>
              </div>
              <div>
                <dt className="text-xs font-bold uppercase tracking-wide text-muted">Geçici Yüklemeler</dt>
                <dd className="mt-0.5 font-mono text-xs text-textStrong">{(tempUploadsCount ?? 0).toLocaleString('tr-TR')}</dd>
              </div>
              <div>
                <dt className="text-xs font-bold uppercase tracking-wide text-muted">Rate Limit (bugün)</dt>
                <dd className="mt-0.5 font-mono text-xs text-textStrong">{(rateLimitToday ?? 0).toLocaleString('tr-TR')}</dd>
              </div>
            </dl>
          </PanelBolumKarti>

          {/* Queue counts RPC output */}
          <PanelBolumKarti title="Kuyruk Sayıları (RPC)">
            <pre className="overflow-auto rounded-lg bg-(--yd-color-bg) p-4 text-xs font-mono text-textStrong">
              {JSON.stringify(queueCounts, null, 2)}
            </pre>
          </PanelBolumKarti>

          {/* SLA metrics */}
          <PanelBolumKarti title="SLA Metrikleri (RPC)">
            <dl className="grid grid-cols-1 gap-3 sm:grid-cols-2 text-sm">
              {Object.entries(slaCounts).map(([key, val]) => (
                <div key={key}>
                  <dt className="text-xs font-bold uppercase tracking-wide text-muted">{key.replace(/_/g, ' ')}</dt>
                  <dd className="mt-0.5 font-extrabold text-textStrong">{String(val)}</dd>
                </div>
              ))}
            </dl>
          </PanelBolumKarti>

          {/* Useful links */}
          <PanelBolumKarti title="Hızlı Bağlantılar">
            <ul className="space-y-2 text-sm">
              {[
                { label: 'Supabase Dashboard', href: 'https://supabase.com/dashboard' },
                { label: 'Vercel Dashboard', href: 'https://vercel.com/dashboard' },
              ].map(({ label, href }) => (
                <li key={label}>
                  <a
                    href={href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-(--yd-color-primary) hover:underline"
                  >
                    {label} ↗
                  </a>
                </li>
              ))}
            </ul>
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function ClockIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" /></svg>; }
function PulseIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>; }
function PlugIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 9.5V4a1 1 0 0 0-1-1h-3a1 1 0 0 0-1 1v5.5" /><path d="M6 9.5V4a1 1 0 0 0-1-1H2a1 1 0 0 0-1 1v5.5" /><path d="M15 9.5H1v3a5 5 0 0 0 5 5h4a5 5 0 0 0 5-5z" /><line x1="8" y1="17.5" x2="8" y2="22" /></svg>; }
function DatabaseIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><ellipse cx="12" cy="5" rx="9" ry="3" /><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3" /><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5" /></svg>; }
function QueueIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 6h11" /><path d="M9 12h11" /><path d="M9 18h11" /><path d="m3 6 1 1 2-2" /><path d="m3 12 1 1 2-2" /><path d="m3 18 1 1 2-2" /></svg>; }
function ShieldIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>; }
