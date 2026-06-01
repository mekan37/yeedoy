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
              {/* Loop 5 MVP: Gurme profil paylaşım */}
              <a
                href={`whatsapp://send?text=${encodeURIComponent(`Yeedoy gurme katkıcısı ${name} — ${reviewCount} yorum! 🍽️ Profil: yeedoy.com/gurmeler/${username}`)}`}
                className="flex items-center gap-1 rounded-lg border border-border bg-card px-2.5 py-1 text-[11px] font-[700] text-muted hover:bg-border/40 transition-colors"
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413z"/>
                  <path d="M12 0C5.373 0 0 5.373 0 12c0 2.122.552 4.112 1.512 5.84L0 24l6.336-1.494A11.928 11.928 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 21.818a9.797 9.797 0 0 1-5.028-1.384l-.36-.214-3.732.879.894-3.63-.235-.373A9.796 9.796 0 0 1 2.182 12C2.182 6.573 6.573 2.182 12 2.182S21.818 6.573 21.818 12 17.427 21.818 12 21.818z"/>
                </svg>
                Paylaş
              </a>
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


