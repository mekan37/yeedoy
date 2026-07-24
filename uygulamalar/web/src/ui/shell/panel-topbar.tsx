'use client';

import { type ReactNode } from 'react';
import { clsx } from 'clsx';

interface PanelTopbarProps {
  title?: string;
  toggleButton?: ReactNode;
  actions?: ReactNode;
}

export function PanelTopbar({ title, toggleButton, actions }: PanelTopbarProps) {
  return (
    <header className="flex h-[60px] shrink-0 items-center gap-3 border-b border-border bg-card px-4">
      {toggleButton}
      {title && (
        <span className="text-sm font-extrabold text-textStrong truncate">{title}</span>
      )}
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
        'flex h-9 w-9 items-center justify-center rounded-lg text-muted transition-colors hover:bg-black/6 hover:text-textStrong focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30',
        className,
      )}
    >
      {children}
    </button>
  );
}
