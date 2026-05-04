import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Arama | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; type?: string }> };

export default async function AdminSearchPage({ searchParams }: Props) {
  const { q = '', type = 'businesses' } = await searchParams;

  const supabase = await createSupabaseServerClient();

  let businesses: any[] = [];
  let users: any[] = [];

  if (q.length >= 2) {
    if (type === 'businesses' || type === 'all') {
      const { data } = await supabase
        .from('businesses')
        .select('id, name, slug, category, city, is_active, is_verified, created_at')
        .or(`name.ilike.%${q}%,slug.ilike.%${q}%,city.ilike.%${q}%`)
        .order('name', { ascending: true })
        .limit(30);
      businesses = data ?? [];
    }

    if (type === 'users' || type === 'all') {
      const { data } = await (supabase as any)
        .from('user_profiles')
        .select('id, display_name, email, role, created_at')
        .or(`display_name.ilike.%${q}%,email.ilike.%${q}%`)
        .order('created_at', { ascending: false })
        .limit(30);
      users = data ?? [];
    }
  }

  const totalResults = businesses.length + users.length;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Admin"
        title="Arama"
        description={q ? `"${q}" için ${totalResults} sonuç` : 'Platform genelinde arama yapın'}
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-4">
          {/* Search form */}
          <form method="get" className="flex gap-3">
            <input
              name="q"
              defaultValue={q}
              placeholder="İşletme adı, kullanıcı, şehir..."
              autoFocus
              className="flex-1 rounded-xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
            <div className="flex gap-1">
              {[
                { value: 'businesses', label: 'İşletmeler' },
                { value: 'users', label: 'Kullanıcılar' },
                { value: 'all', label: 'Tümü' },
              ].map(({ value, label }) => (
                <button
                  key={value}
                  type="submit"
                  name="type"
                  value={value}
                  className={`rounded-xl px-3 py-2 text-xs font-[700] transition-colors ${
                    type === value
                      ? 'bg-primary text-white'
                      : 'border border-border bg-card text-muted hover:text-textStrong'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
            <button
              type="submit"
              className="rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white hover:opacity-90 transition-opacity"
            >
              Ara
            </button>
          </form>

          {q.length < 2 && (
            <p className="text-center text-sm text-muted py-8">En az 2 karakter girin.</p>
          )}

          {/* Business results */}
          {businesses.length > 0 && (
            <PanelSectionCard title={`İşletmeler (${businesses.length})`} noPadding>
              <ul className="divide-y divide-border">
                {businesses.map((b) => (
                  <li key={b.id}>
                    <Link
                      href={`/admin/businesses?q=${encodeURIComponent(b.name)}`}
                      className="flex items-center justify-between px-5 py-3 hover:bg-black/[0.02] transition-colors"
                    >
                      <div>
                        <p className="font-[700] text-textStrong">{b.name}</p>
                        <p className="text-xs text-muted">{b.category} · {b.city} · {b.slug}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        {b.is_verified && (
                          <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-[700] text-blue-700">Doğrulandı</span>
                        )}
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[700] ${
                          b.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                        }`}>
                          {b.is_active ? 'Aktif' : 'Pasif'}
                        </span>
                      </div>
                    </Link>
                  </li>
                ))}
              </ul>
            </PanelSectionCard>
          )}

          {/* User results */}
          {users.length > 0 && (
            <PanelSectionCard title={`Kullanıcılar (${users.length})`} noPadding>
              <ul className="divide-y divide-border">
                {users.map((u: any) => (
                  <li key={u.id}>
                    <Link
                      href={`/admin/users/${u.id}`}
                      className="flex items-center justify-between px-5 py-3 hover:bg-black/[0.02] transition-colors"
                    >
                      <div>
                        <p className="font-[700] text-textStrong">{u.display_name ?? '—'}</p>
                        <p className="text-xs text-muted">{u.email ?? u.id}</p>
                      </div>
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-[700] ${
                        u.role === 'super_admin' || u.role === 'admin'
                          ? 'bg-purple-50 text-purple-700'
                          : u.role === 'community_mod'
                            ? 'bg-blue-50 text-blue-700'
                            : 'bg-zinc-100 text-zinc-500'
                      }`}>
                        {u.role ?? 'user'}
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            </PanelSectionCard>
          )}

          {q.length >= 2 && totalResults === 0 && (
            <PanelEmptyState
              icon={<SearchIcon />}
              title="Sonuç bulunamadı"
              description={`"${q}" için sonuç yok.`}
            />
          )}
        </div>
      </PanelContentSurface>
    </div>
  );
}

function SearchIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>;
}
