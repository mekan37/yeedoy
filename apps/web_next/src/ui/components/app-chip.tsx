'use client';

import { type ReactNode } from 'react';
import { clsx } from 'clsx';

type ChipColor = 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info';

interface AppChipProps {
  children: ReactNode;
  color?: ChipColor;
  filled?: boolean;
  className?: string;
}

const colorMap: Record<ChipColor, { filled: string; outline: string }> = {
  default:  { filled: 'bg-textStrong/[0.14] border-textStrong/[0.35] text-textStrong',  outline: 'bg-cardAlt border-border text-textStrong' },
  primary:  { filled: 'bg-[var(--yd-color-primary-soft)] border-primary/25 text-primary', outline: 'bg-cardAlt border-border text-primary' },
  success:  { filled: 'bg-success/[0.12] border-success/25 text-success',                outline: 'bg-cardAlt border-border text-success' },
  warning:  { filled: 'bg-warning/[0.12] border-warning/25 text-warning',                outline: 'bg-cardAlt border-border text-warning' },
  danger:   { filled: 'bg-danger/[0.12] border-danger/25 text-danger',                   outline: 'bg-cardAlt border-border text-danger' },
  info:     { filled: 'bg-info/[0.12] border-info/25 text-info',                         outline: 'bg-cardAlt border-border text-info' },
};

/** Equivalent of Flutter AppChip — pill badge with color variants. */
export function AppChip({ children, color = 'default', filled = false, className = '' }: AppChipProps) {
  return (
    <span
      className={clsx(
        'inline-flex min-h-[44px] items-center rounded-full border px-3 py-1 text-xs font-[800]',
        filled ? colorMap[color].filled : colorMap[color].outline,
        className,
      )}
    >
      {children}
    </span>
  );
}

/** StatusChip — convenience wrapper matching Flutter AppChip.status(). */
export function StatusChip({ status, children }: { status: 'success' | 'warning' | 'danger' | 'info'; children: ReactNode }) {
  return <AppChip color={status} filled>{children}</AppChip>;
}

interface CategoryChipProps {
  label: string;
  selected: boolean;
  onSelect: () => void;
}

/** Equivalent of Flutter CategoryChip — toggleable filter pill. */
export function CategoryChip({ label, selected, onSelect }: CategoryChipProps) {
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-pressed={selected}
      className={clsx(
        'inline-flex min-h-[44px] items-center rounded-full border px-3 py-1 text-sm font-[800] transition-all duration-[150ms]',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30',
        selected
          ? 'bg-[var(--yd-color-primary-soft)] border-primary/40 text-primary'
          : 'bg-cardAlt border-border text-textStrong hover:border-borderStrong hover:bg-card',
      )}
    >
      {label}
    </button>
  );
}
