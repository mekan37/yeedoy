import Link from 'next/link';
import type { ReactNode } from 'react';
import { clsx } from 'clsx';
import { Icon } from '@/src/ui/acik/simgeler';

export function Container({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={clsx('mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8', className)}>{children}</div>;
}

export function SectionHeader({
  eyebrow,
  title,
  subtitle,
  actionHref,
  actionLabel,
  className,
}: {
  eyebrow?: string;
  title: ReactNode;
  subtitle?: string;
  actionHref?: string;
  actionLabel?: string;
  className?: string;
}) {
  return (
    <div className={clsx('flex items-end justify-between gap-4', className)}>
      <div>
        {eyebrow ? <p className="yd-eyebrow mb-2">{eyebrow}</p> : null}
        <h2 className="text-xl font-black leading-tight text-textStrong sm:text-2xl">{title}</h2>
        {subtitle ? <p className="mt-1 text-sm leading-6 text-muted">{subtitle}</p> : null}
      </div>
      {actionHref && actionLabel ? (
        <Link href={actionHref} className="hidden min-h-11 shrink-0 items-center rounded-2xl px-3 text-sm font-black text-primary hover:bg-(--yd-color-primary-soft) sm:inline-flex">
          {actionLabel}
        </Link>
      ) : null}
    </div>
  );
}

export function Badge({ children, tone = 'neutral', className }: { children: ReactNode; tone?: 'neutral' | 'brand' | 'success' | 'warning' | 'danger'; className?: string }) {
  const tones = {
    neutral: 'border-border bg-cardAlt text-textStrong',
    brand: 'border-primary/25 bg-(--yd-color-primary-soft) text-primary',
    success: 'border-success/25 bg-success/12 text-success',
    warning: 'border-warning/25 bg-warning/[0.14] text-textStrong',
    danger: 'border-danger/25 bg-danger/10 text-danger',
  };
  return <span className={clsx('inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-xs font-black', tones[tone], className)}>{children}</span>;
}

export function Card({ children, className, href }: { children: ReactNode; className?: string; href?: string }) {
  const classes = clsx('rounded-[20px] border border-border bg-card shadow-yd1', className);
  if (!href) return <div className={classes}>{children}</div>;
  return (
    <Link href={href} className={clsx(classes, 'block transition-all hover:-translate-y-0.5 hover:border-primary/25 hover:shadow-yd2 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30')}>
      {children}
    </Link>
  );
}

export function ButtonLink({ href, children, variant = 'primary', className }: { href: string; children: ReactNode; variant?: 'primary' | 'secondary' | 'ghost'; className?: string }) {
  return (
    <Link
      href={href}
      className={clsx(
        'inline-flex min-h-[52px] items-center justify-center rounded-2xl px-5 text-sm font-black focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30',
        variant === 'primary' && 'text-white shadow-(--yd-shadow-primary) hover:-translate-y-px hover:brightness-105',
        variant === 'secondary' && 'border border-border bg-card text-textStrong hover:border-primary/35',
        variant === 'ghost' && 'text-textStrong hover:bg-cardAlt',
        className,
      )}
      style={variant === 'primary' ? { background: 'var(--yd-gradient-primary)' } : undefined}
    >
      {children}
    </Link>
  );
}

type EmptyStateVariant = 'search' | 'inbox' | 'favorites' | 'feed' | 'reviews' | 'default';

const EMPTY_ICONS: Record<EmptyStateVariant, ReactNode> = {
  search: (
    <svg viewBox="0 0 64 64" className="h-16 w-16" aria-hidden="true">
      <circle cx="28" cy="28" r="16" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
      <path d="M40 40 L54 54" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
      <path d="M22 28 Q28 20 34 28" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"/>
      <circle cx="22" cy="31" r="2" fill="currentColor"/>
      <circle cx="34" cy="31" r="2" fill="currentColor"/>
    </svg>
  ),
  inbox: (
    <svg viewBox="0 0 64 64" className="h-16 w-16" aria-hidden="true">
      <rect x="8" y="16" width="48" height="36" rx="4" fill="none" stroke="currentColor" strokeWidth="3"/>
      <path d="M8 24 L32 38 L56 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
      <path d="M24 44 L20 50 M40 44 L44 50" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" opacity="0.5"/>
    </svg>
  ),
  favorites: (
    <svg viewBox="0 0 64 64" className="h-16 w-16" aria-hidden="true">
      <path d="M32 52 L10 32 Q6 22 16 16 Q24 12 32 22 Q40 12 48 16 Q58 22 54 32 Z" fill="none" stroke="currentColor" strokeWidth="3" strokeLinejoin="round"/>
      <path d="M22 32 L28 38 L42 24" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" opacity="0.6"/>
    </svg>
  ),
  feed: (
    <svg viewBox="0 0 64 64" className="h-16 w-16" aria-hidden="true">
      <rect x="8" y="8" width="48" height="20" rx="4" fill="none" stroke="currentColor" strokeWidth="3"/>
      <rect x="8" y="36" width="48" height="20" rx="4" fill="none" stroke="currentColor" strokeWidth="3"/>
      <circle cx="18" cy="18" r="5" fill="none" stroke="currentColor" strokeWidth="2.5"/>
      <path d="M26 15 L44 15 M26 21 L38 21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" opacity="0.6"/>
    </svg>
  ),
  reviews: (
    <svg viewBox="0 0 64 64" className="h-16 w-16" aria-hidden="true">
      <path d="M32 10 L36.9 23.9 H51.5 L40.3 32.5 L45.2 46.4 L32 37.8 L18.8 46.4 L23.7 32.5 L12.5 23.9 H27.1 Z" fill="none" stroke="currentColor" strokeWidth="3" strokeLinejoin="round"/>
    </svg>
  ),
  default: (
    <svg viewBox="0 0 64 64" className="h-16 w-16" aria-hidden="true">
      <circle cx="32" cy="32" r="22" fill="none" stroke="currentColor" strokeWidth="3"/>
      <path d="M32 20 L32 32 L40 40" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
};

export function EmptyState({
  title,
  body,
  actionHref,
  actionLabel,
  variant = 'default',
}: {
  title: string;
  body: string;
  actionHref?: string;
  actionLabel?: string;
  variant?: EmptyStateVariant;
}) {
  return (
    <Card className="px-5 py-14 text-center">
      <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-3xl bg-cardAlt text-muted">
        {EMPTY_ICONS[variant]}
      </div>
      <p className="mt-5 text-lg font-black text-textStrong">{title}</p>
      <p className="mx-auto mt-2 max-w-sm text-sm leading-6 text-muted">{body}</p>
      {actionHref && actionLabel ? <ButtonLink href={actionHref} variant="secondary" className="mt-6 min-h-11">{actionLabel}</ButtonLink> : null}
    </Card>
  );
}

export function ErrorState({ title = 'Bir sorun oluştu', body = 'Sayfa verisi alınamadı.', retryHref }: { title?: string; body?: string; retryHref?: string }) {
  return (
    <Card className="border-danger/20 px-5 py-12 text-center">
      <p className="font-black text-textStrong">{title}</p>
      <p className="mt-2 text-sm text-muted">{body}</p>
      {retryHref ? <ButtonLink href={retryHref} className="mt-5 min-h-11">Tekrar dene</ButtonLink> : null}
    </Card>
  );
}

export function LoadingState({ label = 'Yükleniyor' }: { label?: string }) {
  return <div className="min-h-20 rounded-[20px] border border-border bg-card p-5 text-sm font-black text-muted">{label}...</div>;
}

export function Skeleton({ className = '' }: { className?: string }) {
  return <div className={clsx('skeleton', className)} role="status" aria-label="Yükleniyor" />;
}
