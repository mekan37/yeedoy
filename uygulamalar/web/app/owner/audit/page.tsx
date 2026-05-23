import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Denetim Kaydı | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerAuditPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: logs } = await (supabase as any)
    .from('admin_audit_log')
    .select('id, action, resource_type, resource_id, created_at')
    .eq('actor_id', user!.id)
    .order('created_at', { ascending: false })
    .limit(100) as { data: Array<{ id: string; action: string; resource_type: string | null; resource_id: string | null; created_at: string }> | null };

  const list = (logs ?? []) as Array<{ id: string; action: string; resource_type: string | null; resource_id: string | null; created_at: string }>;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Denetim Kaydı"
        description="Hesabınıza ait eylem geçmişi"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<ShieldIcon />}
            title="Denetim kaydı yok"
            description="Hesabınıza ait henüz kayıtlı eylem bulunmuyor."
          />
        ) : (
          <PanelSectionCard noPadding>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border">
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Eylem</th>
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Kaynak</th>
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Hedef</th>
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Tarih</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {list.map((log) => (
                    <tr key={log.id}>
                      <td className="px-5 py-3 font-[700] text-textStrong">{log.action}</td>
                      <td className="px-5 py-3 text-muted">{log.resource_type ?? '—'}</td>
                      <td className="max-w-[180px] truncate px-5 py-3 text-muted">{log.resource_id ?? '—'}</td>
                      <td className="px-5 py-3 text-muted">
                        {new Date(log.created_at).toLocaleDateString('tr-TR', {
                          day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                        })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function ShieldIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}
