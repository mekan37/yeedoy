'use client';

import { type ButtonHTMLAttributes, type ReactNode } from 'react';
import { clsx } from 'clsx';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';

interface AppButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  icon?: ReactNode;
  fullWidth?: boolean;
  loading?: boolean;
  children: ReactNode;
}

const variantClasses: Record<Variant, string> = {
  primary:
    'text-white shadow-[var(--yd-shadow-primary)] hover:shadow-[var(--yd-shadow-primary-lg)] hover:-translate-y-px hover:brightness-105 active:translate-y-0 active:brightness-95',
  secondary:
    'border border-border bg-card text-textStrong hover:bg-black/[0.04] hover:border-borderStrong active:bg-black/[0.08]',
  ghost:
    'text-textStrong hover:bg-black/[0.06] active:bg-black/[0.10]',
  danger:
    'border border-red-200 bg-red-50 text-danger hover:bg-red-100 active:bg-red-200',
};

/** Equivalent of Flutter AppButton — min 44px hit target, all 4 variants. */
export function AppButton({
  variant = 'primary',
  icon,
  fullWidth = false,
  loading = false,
  children,
  disabled,
  className,
  ...props
}: AppButtonProps) {
  const isPrimary = variant === 'primary';
  return (
    <button
      disabled={disabled || loading}
      className={clsx(
        'inline-flex min-h-[44px] items-center justify-center gap-2 rounded-2xl px-5 py-2 text-sm font-[800] transition-all duration-[180ms]',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        'disabled:cursor-not-allowed disabled:opacity-50',
        variantClasses[variant],
        fullWidth && 'w-full',
        className,
      )}
      style={isPrimary ? { background: 'var(--yd-gradient-primary)' } : undefined}
      {...props}
    >
      {loading ? <SpinnerIcon /> : icon ? <span className="flex h-[18px] w-[18px] shrink-0 items-center justify-center">{icon}</span> : null}
      {children}
    </button>
  );
}

/** GradientButton — main CTA, bordo→red gradient, colored shadow, press scale. */
export function GradientButton({
  icon,
  fullWidth = false,
  loading = false,
  children,
  disabled,
  className,
  ...props
}: Omit<AppButtonProps, 'variant'>) {
  return (
    <button
      disabled={disabled || loading}
      className={clsx(
        'inline-flex min-h-[52px] items-center justify-center gap-2 rounded-2xl px-5 text-base font-[800] text-white',
        'shadow-[var(--yd-shadow-primary)] transition-all duration-[180ms]',
        'hover:shadow-[var(--yd-shadow-primary-lg)] hover:-translate-y-px hover:brightness-105',
        'active:scale-[0.97] active:translate-y-0 active:brightness-95',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        'disabled:cursor-not-allowed disabled:opacity-50 disabled:shadow-none',
        fullWidth && 'w-full',
        className,
      )}
      style={disabled ? { background: 'var(--yd-color-border)' } : { background: 'var(--yd-gradient-primary)' }}
      {...props}
    >
      {loading ? <SpinnerIcon /> : icon ? <span className="flex h-[18px] w-[18px] shrink-0 items-center justify-center">{icon}</span> : null}
      {children}
    </button>
  );
}

function SpinnerIcon() {
  return (
    <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
  );
}
