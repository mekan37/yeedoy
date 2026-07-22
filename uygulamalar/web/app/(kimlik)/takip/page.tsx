import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { Star } from 'lucide-react';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { TakipteCikButonu } from './takipten-cik';

export const metadata: Metadata = { title: 'Takip Ettiklerim | Yeedoy', robots: { index: false, follow: false } };

type FollowRow = {
  followed_id: string;
  created_at: string;
  user_profiles: { display_name: string | null; avatar_url: string | null; bio: string | null } | null;
  recent_review: { business_name: string; rating: number } | null;
};

export default async function FollowingPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let list: FollowRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('user_follows')
      .select('followed_id, created_at, user_profiles!followed_id(display_name, avatar_url, bio)')
      .eq('follower_id', user!.id)
      .order('created_at', { ascending: false }) as { data: Omit<FollowRow, 'recent_review'>[] | null; error: any };
    if (!error || error.code !== '42P01') {
      list = (data ?? []).map((r) => ({ ...r, recent_review: null }));
    }
  } catch { list = []; }

  // Enrich with latest review per followed user
  if (list.length > 0) {
    try {
      const uids = list.map((f) => f.followed_id);
      const { data: reviews } = await (supabase as any)
        .from('business_reviews')
        .select('user_id, rating, businesses(name)')
        .in('user_id', uids)
        .eq('is_visible', true)
        .order('created_at', { ascending: false })
        .limit(list.length * 2) as { data: Array<{ user_id: string; rating: number; businesses: { name: string } | null }> | null };

      const latestByUser = new Map<string, { business_name: string; rating: number }>();
      for (const r of (reviews ?? [])) {
        if (!latestByUser.has(r.user_id)) {
          latestByUser.set(r.user_id, { business_name: r.businesses?.name ?? '?', rating: r.rating });
        }
      }
      list = list.map((f) => ({ ...f, recent_review: latestByUser.get(f.followed_id) ?? null }));
    } catch { /* ignore */ }
  }

  function joinedDate(iso: string) {
    return new Date(iso).toLocaleDateString('tr-TR', { month: 'short', year: 'numeric' });
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">← Profilime Dön</Link>
        <div className="mb-6 flex items-center gap-3">
          <h1 className="text-2xl font-[900] text-textStrong">Takip Ettiklerim</h1>
          {list.length > 0 && (
            <span className="rounded-full bg-border px-2 py-0.5 text-[11px] font-[700] text-muted">{list.length}</span>
          )}
        </div>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-3xl mb-3">🧑‍🍳</p>
            <p className="font-[700] text-textStrong mb-2">Henüz kimseyi takip etmiyorsunuz</p>
            <p className="text-sm text-muted mb-6">İşletmeleri keşfet ve favori mekanlarını takip et.</p>
            <Link href="/kesif" className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white" style={{ background: 'var(--yd-gradient-primary)' }}>
              İşletmeleri Keşfet
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map((f) => {
              const name = f.user_profiles?.display_name ?? 'Anonim Gurme';
              return (
                <div key={f.followed_id} className="rounded-2xl border border-border bg-card p-4">
                  <div className="flex items-start gap-4">
                    {/* Avatar */}
                    <div className="h-11 w-11 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-base font-[900] text-primary">
                      {f.user_profiles?.avatar_url
                        ? <Image src={f.user_profiles.avatar_url} alt={name} width={44} height={44} className="h-full w-full object-cover" />
                        : name[0].toUpperCase()}
                    </div>

                    {/* Info */}
                    <div className="min-w-0 flex-1">
                      <p className="font-[900] text-textStrong">{name}</p>
                      {f.user_profiles?.bio && (
                        <p className="mt-0.5 line-clamp-1 text-[12px] text-muted">{f.user_profiles.bio}</p>
                      )}
                      {f.recent_review && (
                        <p className="mt-1 flex items-center gap-1 text-[11px] text-muted">
                          Son: <Star className="h-3 w-3 shrink-0" aria-hidden="true" />{f.recent_review.rating} — {f.recent_review.business_name}
                        </p>
                      )}
                      <p className="mt-0.5 text-[11px] text-muted">Takip: {joinedDate(f.created_at)}</p>
                    </div>

                    {/* Unfollow */}
                    <div className="shrink-0">
                      <TakipteCikButonu followedId={f.followed_id} />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
