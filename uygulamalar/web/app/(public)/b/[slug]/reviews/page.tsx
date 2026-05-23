import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';

export const revalidate = 120;

type SortOption = 'newest' | 'top' | 'verified';

type Props = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ sort?: string; page?: string }>;
};

const PAGE_SIZE = 20;

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any)
    .from('businesses')
    .select('name')
    .eq('slug', slug)
    .single() as { data: { name: string } | null };
  return {
    title: data ? `${data.name} Yorumları | Yeedoy` : 'Yorumlar | Yeedoy',
  };
}

type Review = {
  id: string;
  rating: number;
  title: string | null;
  content: string | null;
  helpful_count: number;
  created_at: string;
  quality_score: number | null;
  verified_visit: boolean | null;
  r_taste: number | null;
  r_service: number | null;
  r_price_value: number | null;
  r_atmosphere: number | null;
};

export default async function BusinessReviewsPage({ params, searchParams }: Props) {
  const { slug } = await params;
  const sp = await searchParams;

  const sort: SortOption = ['newest', 'top', 'verified'].includes(sp.sort ?? '')
    ? (sp.sort as SortOption)
    : 'newest';
  const pageNum = Math.max(1, parseInt(sp.page ?? '1', 10));
  const offset = (pageNum - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  type Biz = { id: string; name: string; slug: string };
  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug')
    .eq('slug', slug)
    .single() as { data: Biz | null };
  if (!biz) notFound();

  const { data: reviews, count } = await (supabase as any).rpc(
    'get_business_reviews_v3',
    { p_business_id: biz.id, p_sort: sort, p_limit: PAGE_SIZE, p_offset: offset },
    { count: 'exact' },
  ) as { data: Review[] | null; count: number | null };

  const list = reviews ?? [];
  const total = count ?? 0;
  const totalPages = Math.ceil(total / PAGE_SIZE);

  function sortHref(s: SortOption) {
    const params = new URLSearchParams();
    if (s !== 'newest') params.set('sort', s);
    const qs = params.toString();
    return `/b/${slug}/reviews${qs ? `?${qs}` : ''}`;
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-10">
        {/* Back link */}
        <Link
          href={`/m/${biz.slug}`}
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary"
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/>
          </svg>
          {biz.name} Menüsüne Dön
        </Link>

        {/* Header */}
        <AppSectionHeader
          title={`${biz.name} — Yorumlar`}
          subtitle={total > 0 ? `${total.toLocaleString('tr-TR')} yorum` : undefined}
          className="mb-6"
        />

        {/* Sort buttons */}
        <div className="mb-6 flex flex-wrap gap-2">
          {([ ['newest', 'En Yeni'], ['top', 'En İyi'], ['verified', 'Doğrulanmış'] ] as [SortOption, string][]).map(([s, label]) => (
            <Link
              key={s}
              href={sortHref(s)}
              className={[
                'inline-flex min-h-[44px] items-center rounded-full border px-3 py-1 text-sm font-[800] transition-all duration-[150ms]',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
                sort === s
                  ? 'bg-[var(--yd-color-primary-soft)] border-primary/40 text-primary'
                  : 'bg-cardAlt border-border text-textStrong hover:border-borderStrong hover:bg-card',
              ].join(' ')}
            >
              {label}
            </Link>
          ))}
        </div>

        {/* Review list */}
        {list.length === 0 ? (
          <p className="py-16 text-center text-sm text-muted">
            {sort === 'verified' ? 'Doğrulanmış ziyaretli yorum bulunmuyor.' : 'Henüz yorum yapılmamış.'}
          </p>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map((r) => (
              <ReviewCard key={r.id} review={r} />
            ))}
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="mt-8 flex items-center justify-between">
            {pageNum > 1 ? (
              <Link
                href={`?${sort !== 'newest' ? `sort=${sort}&` : ''}page=${pageNum - 1}`}
                className="inline-flex min-h-[44px] items-center rounded-2xl border border-border bg-card px-4 text-sm font-[700] text-textStrong transition-colors hover:border-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              >
                ← Önceki
              </Link>
            ) : <div />}
            <span className="text-sm text-muted">{pageNum} / {totalPages}</span>
            {pageNum < totalPages && (
              <Link
                href={`?${sort !== 'newest' ? `sort=${sort}&` : ''}page=${pageNum + 1}`}
                className="inline-flex min-h-[44px] items-center rounded-2xl border border-border bg-card px-4 text-sm font-[700] text-textStrong transition-colors hover:border-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              >
                Sonraki →
              </Link>
            )}
          </div>
        )}
      </div>
    </main>
  );
}

function ReviewCard({ review: r }: { review: Review }) {
  const hasQualityBadge = (r.quality_score ?? 0) >= 75;
  return (
    <article className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
      {/* Header row */}
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <StarRow rating={r.rating} />
        {r.verified_visit && (
          <span className="inline-flex items-center gap-1 rounded-full border border-success/25 bg-success/[0.12] px-2 py-0.5 text-[11px] font-[800] text-success">
            <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true">
              <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
            </svg>
            Doğrulanmış Ziyaret
          </span>
        )}
        {hasQualityBadge && (
          <span className="rounded-full border border-info/25 bg-info/[0.12] px-2 py-0.5 text-[11px] font-[800] text-info">
            Kaliteli Yorum
          </span>
        )}
        <span className="ml-auto text-[11px] text-muted">
          {new Date(r.created_at).toLocaleDateString('tr-TR')}
        </span>
      </div>

      {/* Title */}
      {r.title && <p className="mb-1 text-sm font-[700] text-textStrong">{r.title}</p>}

      {/* Content */}
      {r.content && (
        <p className="text-sm leading-relaxed text-textStrong">{r.content}</p>
      )}

      {/* Sub-ratings */}
      {(r.r_taste || r.r_service || r.r_price_value || r.r_atmosphere) && (
        <div className="mt-3 flex flex-wrap gap-2">
          {r.r_taste != null && <SubRating label="Lezzet" value={r.r_taste} />}
          {r.r_service != null && <SubRating label="Servis" value={r.r_service} />}
          {r.r_price_value != null && <SubRating label="Fiyat/Değer" value={r.r_price_value} />}
          {r.r_atmosphere != null && <SubRating label="Atmosfer" value={r.r_atmosphere} />}
        </div>
      )}

      {/* Helpful count */}
      {r.helpful_count > 0 && (
        <p className="mt-2 text-[11px] text-muted">{r.helpful_count} kişi faydalı buldu</p>
      )}
    </article>
  );
}

function StarRow({ rating }: { rating: number }) {
  return (
    <span className="text-sm font-[700] text-star" aria-label={`${rating} yıldız`}>
      {'★'.repeat(rating)}{'☆'.repeat(Math.max(0, 5 - rating))}
    </span>
  );
}

function SubRating({ label, value }: { label: string; value: number }) {
  return (
    <span className="rounded-full border border-border bg-card px-2 py-0.5 text-[11px] font-[700] text-muted">
      {label}: {'★'.repeat(value)}
    </span>
  );
}
