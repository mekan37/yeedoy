import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { MetricCard } from '@/src/ui/components/metric-card';

export const metadata: Metadata = {
  title: 'Roller | Admin Panel',
  robots: { index: false, follow: false },
};

const ROLES = [
  { key: 'super_admin', label: 'Süper Admin', description: 'Tüm yetkilere sahip', className: 'bg-purple-100 text-purple-800' },
  { key: 'admin', label: 'Admin', description: 'Platform yönetimi', className: 'bg-purple-50 text-purple-700' },
  { key: 'community_mod', label: 'Moderatör', description: 'İçerik moderasyonu', className: 'bg-blue-50 text-blue-700' },
  { key: 'user', label: 'Kullanıcı', description: 'Standart kullanıcı', className: 'bg-zinc-100 text-zinc-500' },
];

export default async function AdminRolesPage() {
  const supabase = await createSupabaseServerClient();

  const roleCounts = await Promise.all(
    ROLES.map(async (role) => {
      const { count } = await (supabase as any)
        .from('user_profiles')
        .select('id', { count: 'exact', head: true })
        .eq('role', role.key);
      return { ...role, count: count ?? 0 };
    }),
  );

  // Recent privileged users
  const { data: privileged } = await (supabase as any)
    .from('user_profiles')
    .select('id, display_name, email, role, created_at')
    .in('role', ['super_admin', 'admin', 'community_mod'])
    .order('created_at', { ascending: false })
    .limit(50);

  const list = (privileged ?? []) as any[];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Roller"
        description="Kullanıcı rol dağılımı ve ayrıcalıklı hesaplar"
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            {roleCounts.map((r) => (
              <MetricCard
                key={r.key}
                title={r.label}
                value={r.count.toLocaleString('tr-TR')}
                subtitle={r.description}
                icon={<ShieldIcon />}
              />
            ))}
          </div>

          <PanelSectionCard title="Ayrıcalıklı Hesaplar" noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Rol</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kayıt</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((u: any) => {
                  const roleInfo = ROLES.find((r) => r.key === u.role);
                  return (
                    <tr key={u.id} className="hover:bg-black/[0.01]">
                      <td className="px-5 py-3">
                        <Link href={`/admin/users/${u.id}`} className="group">
                          <p className="font-[700] text-textStrong group-hover:text-primary transition-colors">
                            {u.display_name ?? '—'}
                          </p>
                          <p className="text-xs text-muted">{u.email ?? u.id.slice(0, 12)}</p>
                        </Link>
                      </td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${roleInfo?.className ?? 'bg-zinc-100 text-zinc-500'}`}>
                          {roleInfo?.label ?? u.role}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(u.created_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </PanelSectionCard>
        </div>
      </PanelContentSurface>
    </div>
  );
}

function ShieldIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>;
}
