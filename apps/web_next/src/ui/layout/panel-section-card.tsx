import { clsx } from 'clsx';
import { type ReactNode } from 'react';

interface PanelSectionCardProps {
  title?: string;
  description?: string;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
  noPadding?: boolean;
}

export function PanelSectionCard({
  title,
  description,
  actions,
  children,
  className,
  noPadding,
}: PanelSectionCardProps) {
  return (
    <div
      className={clsx(
        'rounded-2xl border border-border bg-card shadow-sm',
        className,
      )}
    >
      {(title || actions) && (
        <div className="flex items-center justify-between gap-3 border-b border-border px-5 py-4">
          <div>
            {title && (
              <h2 className="text-[15px] font-[900] text-textStrong">{title}</h2>
            )}
            {description && (
              <p className="mt-0.5 text-xs text-muted">{description}</p>
            )}
          </div>
          {actions && <div className="flex shrink-0 items-center gap-2">{actions}</div>}
        </div>
      )}
      <div className={noPadding ? undefined : 'p-5'}>{children}</div>
    </div>
  );
}

interface PanelContentSurfaceProps {
  children: ReactNode;
  className?: string;
}

/** Max-width centered wrapper for panel page content */
export function PanelContentSurface({ children, className }: PanelContentSurfaceProps) {
  return (
    <div className={clsx('mx-auto w-full max-w-[1520px] px-6 pb-10', className)}>
      {children}
    </div>
  );
}
