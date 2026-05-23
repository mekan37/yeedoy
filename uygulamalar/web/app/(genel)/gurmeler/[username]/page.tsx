import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

type Props = { params: Promise<{ username: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { username } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any)
    .from('user_profiles')
    .select('display_name')
    .eq('username', username)
    .single() as { data: { display_name: string | null } | null };

  const name = data?.display_name ?? username;
  return {
    title: `${name} | Yeedoy Gurme`,
    description: `${name} adlı gurmenin Yeedoy profili`,
  };
}

export const revalidate = 300;

export default async function GourmetProfilePage({ params }: Props) {
  const { username } = await params;
  const supabase = await createSupabaseServerClient();

  type Profile = {
    id: string;
    display_name: string | null;
    avatar_url: string | null;
    bio: string | null;
    city: string | null;
    created_at: string;
  };

  const { data: profile } = await (supabase as any)
    .from('user_profiles')
    .select('id, display_name, avatar_url, bio, city, created_at')
    .eq('username', username)
    .single() as { data: Profile | null };

  if (!profile) notFound();

  const name = profile.display_name ?? username;

  type ReviewRow = {
    id: string;
    rating: number;
    body: string | null;
    created_at: string;
    businesses: { name: string; slug: string } | null;
  };

  const [reviewsRes, statsRes] = await Promise.all([
    (supabase as any)
      .from('business_reviews')
      .select('id, rating, body, created_at, businesses!business_id(name, slug)')
      .eq('user_id', profile.id)
      .order('created_at', { ascending: false })
      .limit(20) as Promise<{ data: ReviewRow[] | null }>,
    (supabase as any)
      .from('business_reviews')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', profile.id) as Promise<{ count: number | null }>,
  ]);

  const reviews = reviewsRes.data ?? [];
  const reviewCount = statsRes.count ?? 0;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/akis" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">
          ← Gurme Akışı
        </Link>

        {/* Profile header */}
        <div className="flex items-center gap-5 mb-8">
          <div className="h-20 w-20 shrink-0 overflow-hidden rounded-full border-2 border-border bg-primary/10 flex items-center justify-center text-2xl font-[900] text-primary">
            {profile.avatar_url
              ? <Image src={profile.avatar_url} alt={name} width={80} height={80} className="h-full w-full object-cover" />
              : name[0]?.toUpperCase() ?? 'G'}
          </div>
          <div>
            <h1 className="text-2xl font-[900] text-textStrong">{name}</h1>
            {profile.city && <p className="text-sm text-muted mt-0.5">{profile.city}</p>}
            {profile.bio && <p className="text-sm text-muted mt-1 leading-relaxed max-w-md">{profile.bio}</p>}
            <div className="flex items-center gap-4 mt-3">
              <span className="text-sm">
                <span className="font-[800] text-textStrong">{reviewCount.toLocaleString('tr-TR')}</span>
                <span className="text-muted ml-1">yorum</span>
              </span>
            </div>
          </div>
        </div>

        {/* Reviews */}
        <div>
          <h2 className="text-lg font-[900] text-textStrong mb-4">Yorumlar</h2>
          {reviews.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-8 text-center">
              <p className="text-muted">Henüz yorum yapılmamış.</p>
            </div>
          ) : (
            <div className="flex flex-col gap-4">
              {reviews.map((r) => {
                const biz = r.businesses;
                return (
                  <article key={r.id} className="rounded-2xl border border-border bg-card p-5">
                    <div className="flex items-start justify-between gap-2 mb-2">
                      {biz ? (
                        <Link href={`/isletme/${biz.slug}`} className="font-[800] text-textStrong hover:text-primary transition-colors cursor-pointer">
                          {biz.name}
                        </Link>
                      ) : (
                        <span className="font-[800] text-textStrong">—</span>
                      )}
                      <div className="flex items-center gap-0.5 shrink-0">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <svg key={i} width="12" height="12" viewBox="0 0 24 24" fill={i < r.rating ? '#dc2626' : 'none'} stroke={i < r.rating ? '#dc2626' : '#d1d5db'} strokeWidth="2">
                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                          </svg>
                        ))}
                      </div>
                    </div>
                    {r.body && (
                      <p className="text-sm text-textStrong leading-relaxed mb-2">&ldquo;{r.body}&rdquo;</p>
                    )}
                    <p className="text-[11px] text-muted">
                      {new Date(r.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                    </p>
                  </article>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </main>
  );
}


