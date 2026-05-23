import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';

export const metadata: Metadata = {
  title: 'Gurme Akışı | Yeedoy',
  description: 'Yeedoy gurme topluluğunun son yorum ve katkıları',
  openGraph: { title: 'Gurme Akışı | Yeedoy', description: 'Topluluk gözdesinin son aktiviteleri' },
};

export const revalidate = 120;

type ReviewRow = {
  id: string; rating: number; body: string | null; content: string | null;
  created_at: string; verified_visit?: boolean;
  businesses: { name: string; slug: string } | null;
  user_profiles: { display_name: string | null; avatar_url: string | null } | null;
};

export default async function FeedPage() {
  const supabase = await createSupabaseServerClient();

  let reviews: ReviewRow[] = [];
  try {
    const { data, error } = await (supabase as any)
      .from('business_reviews')
      .select('id, rating, body, content, created_at, verified_visit, businesses!business_id(name, slug), user_profiles!user_id(display_name, avatar_url)')
      .eq('is_visible', true)
      .order('created_at', { ascending: false })
      .limit(30) as { data: ReviewRow[] | null; error: any };
    if (!error || error.code !== '42P01') reviews = data ?? [];
  } catch { reviews = []; }

  function timeAgo(dateStr: string): string {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins} dk önce`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours} sa önce`;
    const days = Math.floor(hours / 24);
    if (days < 7) return `${days} gün önce`;
    return new Date(dateStr).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' });
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 pb-16 pt-10">

        <AppSectionHeader title="Gurme Akışı"
          subtitle="Topluluğun son yorum ve değerlendirmeleri"
          className="mb-8" />

        {reviews.length === 0 ? (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center">
            <p className="font-[900] text-textStrong mb-2">Henüz aktivite yok</p>
            <Link href="/discover" className="text-sm font-[700] text-primary hover:underline">İşletmeleri keşfet →</Link>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {reviews.map((r) => {
              const author = r.user_profiles?.display_name ?? 'Anonim Gurme';
              const biz = r.businesses;
              const text = r.body ?? r.content;
              return (
                <article key={r.id}
                  className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
                  {/* Header */}
                  <div className="mb-3 flex items-start gap-3">
                    {/* Avatar */}
                    <div className="h-10 w-10 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-sm font-[900] text-primary">
                      {r.user_profiles?.avatar_url
                        ? // eslint-disable-next-line @next/next/no-img-element
                          <img loading="lazy" src={r.user_profiles.avatar_url} alt={author} className="h-full w-full object-cover" />
                        : author[0]?.toUpperCase() ?? 'G'}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-[800] text-textStrong">{author}</p>
                      {biz && (
                        <Link href={`/b/${biz.slug}`}
                          className="text-xs text-muted transition-colors hover:text-primary">
                          {biz.name}
                        </Link>
                      )}
                    </div>
                    <div className="flex shrink-0 flex-col items-end gap-1">
                      {/* Stars */}
                      <div className="flex items-center gap-0.5">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <svg key={i} width="11" height="11" viewBox="0 0 24 24"
                            fill={i < r.rating ? '#f59e0b' : 'none'}
                            stroke={i < r.rating ? '#f59e0b' : '#d1d5db'}
                            strokeWidth="2" aria-hidden="true">
                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                          </svg>
                        ))}
                      </div>
                      <span className="text-[10px] text-muted">{timeAgo(r.created_at)}</span>
                    </div>
                  </div>

                  {/* Badges */}
                  {r.verified_visit && (
                    <div className="mb-2">
                      <span className="inline-flex items-center gap-1 rounded-full border border-success/25 bg-success/[0.12] px-2 py-0.5 text-[10px] font-[800] text-success">
                        <svg viewBox="0 0 24 24" className="h-2.5 w-2.5 fill-current" aria-hidden="true"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
                        Doğrulanmış Ziyaret
                      </span>
                    </div>
                  )}

                  {/* Content */}
                  {text && (
                    <p className="line-clamp-3 text-sm leading-relaxed text-textStrong">
                      &ldquo;{text}&rdquo;
                    </p>
                  )}

                  {/* Business link */}
                  {biz && (
                    <div className="mt-3 border-t border-border pt-3">
                      <Link href={`/b/${biz.slug}`}
                        className="inline-flex items-center gap-1 text-xs font-[700] text-primary hover:underline">
                        {biz.name} sayfasına git →
                      </Link>
                    </div>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
