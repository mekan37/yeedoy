import { type ReactNode } from 'react';

interface AppSectionHeaderProps {
  title: string;
  subtitle?: ReactNode;
  trailing?: ReactNode;
  className?: string;
}

/** Equivalent of Flutter AppSectionHeader — bold title with 8×20px red left-bar accent. */
export function AppSectionHeader({ title, subtitle, trailing, className = '' }: AppSectionHeaderProps) {
  return (
    <div className={`flex flex-col gap-2 ${className}`}>
      <div className="flex items-center gap-2">
        {/* Red left-bar accent */}
        <span
          className="shrink-0 rounded-full bg-primary"
          style={{ width: 8, height: 20 }}
          aria-hidden="true"
        />
        <h2 className="flex-1 text-xl font-black text-textStrong leading-tight">{title}</h2>
        {trailing && <div className="shrink-0">{trailing}</div>}
      </div>
      {subtitle && <div className="text-sm text-muted leading-snug pl-4">{subtitle}</div>}
    </div>
  );
}
