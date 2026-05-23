import Link from 'next/link';
import { clsx } from 'clsx';
import { type ReactNode } from 'react';

interface BusinessTileProps {
  name: string;
  category?: string | null;
  subtitle?: string | null;
  slug: string;
  badgeText?: string | null;
  isVerified?: boolean;
  qualityScore?: number | null;
  distanceKm?: number | null;
  socialProof?: string[];
  trailingAction?: ReactNode;
  className?: string;
}

function fmtKm(km: number) {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km < 10 ? km.toFixed(1) : Math.round(km)} km`;
}

/** Equivalent of Flutter BusinessTile — horizontal card matching mobile layout. */
export function BusinessTile({
  name,
  category,
  subtitle,
  slug,
  badgeText,
  isVerified,
  qualityScore,
  distanceKm,
  socialProof,
  trailingAction,
  className = '',
}: BusinessTileProps) {
  return (
    <Link
      href={`/m/${slug}`}
      className={clsx(
        'group flex items-center gap-3 rounded-[20px] border border-border bg-cardAlt p-3 shadow-yd2',
        'cursor-pointer transition-all duration-[180ms] hover:-translate-y-0.5 hover:shadow-yd3 active:scale-[0.97] active:shadow-yd1',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        className,
      )}
    >
      {/* Category icon area — matches Flutter 64×64 gradient container */}
      <div
        className="flex h-16 w-16 shrink-0 items-center justify-center rounded-[18px] text-white"
        style={{ background: 'linear-gradient(135deg, #5C1515 0%, #7F1D1D 100%)' }}
        aria-hidden="true"
      >
        <PlaceIcon />
      </div>

      {/* Content */}
      <div className="flex min-w-0 flex-1 flex-col gap-1.5">
        {/* Name row + pills */}
        <div className="flex flex-wrap items-center gap-2">
          <span className="min-w-0 flex-1 truncate font-[900] text-textStrong group-hover:text-primary transition-colors">
            {name}
          </span>

          {badgeText && badgeText.trim() && (
            <span className="shrink-0 rounded-full border border-primary/25 bg-[var(--yd-color-primary-soft)] px-2 py-1 text-xs font-[900] text-primary">
              {badgeText}
            </span>
          )}

          {distanceKm != null && (
            <span className="shrink-0 rounded-full border border-border bg-cardAlt px-2.5 py-1 text-xs font-[900] text-textStrong">
              {fmtKm(distanceKm)}
            </span>
          )}

          {qualityScore != null && qualityScore >= 3 && (
            <span className="inline-flex shrink-0 items-center gap-1 rounded-full border border-success/25 bg-success/[0.12] px-2 py-1 text-xs font-[900] text-success">
              <VerifiedIcon />
              Kaliteli
            </span>
          )}

          {isVerified && qualityScore == null && (
            <span className="shrink-0 rounded-full border border-success/25 bg-success/[0.12] px-2 py-1 text-xs font-[900] text-success">
              Onaylı
            </span>
          )}
        </div>

        {/* Subtitle */}
        {subtitle && (
          <p className="truncate text-xs text-muted">{subtitle}</p>
        )}

        {/* Category chip */}
        {category && (
          <div className="flex flex-wrap gap-1.5">
            <span className="rounded-full bg-[var(--yd-color-primary-soft)] px-2 py-0.5 text-xs font-[800] text-primary">
              {category}
            </span>
          </div>
        )}

        {/* Social proof */}
        {socialProof && socialProof.length > 0 && (
          <div className="flex flex-wrap gap-1.5">
            {socialProof.map((label) => (
              <span
                key={label}
                className="rounded-full border border-info/30 bg-info/[0.12] px-2 py-0.5 text-[11px] font-[800] text-info"
              >
                {label}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Trailing action or chevron */}
      {trailingAction ?? (
        <ChevronIcon className="ml-1 shrink-0 text-muted transition-transform group-hover:translate-x-0.5" />
      )}
    </Link>
  );
}

function PlaceIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6 fill-current" aria-hidden="true">
      <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
    </svg>
  );
}

function VerifiedIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true">
      <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
    </svg>
  );
}

function ChevronIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={clsx('h-5 w-5 fill-current', className)} aria-hidden="true">
      <path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/>
    </svg>
  );
}
