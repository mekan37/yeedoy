import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any).from('user_profiles').select('display_name').eq('id', id).single();
  return {
    title: data ? `${data.display_name} | Admin Panel` : 'Kullanıcı | Admin Panel',
    robots: { index: false, follow: false },
  };
}

const ROLE_MAP: Record<string, { label: string; className: string }> = {
  super_admin: { label: 'Süper Admin', className: 'bg-purple-100 text-purple-800' },
  admin: { label: 'Admin', className: 'bg-purple-50 text-purple-700' },
  community_mod: { label: 'Moderatör', className: 'bg-blue-50 text-blue-700' },
  user: { label: 'Kullanıcı', className: 'bg-zinc-100 text-zinc-500' },
};

export default async function AdminUserDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();

  const { data: user } = await (supabase as any)
    .from('user_profiles')
    .select('id, display_name, email, role, created_at, city, bio, avatar_url')
    .eq('id', id)
    .single();

  if (!user) notFound();

  const [claimsRes, reviewsRes, submissionsRes] = await Promise.all([
    (supabase as any)
      .from('owner_claims')
      .select('id, status, created_at, businesses(name)')
      .eq('user_id', id)
      .order('created_at', { ascending: false })
      .limit(10),
    (supabase as any)
      .from('business_reviews')
      .select('id, rating, content, created_at, businesses(name)')
      .eq('created_by', id)
      .order('created_at', { ascending: false })
      .limit(10),
    (supabase as any)
      .from('business_submissions')
      .select('id, name, status, created_at')
      .eq('submitted_by', id)
      .order('created_at', { ascending: false })
      .limit(10),
  ]);

  const claims = (claimsRes.data ?? []) as any[];
  const reviews = (reviewsRes.data ?? []) as any[];
  const submissions = (submissionsRes.data ?? []) as any[];

  const roleInfo = ROLE_MAP[user.role] ?? ROLE_MAP['user'];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Kullanıcılar"
        title={user.display_name ?? 'Anonim'}
        description={user.email ?? user.id}
        actions={
          <Link href="/admin/users">
            <PanelActionButton variant="ghost">← Geri</PanelActionButton>
          </Link>
        }
      />
      <PanelContentSurface className="pt-6">
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          <div className="flex flex-col gap-5">
            <PanelSectionCard title="Profil">
              <dl className="space-y-3 text-sm">
                <div>
                  <dt className="text-xs font-[700] uppercase tracking-wide text-muted">Rol</dt>
                  <dd className="mt-1">
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-[800] ${roleInfo.className}`}>
                      {roleInfo.label}
                    </span>
                  </dd>
                </div>
                <div>
                  <dt className="text-xs font-[700] uppercase tracking-wide text-muted">E-posta</dt>
                  <dd className="mt-0.5 text-textStrong">{user.email ?? '—'}</dd>
                </div>
                <div>
                  <dt className="text-xs font-[700] uppercase tracking-wide text-muted">Şehir</dt>
                  <dd className="mt-0.5 text-textStrong">{user.city ?? '—'}</dd>
                </div>
                <div>
                  <dt className="text-xs font-[700] uppercase tracking-wide text-muted">Kayıt Tarihi</dt>
                  <dd className="mt-0.5 text-textStrong">
                    {new Date(user.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                  </dd>
                </div>
                {user.bio && (
                  <div>
                    <dt className="text-xs font-[700] uppercase tracking-wide text-muted">Bio</dt>
                    <dd className="mt-0.5 text-textStrong">{user.bio}</dd>
                  </div>
                )}
              </dl>
            </PanelSectionCard>
          </div>

          <div className="flex flex-col gap-5 lg:col-span-2">
            {/* Claims */}
            <PanelSectionCard title={`Sahiplenme Talepleri (${claims.length})`}>
              {claims.length === 0 ? (
                <p className="text-sm text-muted">Talep yok.</p>
              ) : (
                <ul className="divide-y divide-border -mx-4">
                  {claims.map((c: any) => (
                    <li key={c.id} className="flex items-center justify-between px-4 py-2">
                      <span className="text-sm font-[700] text-textStrong">{c.businesses?.name ?? '—'}</span>
                      <div className="flex items-center gap-2">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                          c.status === 'approved' ? 'bg-green-50 text-green-700' :
                          c.status === 'rejected' ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700'
                        }`}>
                          {c.status === 'approved' ? 'Onaylı' : c.status === 'rejected' ? 'Reddedildi' : 'Bekliyor'}
                        </span>
                        <span className="text-xs text-muted">{new Date(c.created_at).toLocaleDateString('tr-TR')}</span>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </PanelSectionCard>

            {/* Reviews */}
            <PanelSectionCard title={`Yorumlar (${reviews.length})`}>
              {reviews.length === 0 ? (
                <p className="text-sm text-muted">Yorum yok.</p>
              ) : (
                <ul className="divide-y divide-border -mx-4">
                  {reviews.map((r: any) => (
                    <li key={r.id} className="px-4 py-2">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-[700] text-textStrong">{r.businesses?.name ?? '—'}</span>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-[800] text-amber-500">{'★'.repeat(r.rating)}{'☆'.repeat(5 - r.rating)}</span>
                          <span className="text-xs text-muted">{new Date(r.created_at).toLocaleDateString('tr-TR')}</span>
                        </div>
                      </div>
                      {r.content && <p className="mt-0.5 line-clamp-2 text-xs text-muted">{r.content}</p>}
                    </li>
                  ))}
                </ul>
              )}
            </PanelSectionCard>

            {/* Submissions */}
            {submissions.length > 0 && (
              <PanelSectionCard title={`İşletme Başvuruları (${submissions.length})`}>
                <ul className="divide-y divide-border -mx-4">
                  {submissions.map((s: any) => (
                    <li key={s.id} className="flex items-center justify-between px-4 py-2">
                      <span className="text-sm font-[700] text-textStrong">{s.name}</span>
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                        s.status === 'approved' ? 'bg-green-50 text-green-700' :
                        s.status === 'rejected' ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700'
                      }`}>
                        {s.status === 'approved' ? 'Onaylı' : s.status === 'rejected' ? 'Reddedildi' : 'Yeni'}
                      </span>
                    </li>
                  ))}
                </ul>
              </PanelSectionCard>
            )}
          </div>
        </div>
      </PanelContentSurface>
    </div>
  );
}
