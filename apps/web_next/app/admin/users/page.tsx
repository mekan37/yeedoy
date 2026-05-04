import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Kullanıcılar | Admin Panel',
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
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  let query = (supabase as any)
    .from('user_profiles')
    .select('id, display_name, email, role, created_at, city', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);

  if (q) {
    query = query.or(`display_name.ilike.%${q}%,email.ilike.%${q}%`);
  }
  if (role) {
    query = query.eq('role', role);
  }

  const { data: users, count } = await query;
  const list = (users ?? []) as any[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Kullanıcılar"
        description={count != null ? `${count.toLocaleString('tr-TR')} kullanıcı` : ''}
      />
      <PanelContentSurface className="pt-6">
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
          <PanelSectionCard noPadding>
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
                        <Link href={`/admin/users/${u.id}`} className="group">
                          <p className="font-[700] text-textStrong group-hover:text-primary transition-colors">
                            {u.display_name ?? '—'}
                          </p>
                          <p className="text-xs text-muted">{u.email ?? u.id.slice(0, 12)}</p>
                        </Link>
                      </td>
                      <td className="px-5 py-3">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${roleInfo.className}`}>
                          {roleInfo.label}
                        </span>
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
                  {pageNum > 1 && <a href={`?q=${q}&role=${role}&page=${pageNum - 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">← Önceki</a>}
                  {pageNum < totalPages && <a href={`?q=${q}&role=${role}&page=${pageNum + 1}`} className="rounded-lg border border-border px-3 py-1 text-xs font-[700] text-textStrong hover:bg-black/[0.02]">Sonraki →</a>}
                </div>
              </div>
            )}
          </PanelSectionCard>
        )}
      </PanelContentSurface>
    </div>
  );
}

function UsersIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
