import Link from 'next/link';

interface FeaturedCardProps {
  name: string;
  slug: string;
  category?: string | null;
  city?: string | null;
  avgRating?: number | null;
  reviewsCount?: number | null;
  rank?: number;
  logoUrl?: string | null;
}

/** Horizontal-scroll featured business card — yatay strip için, Figma Faz-1 */
export function FeaturedCard({
  name, slug, category, city, avgRating, reviewsCount, rank, logoUrl,
}: FeaturedCardProps) {
  return (
    <Link
      href={`/b/${slug}`}
      className="group flex w-52 shrink-0 flex-col gap-3 rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1
                 transition-all duration-180 hover:-translate-y-1 hover:border-primary/25 hover:shadow-yd3
                 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
    >
      {/* Rank + logo row */}
      <div className="flex items-start justify-between">
        {rank != null && (
          <span className="text-[11px] font-black text-primary">#{rank}</span>
        )}
        <div
          className={`h-12 w-12 shrink-0 overflow-hidden rounded-xl border border-border bg-bg ${rank == null ? '' : 'ml-auto'}`}
        >
          {logoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={logoUrl} alt={name} className="h-full w-full object-cover" loading="lazy" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-base font-black text-primary/60">
              {name[0]}
            </div>
          )}
        </div>
      </div>

      {/* Name + meta */}
      <div className="min-w-0 flex-1">
        <p className="line-clamp-2 font-black leading-tight text-textStrong transition-colors group-hover:text-primary">
          {name}
        </p>
        {(category || city) && (
          <p className="mt-0.5 text-xs text-muted">
            {[category, city].filter(Boolean).join(' · ')}
          </p>
        )}
      </div>

      {/* Rating row */}
      {avgRating != null && (
        <div className="flex items-center justify-between">
          <span className="flex items-center gap-1 text-xs font-extrabold text-amber-500">
            <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true">
              <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
            </svg>
            {avgRating.toFixed(1)}
          </span>
          {reviewsCount != null && (
            <span className="text-[10px] text-muted">{reviewsCount} yorum</span>
          )}
        </div>
      )}
    </Link>
  );
}
