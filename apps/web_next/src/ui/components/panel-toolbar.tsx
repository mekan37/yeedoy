import { clsx } from 'clsx';
import { type ReactNode } from 'react';

interface PanelToolbarProps {
  children: ReactNode;
  className?: string;
}

export function PanelToolbar({ children, className }: PanelToolbarProps) {
  return (
    <div className={clsx('flex flex-wrap items-center gap-3 py-3', className)}>
      {children}
    </div>
  );
}

interface PanelToolbarGroupProps {
  children: ReactNode;
  className?: string;
}

export function PanelToolbarGroup({ children, className }: PanelToolbarGroupProps) {
  return (
    <div className={clsx('flex items-center gap-2', className)}>
      {children}
    </div>
  );
}
