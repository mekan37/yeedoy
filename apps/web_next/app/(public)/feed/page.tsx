import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = {
  title: 'Gurme Akışı | Yeedoy',
  description: 'Yeedoy gurme topluluğunun son yorum ve katkıları',
  openGraph: {
    title: 'Gurme Akışı | Yeedoy',
    description: 'Topluluk gözdesinin son aktiviteleri',
  },
};

export const revalidate = 120;

export default async function FeedPage() {
  const supabase = await createSupabaseServerClient();

  type ReviewRow = {
    id: string;
    rating: number;
    body: string | null;
    created_at: string;
    businesses: { name: string; slug: string } | null;
    user_profiles: { display_name: string | null; avatar_url: string | null } | null;
  };

  let reviews: ReviewRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('business_reviews')
      .select('id, rating, body, created_at, businesses!business_id(name, slug), user_profiles!user_id(display_name, avatar_url)')
      .order('created_at', { ascending: false })
      .limit(40) as { data: ReviewRow[] | null; error: any };
    if (!error || error.code !== '42P01') reviews = data ?? [];
  } catch { reviews = []; }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="mb-8">
          <p className="text-xs font-[800] uppercase tracking-widest text-primary mb-2">Topluluk</p>
          <h1 className="font-display text-3xl font-[900] text-textStrong mb-2">Gurme Akışı</h1>
          <p className="text-muted">Topluluğun son yorum ve değerlendirmeleri</p>
        </div>

        {reviews.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="font-[700] text-textStrong mb-2">Henüz aktivite yok</p>
            <Link href="/discover" className="text-sm text-primary hover:underline cursor-pointer">
              İşletmeleri keşfet →
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {reviews.map((r) => {
              const author = r.user_profiles?.display_name ?? 'Anonim Gurme';
              const biz = r.businesses;
              return (
                <article key={r.id} className="rounded-2xl border border-border bg-card p-5">
                  <div className="flex items-start gap-3 mb-3">
                    <div className="h-9 w-9 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-sm font-[900] text-primary">
                      {r.user_profiles?.avatar_url
                        ? <img loading="lazy" src={r.user_profiles.avatar_url} alt={author} className="h-full w-full object-cover" />
                        : author[0]?.toUpperCase() ?? 'G'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-[800] text-textStrong text-sm">{author}</p>
                      {biz && (
                        <Link
                          href={`/b/${biz.slug}`}
                          className="text-xs text-muted hover:text-primary transition-colors cursor-pointer"
                        >
                          {biz.name}
                        </Link>
                      )}
                    </div>
                    <div className="flex items-center gap-0.5 shrink-0">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <svg
                          key={i}
                          width="12"
                          height="12"
                          viewBox="0 0 24 24"
                          fill={i < r.rating ? '#dc2626' : 'none'}
                          stroke={i < r.rating ? '#dc2626' : '#d1d5db'}
                          strokeWidth="2"
                        >
                          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                        </svg>
                      ))}
                    </div>
                  </div>

                  {r.body && (
                    <p className="text-sm text-textStrong leading-relaxed mb-2 line-clamp-3">
                      &ldquo;{r.body}&rdquo;
                    </p>
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
    </main>
  );
}
