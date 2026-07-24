import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';

export const metadata: Metadata = {
  title: 'Geliştirici Araçları | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminDevToolsPage() {
  const supabase = await createSupabaseServerClient();

  // Queue counts RPC
  const [queueRpc, slaRpc] = await Promise.all([
    supabase.rpc('admin_get_queues_counts_v1' as never),
    supabase.rpc('admin_sla_metrics_v1' as never),
  ]);

  const queueCounts = (queueRpc.data as any) ?? {};
  const slaCounts = (slaRpc.data as any) ?? {};

  // Temp uploads count
  const { count: tempUploadsCount } = await (supabase as any)
    .from('temp_uploads')
    .select('id', { count: 'exact', head: true });

  // Rate limit events today
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const { count: rateLimitToday } = await (supabase as any)
    .from('edge_rate_limit_events')
    .select('id', { count: 'exact', head: true })
    .gte('created_at', today.toISOString());

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Geliştirici Araçları"
        description="Platform debug ve sistem bilgileri"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
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
            <pre className="overflow-auto rounded-lg bg-(--yd-color-bg) p-4 text-xs font-mono text-textStrong">
              {JSON.stringify(slaCounts, null, 2)}
            </pre>
          </PanelBolumKarti>

          {/* Useful links */}
          <PanelBolumKarti title="Hızlı Bağlantılar">
            <ul className="space-y-2 text-sm">
              {[
                { label: 'Supabase Dashboard', href: 'https://supabase.com/dashboard' },
                { label: 'Vercel Dashboard', href: 'https://vercel.com/dashboard' },
                { label: 'GitHub Repo', href: 'https://github.com' },
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

