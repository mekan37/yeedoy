'use client';

import { type ReactNode } from 'react';
import { clsx } from 'clsx';

export type MetricCardTone = 'primary' | 'blue' | 'pink' | 'purple' | 'green' | 'orange';

const TONE_CLASSES: Record<MetricCardTone, string> = {
  primary: 'bg-primary/10 text-(--yd-color-primary)',
  blue: 'bg-blue-50 text-blue-600',
  pink: 'bg-rose-50 text-rose-600',
  purple: 'bg-violet-50 text-violet-600',
  green: 'bg-emerald-50 text-emerald-600',
  orange: 'bg-amber-50 text-amber-600',
};

interface MetricCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: ReactNode;
  tone?: MetricCardTone;
  trend?: { value: number; label?: string };
  /** Additional className on the wrapper */
  className?: string;
}

export function MetricCard({ title, value, subtitle, icon, tone = 'primary', trend, className }: MetricCardProps) {
  const trendPositive = trend && trend.value >= 0;

  return (
    <div
      className={clsx(
        'group flex flex-col gap-3 rounded-2xl border border-border bg-card p-5 shadow-xs',
        'transition-all duration-200 hover:translate-y-[-2px] hover:shadow-md',
        className,
      )}
    >
      {icon && (
        <div className={clsx('flex h-10 w-10 shrink-0 items-center justify-center rounded-xl', TONE_CLASSES[tone])}>
          {icon}
        </div>
      )}

      <div className="min-w-0">
        <p
          className="text-2xl font-black tabular-nums tracking-tight text-textStrong"
          style={{ fontVariantNumeric: 'tabular-nums' }}
        >
          {value}
        </p>
        <p className="mt-0.5 truncate text-xs font-bold text-muted">{title}</p>
      </div>

      {trend && (
        <div className="flex flex-col gap-0.5">
          <span
            className={clsx(
              'inline-flex w-fit items-center gap-0.5 text-[11px] font-extrabold',
              trendPositive ? 'text-emerald-600' : 'text-(--yd-color-danger)',
            )}
          >
            {trendPositive ? '↑' : '↓'} %{Math.abs(trend.value)}
          </span>
          {trend.label && <span className="truncate text-[11px] text-muted">{trend.label}</span>}
        </div>
      )}
      {subtitle && !trend && <p className="text-[11px] text-muted">{subtitle}</p>}
    </div>
  );
}
