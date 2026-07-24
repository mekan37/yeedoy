import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const serviceClient = createSupabaseServiceClient();
  const user = serviceClient ? await getAdminUserDetail(serviceClient as any, id) : null;
  return {
    title: user ? `${user.display_name ?? user.email ?? user.id} | Yonetici Paneli` : 'Kullanıcı | Yonetici Paneli',
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
  const serviceClient = createSupabaseServiceClient();

  const user = serviceClient ? await getAdminUserDetail(serviceClient as any, id) : null;

  if (!user) notFound();

  const [claimsRes, reviewsRes, submissionsRes] = await Promise.all([
    (supabase as any)
      .from('owner_claims')
      .select('id, status, created_at, businesses(name)')
      .eq('user_id', id)
      .order('created_at', { ascending: false })
      .limit(10),
    (supabase as any)
      .from('reviews')
      .select('id, rating, content, created_at, businesses(name)')
      .eq('user_id', id)
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
      <PanelSayfaBasligi
        eyebrow="Kullanıcılar"
        title={user.display_name ?? 'Anonim'}
        description={user.email ?? user.id}
        actions={
          <Link href="/yonetici/kullanicilar">
            <PanelActionButton variant="ghost">← Geri</PanelActionButton>
          </Link>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          <div className="flex flex-col gap-5">
            <PanelBolumKarti title="Profil">
              <dl className="space-y-3 text-sm">
                <div>
                  <dt className="text-xs font-bold uppercase tracking-wide text-muted">Rol</dt>
                  <dd className="mt-1">
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-extrabold ${roleInfo.className}`}>
                      {roleInfo.label}
                    </span>
                  </dd>
                </div>
                <div>
                  <dt className="text-xs font-bold uppercase tracking-wide text-muted">E-posta</dt>
                  <dd className="mt-0.5 text-textStrong">{user.email ?? '—'}</dd>
                </div>
                <div>
                  <dt className="text-xs font-bold uppercase tracking-wide text-muted">Şehir</dt>
                  <dd className="mt-0.5 text-textStrong">{user.city ?? '—'}</dd>
                </div>
                <div>
                  <dt className="text-xs font-bold uppercase tracking-wide text-muted">Kayıt Tarihi</dt>
                  <dd className="mt-0.5 text-textStrong">
                    {new Date(user.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                  </dd>
                </div>
                {user.bio && (
                  <div>
                    <dt className="text-xs font-bold uppercase tracking-wide text-muted">Bio</dt>
                    <dd className="mt-0.5 text-textStrong">{user.bio}</dd>
                  </div>
                )}
              </dl>
            </PanelBolumKarti>
          </div>

          <div className="flex flex-col gap-5 lg:col-span-2">
            {/* Claims */}
            <PanelBolumKarti title={`Sahiplenme Talepleri (${claims.length})`}>
              {claims.length === 0 ? (
                <p className="text-sm text-muted">Talep yok.</p>
              ) : (
                <ul className="divide-y divide-border -mx-4">
                  {claims.map((c: any) => (
                    <li key={c.id} className="flex items-center justify-between px-4 py-2">
                      <span className="text-sm font-bold text-textStrong">{c.businesses?.name ?? '—'}</span>
                      <div className="flex items-center gap-2">
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
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
            </PanelBolumKarti>

            {/* Reviews */}
            <PanelBolumKarti title={`Yorumlar (${reviews.length})`}>
              {reviews.length === 0 ? (
                <p className="text-sm text-muted">Yorum yok.</p>
              ) : (
                <ul className="divide-y divide-border -mx-4">
                  {reviews.map((r: any) => (
                    <li key={r.id} className="px-4 py-2">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-bold text-textStrong">{r.businesses?.name ?? '—'}</span>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-extrabold text-amber-500">{'★'.repeat(r.rating)}{'☆'.repeat(5 - r.rating)}</span>
                          <span className="text-xs text-muted">{new Date(r.created_at).toLocaleDateString('tr-TR')}</span>
                        </div>
                      </div>
                      {r.content && <p className="mt-0.5 line-clamp-2 text-xs text-muted">{r.content}</p>}
                    </li>
                  ))}
                </ul>
              )}
            </PanelBolumKarti>

            {/* Submissions */}
            {submissions.length > 0 && (
              <PanelBolumKarti title={`İşletme Başvuruları (${submissions.length})`}>
                <ul className="divide-y divide-border -mx-4">
                  {submissions.map((s: any) => (
                    <li key={s.id} className="flex items-center justify-between px-4 py-2">
                      <span className="text-sm font-bold text-textStrong">{s.name}</span>
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${
                        s.status === 'approved' ? 'bg-green-50 text-green-700' :
                        s.status === 'rejected' ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700'
                      }`}>
                        {s.status === 'approved' ? 'Onaylı' : s.status === 'rejected' ? 'Reddedildi' : 'Yeni'}
                      </span>
                    </li>
                  ))}
                </ul>
              </PanelBolumKarti>
            )}
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

type AdminUserDetail = {
  id: string;
  display_name: string | null;
  email: string | null;
  role: string;
  city: string | null;
  bio: string | null;
  avatar_url: string | null;
  created_at: string;
};

async function getAdminUserDetail(supabase: any, id: string): Promise<AdminUserDetail | null> {
  const { data, error } = await supabase.auth.admin.getUserById(id);
  if (error || !data.user) return null;

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('user_id, display_name, avatar_url, bio, created_at')
    .eq('user_id', id)
    .maybeSingle();

  const user = data.user;
  return {
    id: user.id,
    display_name: profile?.display_name ?? getMetadataText(user, 'display_name') ?? getMetadataText(user, 'name'),
    email: user.email ?? null,
    role: getUserRole(user),
    city: getMetadataText(user, 'city'),
    bio: profile?.bio ?? null,
    avatar_url: profile?.avatar_url ?? null,
    created_at: user.created_at ?? profile?.created_at ?? new Date(0).toISOString(),
  };
}

function getUserRole(user: any) {
  const role = String(user?.app_metadata?.role ?? user?.user_metadata?.role ?? 'user').toLocaleLowerCase('tr-TR');
  return ROLE_MAP[role] ? role : 'user';
}

function getMetadataText(user: any, key: string) {
  const value = user?.user_metadata?.[key] ?? user?.app_metadata?.[key];
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

