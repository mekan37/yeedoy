import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Aktivite | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerActivityPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const businessIds = (businesses ?? []).map((b) => b.id);

  const { data: logs } = businessIds.length > 0
    ? await (supabase as any)
        .from('admin_audit_log')
        .select('id, action, resource_type, resource_id, created_at, metadata')
        .in('resource_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(100)
    : { data: [] };

  const list = (logs ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Aktivite"
        description="İşletmelerinize ait son aktivite kayıtları"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<ActivityIcon />}
            title="Aktivite kaydı yok"
            description="İşletmelerinize ait henüz kayıtlı bir aktivite bulunmuyor."
          />
        ) : (
          <PanelSectionCard noPadding>
            <ul className="divide-y divide-border">
              {list.map((log: any) => (
                <li key={log.id} className="flex items-start justify-between gap-4 px-5 py-3">
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-[700] text-textStrong">{log.action}</p>
                    <p className="text-xs text-muted">
                      {log.resource_type}
                      {log.resource_id ? ` · ${log.resource_id}` : ''}
                    </p>
                  </div>
                  <p className="shrink-0 text-xs text-muted">
                    {new Date(log.created_at).toLocaleDateString('tr-TR', {
                      day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
                    })}
                  </p>
                </li>
              ))}
            </ul>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function ActivityIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
    </svg>
  );
}
