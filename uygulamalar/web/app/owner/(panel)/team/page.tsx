import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Ekip | Owner Panel',
  robots: { index: false, follow: false },
};

const ROLE_LABELS: Record<string, { label: string; className: string }> = {
  manager: { label: 'Yönetici', className: 'bg-purple-50 text-purple-700' },
  editor: { label: 'Editör', className: 'bg-blue-50 text-blue-700' },
  staff: { label: 'Personel', className: 'bg-zinc-100 text-zinc-600' },
  viewer: { label: 'İzleyici', className: 'bg-zinc-50 text-zinc-500' },
};

export default async function OwnerTeamPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string }> | null };

  const businessIds = (businesses ?? []).map((b) => b.id);
  const businessMap = Object.fromEntries((businesses ?? []).map((b) => [b.id, b.name]));

  const { data: members } = businessIds.length > 0
    ? await (supabase as any)
        .from('business_team_memberships')
        .select('id, business_id, role, created_at, user_profiles(id, display_name, email)')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
    : { data: [] };

  const list = (members ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Ekip"
        description="İşletme erişim üyeleri"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<UsersIcon />}
            title="Ekip üyesi yok"
            description="Ekip üyesi davet etmek için işletme ayarlarından yönetin."
          />
        ) : (
          <PanelSectionCard noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  {businessIds.length > 1 && (
                    <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  )}
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Rol</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Eklenme</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((m: any) => {
                  const roleConfig = ROLE_LABELS[m.role] ?? ROLE_LABELS.viewer;
                  return (
                    <tr key={m.id} className="hover:bg-black/[0.02]">
                      <td className="px-5 py-3">
                        <p className="font-[700] text-textStrong">
                          {m.user_profiles?.display_name ?? '—'}
                        </p>
                        <p className="text-xs text-muted">{m.user_profiles?.email ?? '—'}</p>
                      </td>
                      {businessIds.length > 1 && (
                        <td className="px-5 py-3 text-muted">{businessMap[m.business_id] ?? '—'}</td>
                      )}
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${roleConfig.className}`}>
                          {roleConfig.label}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(m.created_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function UsersIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
