import { type ReactNode } from 'react';
import { clsx } from 'clsx';

interface PanelPageHeaderProps {
  eyebrow?: string;
  title: string;
  description?: string;
  actions?: ReactNode;
  className?: string;
}

export function PanelPageHeader({ eyebrow, title, description, actions, className }: PanelPageHeaderProps) {
  return (
    <div className={clsx('flex flex-col gap-4 px-6 pt-6 pb-4 sm:flex-row sm:items-start sm:justify-between', className)}>
      {/* Left: accent bar + text */}
      <div className="flex gap-4">
        {/* 3px left accent gradient bar */}
        <div
          className="mt-1 w-[3px] shrink-0 rounded-full"
          style={{ background: 'linear-gradient(180deg, #7f1d1d, #dc2626)', minHeight: '48px' }}
        />
        <div>
          {eyebrow && (
            <p className="mb-0.5 text-[11px] font-extrabold uppercase tracking-[0.07em] text-muted">
              {eyebrow}
            </p>
          )}
          <h1 className="text-2xl font-black tracking-tight text-textStrong">{title}</h1>
          {description && (
            <p className="mt-1 text-sm leading-relaxed text-muted">{description}</p>
          )}
        </div>
      </div>

      {/* Right: actions */}
      {actions && (
        <div className="flex shrink-0 flex-wrap items-center gap-2">{actions}</div>
      )}
    </div>
  );
}
