'use client';

import { type ReactNode } from 'react';
import { clsx } from 'clsx';

interface PanelTopbarProps {
  title?: string;
  toggleButton?: ReactNode;
  centerSlot?: ReactNode;
  actions?: ReactNode;
}

export function PanelTopbar({ title, toggleButton, centerSlot, actions }: PanelTopbarProps) {
  return (
    <header className="flex h-[60px] shrink-0 items-center gap-2 border-b border-border bg-card px-3">
      {toggleButton}

      {/* Panel kimlik badge'i */}
      <div className="flex items-center gap-2 rounded-lg border border-primary/20 bg-primary/8 px-2.5 py-1">
        <span className="h-2 w-2 shrink-0 rounded-full bg-primary" />
        <span className="text-[11px] font-black uppercase tracking-[0.14em] text-primary whitespace-nowrap">
          {title ?? 'Panel'}
        </span>
      </div>

      {centerSlot && <div className="flex flex-1 justify-center px-3">{centerSlot}</div>}
      <div className="ml-auto flex items-center gap-2">{actions}</div>
    </header>
  );
}

interface TopbarIconButtonProps {
  onClick?: () => void;
  label: string;
  children: ReactNode;
  className?: string;
}

export function TopbarIconButton({ onClick, label, children, className }: TopbarIconButtonProps) {
  return (
    <button
      onClick={onClick}
      aria-label={label}
      className={clsx(
        'flex h-9 w-9 items-center justify-center rounded-lg text-muted transition-colors hover:bg-textStrong/[0.07] hover:text-textStrong focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30',
        className,
      )}
    >
      {children}
    </button>
  );
}
