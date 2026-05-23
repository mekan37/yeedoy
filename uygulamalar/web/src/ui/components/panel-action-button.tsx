'use client';

import { clsx } from 'clsx';
import { type ButtonHTMLAttributes, type ReactNode } from 'react';

type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';

interface PanelActionButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  icon?: ReactNode;
  loading?: boolean;
  children: ReactNode;
}

const variantClasses: Record<Variant, string> = {
  primary:
    'text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] hover:shadow-[0_6px_24px_rgba(127,29,29,0.36)] hover:-translate-y-[1px] active:translate-y-0',
  secondary:
    'border border-border bg-card text-textStrong hover:bg-black/[0.04] hover:border-borderStrong',
  ghost:
    'text-textStrong hover:bg-black/[0.06]',
  danger:
    'border border-red-200 bg-red-50 text-[color:var(--yd-color-danger)] hover:bg-red-100',
};

export function PanelActionButton({
  variant = 'secondary',
  icon,
  loading,
  children,
  disabled,
  className,
  ...props
}: PanelActionButtonProps) {
  const isPrimary = variant === 'primary';

  return (
    <button
      disabled={disabled || loading}
      className={clsx(
        'inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-[800] transition-all duration-150',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        'disabled:cursor-not-allowed disabled:opacity-50',
        variantClasses[variant],
        className,
      )}
      style={
        isPrimary
          ? { background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }
          : undefined
      }
      {...props}
    >
      {loading ? (
        <SpinnerIcon />
      ) : icon ? (
        <span className="flex h-4 w-4 items-center justify-center text-[14px]">{icon}</span>
      ) : null}
      {children}
    </button>
  );
}

function SpinnerIcon() {
  return (
    <svg
      className="h-4 w-4 animate-spin"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
    >
      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
  );
}
