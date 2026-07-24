import { type ReactNode, type MouseEventHandler } from 'react';
import { clsx } from 'clsx';

interface AppCardProps {
  children: ReactNode;
  onTap?: MouseEventHandler<HTMLDivElement>;
  className?: string;
  padding?: string;
  semanticLabel?: string;
}

/** Equivalent of Flutter AppCard — cardAlt bg, radius20, border, shadow2. */
export function AppCard({ children, onTap, className = '', padding = 'p-4', semanticLabel }: AppCardProps) {
  const interactive = !!onTap;
  return (
    <div
      role={interactive ? 'button' : undefined}
      tabIndex={interactive ? 0 : undefined}
      aria-label={semanticLabel}
      onClick={onTap}
      onKeyDown={interactive ? (e) => { if (e.key === 'Enter' || e.key === ' ') (e.currentTarget as HTMLElement).click(); } : undefined}
      className={clsx(
        'rounded-[20px] border border-border bg-cardAlt shadow-yd2',
        interactive && 'cursor-pointer transition-all duration-180 hover:-translate-y-0.5 hover:shadow-yd3 active:translate-y-0 active:shadow-yd1 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30',
        padding,
        className,
      )}
    >
      {children}
    </div>
  );
}

/** PressableCard — stronger press feedback, used for feed items and menu tiles. */
export function PressableCard({ children, onTap, className = '', padding = 'p-4', semanticLabel }: AppCardProps) {
  const interactive = !!onTap;
  return (
    <div
      role={interactive ? 'button' : undefined}
      tabIndex={interactive ? 0 : undefined}
      aria-label={semanticLabel}
      onClick={onTap}
      onKeyDown={interactive ? (e) => { if (e.key === 'Enter' || e.key === ' ') (e.currentTarget as HTMLElement).click(); } : undefined}
      className={clsx(
        'rounded-[20px] border border-border bg-cardAlt shadow-yd2',
        interactive && 'cursor-pointer select-none transition-all duration-180 hover:translate-y-[-2px] hover:shadow-yd3 active:scale-[0.97] active:shadow-yd1 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30',
        padding,
        className,
      )}
    >
      {children}
    </div>
  );
}
