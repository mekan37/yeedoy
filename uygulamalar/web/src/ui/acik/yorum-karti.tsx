import Link from 'next/link';

export type YorumSatiri = {
  id: string;
  content: string | null;
  title: string | null;
  rating: number | null;
  overall_rating: number | null;
  created_at: string;
  businesses: { name: string; category: string | null; district: string | null; slug: string | null } | null;
};

export function formatZaman(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const gun = Math.floor(diff / 86_400_000);
  if (gun === 0) return 'Bugün';
  if (gun === 1) return 'Dün';
  if (gun < 7) return `${gun} gün önce`;
  if (gun < 30) return `${Math.floor(gun / 7)} hafta önce`;
  if (gun < 365) return `${Math.floor(gun / 30)} ay önce`;
  return `${Math.floor(gun / 365)} yıl önce`;
}

// Profildeki "Son Yorumlarım" önizlemesi ve /yorumlarim'deki tam liste
// tarafından paylaşılan tek yorum kartı — iki yerde de aynı görünüm.
export function YorumKarti({ y }: { y: YorumSatiri }) {
  const b = y.businesses;
  const bizHref = b?.slug ? `/isletme/${b.slug}` : '/kesif';
  const rating = y.rating ?? 0;
  const ratingColor = rating >= 4
    ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
    : rating === 3
    ? 'bg-amber-50 text-amber-700 border-amber-200'
    : rating > 0
    ? 'bg-red-50 text-red-600 border-red-200'
    : 'bg-cardAlt text-muted border-border';

  return (
    <div className="rounded-2xl border border-border bg-cardAlt overflow-hidden transition hover:border-primary/20 hover:shadow-yd1">
      {/* Header */}
      <div className="flex items-center gap-3 px-4 py-3 bg-card border-b border-border/60">
        {/* Rating badge */}
        <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border text-base font-black ${ratingColor}`}>
          {rating > 0 ? rating : '—'}
        </div>
        {/* Stars + date */}
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-0.5">
            {Array.from({ length: 5 }, (_, i) => (
              <svg key={i} width="13" height="13" viewBox="0 0 24 24"
                fill={i < rating ? '#f59e0b' : '#e2e8f0'} aria-hidden="true">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
              </svg>
            ))}
            <span className="ml-1.5 text-[11px] font-bold text-muted">{formatZaman(y.created_at)}</span>
          </div>
        </div>
        {/* Business link */}
        <Link href={bizHref} className="shrink-0 text-right group max-w-[130px]">
          <p className="text-[12px] font-black text-textStrong group-hover:text-primary transition-colors leading-tight line-clamp-1">{b?.name ?? 'İşletme'}</p>
          {(b?.category || b?.district) && (
            <p className="text-[10px] font-bold text-muted leading-tight line-clamp-1">{[b?.category, b?.district].filter(Boolean).join(' · ')}</p>
          )}
        </Link>
      </div>
      {/* Review body */}
      {(y.title || y.content) && (
        <div className="flex gap-3 px-4 py-3">
          <div className="w-0.5 shrink-0 rounded-full bg-primary/30 self-stretch" />
          <div className="min-w-0 space-y-0.5">
            {y.title && (
              <p className="text-[13px] font-black text-textStrong leading-snug">{y.title}</p>
            )}
            {y.content && (
              <p className="text-[12px] font-bold leading-relaxed text-text line-clamp-2">{y.content}</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
