import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { RolDegistirIstemci } from './rol-degistir-istemci';

export const metadata: Metadata = {
  title: 'Kullanıcılar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; role?: string; page?: string }> };
const PAGE_SIZE = 50;

const ROLE_MAP: Record<string, { label: string; className: string }> = {
  super_admin: { label: 'Süper Admin', className: 'bg-purple-100 text-purple-800' },
  admin: { label: 'Admin', className: 'bg-purple-50 text-purple-700' },
  community_mod: { label: 'Moderatör', className: 'bg-blue-50 text-blue-700' },
  user: { label: 'Kullanıcı', className: 'bg-zinc-100 text-zinc-500' },
};

export default async function AdminUsersPage({ searchParams }: Props) {
  const { q = '', role = '', page = '1' } = await searchParams;
  const pageNum = Math.max(1, parseInt(page, 10));

  const supabase = await createSupabaseServerClient();
  const serviceClient = createSupabaseServiceClient();

  const { users, count, hasNextPage } = serviceClient
    ? await listAuthUsers(serviceClient as any, { q: q.trim(), role, page: pageNum })
    : await listProfileUsers(supabase as any, { q: q.trim(), role, page: pageNum });

  const list = users;
  const totalPages = count != null ? Math.ceil(count / PAGE_SIZE) : pageNum + (hasNextPage ? 1 : 0);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Kullanıcılar"
        description={count != null ? `${count.toLocaleString('tr-TR')} kullanıcı` : `${list.length.toLocaleString('tr-TR')} kullanıcı`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Filters */}
        <form method="get" className="mb-4 flex flex-wrap gap-3">
          <input
            name="q"
            defaultValue={q}
            placeholder="Ad veya e-posta ara..."
            className="w-64 rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
          <div className="flex gap-1">
            {[
              { value: '', label: 'Tümü' },
              { value: 'super_admin', label: 'Süper Admin' },
              { value: 'admin', label: 'Admin' },
              { value: 'community_mod', label: 'Moderatör' },
            ].map(({ value, label }) => (
              <button
                key={value}
                type="submit"
                name="role"
                value={value}
                className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${
                  role === value ? 'bg-primary text-white' : 'border border-border bg-card text-muted hover:text-textStrong'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </form>

        {list.length === 0 ? (
          <PanelEmptyState icon={<UsersIcon />} title="Kullanıcı bulunamadı" />
        ) : (
          <PanelBolumKarti noPadding>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Rol</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şehir</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kayıt</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {list.map((u: any) => {
                  const roleInfo = ROLE_MAP[u.role] ?? ROLE_MAP['user'];
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
                        <RolDegistirIstemci
                          userId={u.id}
                          currentRole={u.role ?? 'user'}
                          roleMap={ROLE_MAP}
                        />
                      </td>
                      <td className="px-5 py-3 text-muted">{u.city ?? '—'}</td>
                      <td className="px-5 py-3 text-xs text-muted">
                        {new Date(u.created_at).toLocaleDateString('tr-TR')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            {totalPages > 1 && (
              <div className="flex items-center justify-between border-t border-border px-5 py-3">
                <span className="text-xs text-muted">Sayfa {pageNum} / {totalPages}</span>
                <div className="flex gap-2">
                  {pageNum > 1 && <Link href={`?q=${encodeURIComponent(q)}&role=${encodeURIComponent(role)}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">← Önceki</Link>}
                  {pageNum < totalPages && <Link href={`?q=${encodeURIComponent(q)}&role=${encodeURIComponent(role)}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">Sonraki →</Link>}
                </div>
              </div>
            )}
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

type AdminUserListRow = {
  id: string;
  display_name: string | null;
  email: string | null;
  role: string;
  city: string | null;
  created_at: string;
};

async function listAuthUsers(
  supabase: any,
  input: { q: string; role: string; page: number },
): Promise<{ users: AdminUserListRow[]; count: number | null; hasNextPage: boolean }> {
  const needsClientFilter = Boolean(input.q || input.role);
  const perPage = needsClientFilter ? 1000 : PAGE_SIZE;
  const page = needsClientFilter ? 1 : input.page;

  const { data, error } = await supabase.auth.admin.listUsers({ page, perPage });
  if (error) return { users: [], count: 0, hasNextPage: false };

  const authUsers = data?.users ?? [];
  const profileIds = authUsers.map((user: any) => user.id).filter(Boolean);
  const profiles = await getProfilesByUserIds(supabase, profileIds);

  let rows: AdminUserListRow[] = authUsers.map((user: any) => {
    const profile = profiles.get(user.id);
    const role = getUserRole(user);
    return {
      id: user.id,
      display_name: profile?.display_name ?? getMetadataText(user, 'display_name') ?? getMetadataText(user, 'name'),
      email: user.email ?? null,
      role,
      city: getMetadataText(user, 'city'),
      created_at: user.created_at ?? profile?.created_at ?? new Date(0).toISOString(),
    };
  });

  if (input.q) {
    const needle = input.q.toLocaleLowerCase('tr-TR');
    rows = rows.filter((user) =>
      [user.display_name, user.email, user.city, user.id]
        .some((value) => value?.toLocaleLowerCase('tr-TR').includes(needle)),
    );
  }
  if (input.role) {
    rows = rows.filter((user) => user.role === input.role);
  }

  const filteredCount = rows.length;
  const pagedRows = needsClientFilter
    ? rows.slice((input.page - 1) * PAGE_SIZE, input.page * PAGE_SIZE)
    : rows;

  return {
    users: pagedRows,
    count: needsClientFilter ? filteredCount : null,
    hasNextPage: !needsClientFilter && authUsers.length === PAGE_SIZE,
  };
}

async function listProfileUsers(
  supabase: any,
  input: { q: string; role: string; page: number },
): Promise<{ users: AdminUserListRow[]; count: number | null; hasNextPage: boolean }> {
  let query = supabase
    .from('user_profiles')
    .select('user_id, display_name, created_at', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range((input.page - 1) * PAGE_SIZE, input.page * PAGE_SIZE - 1);

  if (input.q) {
    query = query.ilike('display_name', `%${input.q.replace(/[%,_]/g, ' ')}%`);
  }

  const { data, count } = await query;
  const rows = ((data ?? []) as any[])
    .map((profile) => ({
      id: profile.user_id,
      display_name: profile.display_name ?? null,
      email: null,
      role: 'user',
      city: null,
      created_at: profile.created_at,
    }))
    .filter((user) => !input.role || user.role === input.role);

  return { users: rows, count, hasNextPage: false };
}

async function getProfilesByUserIds(supabase: any, userIds: string[]) {
  if (userIds.length === 0) return new Map<string, { display_name: string | null; created_at: string | null }>();

  const { data } = await supabase
    .from('user_profiles')
    .select('user_id, display_name, created_at')
    .in('user_id', userIds);

  return new Map(
    ((data ?? []) as any[]).map((profile) => [
      profile.user_id,
      { display_name: profile.display_name ?? null, created_at: profile.created_at ?? null },
    ]),
  );
}

function getUserRole(user: any) {
  const role = String(user?.app_metadata?.role ?? user?.user_metadata?.role ?? 'user').toLocaleLowerCase('tr-TR');
  return ROLE_MAP[role] ? role : 'user';
}

function getMetadataText(user: any, key: string) {
  const value = user?.user_metadata?.[key] ?? user?.app_metadata?.[key];
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function UsersIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
