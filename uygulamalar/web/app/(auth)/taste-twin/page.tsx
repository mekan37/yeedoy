import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = {
  title: 'Taste Twin | Yeedoy',
  robots: { index: false, follow: false },
};

// RPC return shapes
type HybridMatchRow = {
  user_id: string;
  similarity: number;
  overlap: number;
  review_similarity: number;
  signal_similarity: number;
};

type PublicProfileRow = {
  user_id: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  is_gourmet: boolean;
};

type RecommendationRow = {
  business_id: string;
  business_name: string;
  city: string | null;
  district: string | null;
  match_rating: number;
  match_review_title: string | null;
  match_review_excerpt: string | null;
  match_review_created_at: string;
};

type MatchWithProfile = HybridMatchRow & {
  profile: PublicProfileRow | null;
};

const initials = (name: string | null) => (name ?? 'G')[0].toUpperCase();

const matchLabel = (sim: number): string => {
  if (sim >= 0.8) return 'Harika Uyum';
  if (sim >= 0.6) return 'Yüksek Uyum';
  if (sim >= 0.4) return 'Orta Uyum';
  return 'Düşük Uyum';
};

export default async function TasteTwinPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login?redirect=/taste-twin');

  let matches: MatchWithProfile[] = [];
  let topRecommendations: RecommendationRow[] = [];
  let myReviewCount = 0;

  try {
    // Fetch hybrid matches (uses auth.uid() internally — safe, SECURITY DEFINER)
    const { data: rawMatches } = await (supabase as any).rpc(
      'get_taste_matches_hybrid_v1',
      { p_limit: 12, p_min_overlap: 3 },
    ) as { data: HybridMatchRow[] | null };

    if (rawMatches && rawMatches.length > 0) {
      // Enrich with public profiles (parallel fetches, max 12)
      const enriched = await Promise.all(
        rawMatches.map(async (m) => {
          try {
            const { data: prof } = await (supabase as any).rpc(
              'get_user_public_profile_v1',
              { p_user_id: m.user_id },
            ) as { data: PublicProfileRow | null };
            return { ...m, profile: prof ?? null } satisfies MatchWithProfile;
          } catch {
            return { ...m, profile: null } satisfies MatchWithProfile;
          }
        }),
      );
      matches = enriched;

      // Fetch recommendations from the top match
      const topMatch = enriched[0];
      if (topMatch) {
        try {
          const { data: recs } = await (supabase as any).rpc(
            'taste_recommendations_from_match_v2',
            { p_match_user_id: topMatch.user_id, p_limit: 5 },
          ) as { data: RecommendationRow[] | null };
          topRecommendations = recs ?? [];
        } catch {
          // recommendations are bonus — ignore failure
        }
      }
    }

    // My own review count (for empty state messaging)
    const { count } = await (supabase as any)
      .from('reviews')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', user!.id)
      .eq('status', 'approved') as { count: number | null };
    myReviewCount = count ?? 0;
  } catch {
    // Render empty state on any unexpected error
  }

  const hasEnoughData = myReviewCount >= 3;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link
          href="/profile"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary"
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" />
          </svg>
          Profile Dön
        </Link>

        <h1 className="mb-1 text-2xl font-[900] text-textStrong">Taste Twin</h1>
        <p className="mb-4 text-sm leading-relaxed text-muted">
          Benzer damak zevkine sahip gurmeleri keşfedin ve onların favori mekanlarını görün.
        </p>

        <div className="mb-8 flex flex-wrap gap-2 text-[11px]">
          {[
            { label: 'Yorum bazlı kosinüs benzerliği' },
            { label: 'Sinyal ağırlıklı hibrit skoru' },
            { label: 'Min. 3 ortak mekan' },
          ].map(({ label }) => (
            <span
              key={label}
              className="inline-flex items-center gap-1.5 rounded-full border border-border bg-cardAlt px-3 py-1 font-[700] text-textStrong"
            >
              {label}
            </span>
          ))}
        </div>

        {matches.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="mb-3 text-3xl">🍽️</p>
            <p className="mb-2 font-[700] text-textStrong">Henüz yeterli veri yok</p>
            <p className="mb-6 text-sm text-muted">
              {hasEnoughData
                ? 'Yeterli ortak mekan bulunan başka kullanıcı henüz yok. Daha fazla değerlendirme geldikçe eşleşmeler oluşacak.'
                : `Şu an ${myReviewCount} onaylı değerlendirmeniz var. En az 3 değerlendirme yapıldığında eşleşme arayışı başlar.`}
            </p>
            <Link
              href="/discover"
              className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white transition-all duration-[180ms] hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}
            >
              İşletme Keşfet
            </Link>
          </div>
        ) : (
          <>
            {/* Match list */}
            <section aria-label="Damak Twinleri" className="mb-10 flex flex-col gap-3">
              {matches.map((m, idx) => {
                const name = m.profile?.display_name ?? 'Anonim Gurme';
                const pct = Math.round(Math.max(0, Math.min(1, m.similarity)) * 100);
                return (
                  <div
                    key={m.user_id}
                    className="flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4"
                  >
                    {/* Rank */}
                    <div className="w-5 shrink-0 text-center text-xs font-[900] text-muted">
                      {idx + 1}
                    </div>

                    {/* Avatar — plain <img> to support external OAuth avatar hosts */}
                    <div className="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-full border border-border bg-primary/10 text-base font-[900] text-primary">
                      {m.profile?.avatar_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={m.profile.avatar_url}
                          alt={name}
                          width={44}
                          height={44}
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        initials(m.profile?.display_name ?? null)
                      )}
                    </div>

                    {/* Info */}
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-[900] text-textStrong">{name}</p>
                      <div className="mt-1.5 flex items-center gap-2">
                        <div className="h-1.5 w-24 overflow-hidden rounded-full bg-border">
                          <div
                            className="h-full rounded-full bg-primary transition-all"
                            style={{ width: `${Math.max(10, pct)}%` }}
                          />
                        </div>
                        <span className="text-[11px] font-[700] text-muted">
                          {m.overlap} ortak mekan · {matchLabel(m.similarity)}
                        </span>
                      </div>
                    </div>

                    {/* Score badge */}
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--yd-color-primary-soft)] text-sm font-[900] text-primary">
                      %{pct}
                    </div>
                  </div>
                );
              })}
            </section>

            {/* Top match recommendations */}
            {topRecommendations.length > 0 && (
              <section aria-label="Damak Twininden Öneriler">
                <h2 className="mb-4 text-base font-[900] text-textStrong">
                  En Yakın Twinin Sevdikleri
                </h2>
                <div className="flex flex-col gap-3">
                  {topRecommendations.map((rec) => (
                    <Link
                      key={rec.business_id}
                      href={`/b/${rec.business_id}`}
                      className="block rounded-2xl border border-border bg-card px-5 py-4 transition-shadow hover:shadow-yd2"
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0 flex-1">
                          <p className="truncate font-[900] text-textStrong">{rec.business_name}</p>
                          {(rec.city || rec.district) && (
                            <p className="mt-0.5 text-[11px] text-muted">
                              {[rec.district, rec.city].filter(Boolean).join(', ')}
                            </p>
                          )}
                          {rec.match_review_excerpt && (
                            <p className="mt-2 line-clamp-2 text-xs text-muted">
                              &ldquo;{rec.match_review_excerpt}&rdquo;
                            </p>
                          )}
                        </div>
                        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[var(--yd-color-primary-soft)] text-xs font-[900] text-primary">
                          {rec.match_rating}★
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </section>
            )}
          </>
        )}
      </div>
    </main>
  );
}
