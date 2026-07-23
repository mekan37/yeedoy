import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Roller | Yonetici Paneli',
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
  const serviceClient = createSupabaseServiceClient();
  const authUsers = serviceClient
    ? (await serviceClient.auth.admin.listUsers({ page: 1, perPage: 1000 })).data.users ?? []
    : [];

  const roleCounts = ROLES.map((role) => ({
    ...role,
    count: authUsers.filter((user) => getUserRole(user) === role.key).length,
  }));

  // Recent privileged users
  const profileIds = authUsers.map((user) => user.id).filter(Boolean);
  const profiles = await getProfilesByUserIds(supabase as any, profileIds);
  const list = authUsers
    .map((user) => {
      const role = getUserRole(user);
      const profile = profiles.get(user.id);
      return {
        id: user.id,
        display_name: profile?.display_name ?? getMetadataText(user, 'display_name') ?? getMetadataText(user, 'name'),
        email: user.email ?? null,
        role,
        created_at: user.created_at,
      };
    })
    .filter((user) => ['super_admin', 'admin', 'community_mod'].includes(user.role))
    .sort((a, b) => new Date(b.created_at ?? 0).getTime() - new Date(a.created_at ?? 0).getTime())
    .slice(0, 50);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Roller"
        description="Kullanıcı rol dağılımı ve ayrıcalıklı hesaplar"
      />
      <PanelIcerikYuzeyi className="pt-6">
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

          {/* Permission Matrix */}
          <PanelBolumKarti title="İzin Matrisi — Rol × Yetki">
            <PermissionMatrix />
          </PanelBolumKarti>

          <PanelBolumKarti title="Ayrıcalıklı Hesaplar" noPadding>
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
                        <Link href={`/yonetici/kullanicilar/${u.id}`} className="group">
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
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

const PERMISSIONS = [
  { id: 'manage_users',       label: 'Kullanıcı Yönetimi',     super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'manage_businesses',  label: 'İşletme Yönetimi',       super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'moderate_reviews',   label: 'Yorum Moderasyonu',      super_admin: true,  admin: true,  community_mod: true,  user: false },
  { id: 'moderate_photos',    label: 'Fotoğraf Moderasyonu',   super_admin: true,  admin: true,  community_mod: true,  user: false },
  { id: 'manage_feature_flags', label: 'Feature Flags',        super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'manage_api_keys',    label: 'API Anahtarları',        super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'view_analytics',     label: 'Analitik Görüntüleme',   super_admin: true,  admin: true,  community_mod: true,  user: false },
  { id: 'manage_sponsorships', label: 'Sponsorluk Yönetimi',  super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'view_audit_log',     label: 'Denetim Kaydı',         super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'manage_roles',       label: 'Rol Yönetimi',           super_admin: true,  admin: false, community_mod: false, user: false },
  { id: 'manage_fraud',       label: 'Fraud Yönetimi',         super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'bulk_operations',    label: 'Toplu İşlemler',         super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'send_push',          label: 'Push Kampanya Gönder',   super_admin: true,  admin: true,  community_mod: false, user: false },
  { id: 'manage_support',     label: 'Müşteri Destek',         super_admin: true,  admin: true,  community_mod: true,  user: false },
  { id: 'export_data',        label: 'Veri Dışa Aktarma',      super_admin: true,  admin: true,  community_mod: false, user: false },
];

function PermissionMatrix() {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border">
            <th className="px-4 py-3 text-left text-[11px] font-[800] uppercase tracking-wide text-muted w-48">İzin</th>
            {['super_admin', 'admin', 'community_mod', 'user'].map(role => {
              const info = ROLES.find(r => r.key === role);
              return (
                <th key={role} className="px-4 py-3 text-center text-[11px] font-[800] uppercase tracking-wide text-muted">
                  <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[800] ${info?.className ?? 'bg-zinc-100 text-zinc-500'}`}>
                    {info?.label ?? role}
                  </span>
                </th>
              );
            })}
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {PERMISSIONS.map(perm => (
            <tr key={perm.id} className="hover:bg-black/[0.02]">
              <td className="px-4 py-2.5 text-sm font-[600] text-textStrong">{perm.label}</td>
              {(['super_admin', 'admin', 'community_mod', 'user'] as const).map(role => (
                <td key={role} className="px-4 py-2.5 text-center">
                  {perm[role]
                    ? <span className="text-green-600">✅</span>
                    : <span className="text-zinc-200">○</span>
                  }
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ShieldIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>;
}

function getUserRole(user: any) {
  const role = String(user.app_metadata?.role ?? user.user_metadata?.role ?? 'user').toLocaleLowerCase('tr-TR');
  return ROLES.some((item) => item.key === role) ? role : 'user';
}

function getMetadataText(user: any, key: string) {
  const value = user.user_metadata?.[key] ?? user.app_metadata?.[key];
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

async function getProfilesByUserIds(supabase: any, userIds: string[]) {
  if (userIds.length === 0) return new Map<string, { display_name: string | null }>();

  const { data } = await supabase
    .from('user_profiles')
    .select('user_id, display_name')
    .in('user_id', userIds);

  return new Map(
    ((data ?? []) as any[]).map((profile) => [
      profile.user_id,
      { display_name: profile.display_name ?? null },
    ]),
  );
}
