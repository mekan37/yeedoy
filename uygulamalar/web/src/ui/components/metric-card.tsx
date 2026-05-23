'use client';

import { type ReactNode } from 'react';
import { clsx } from 'clsx';

interface MetricCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: ReactNode;
  trend?: { value: number; label?: string };
  /** Additional className on the wrapper */
  className?: string;
}

export function MetricCard({ title, value, subtitle, icon, trend, className }: MetricCardProps) {
  const trendPositive = trend && trend.value >= 0;

  return (
    <div
      className={clsx(
        'group relative overflow-hidden rounded-2xl border border-border bg-card p-5 shadow-sm',
        'transition-all duration-200 hover:-translate-y-[2px] hover:shadow-md',
        className,
      )}
    >
      {/* Subtle radial top-left glow */}
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(127,29,29,0.04),transparent_60%)]" />

      <div className="relative flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-xs font-[700] uppercase tracking-[0.06em] text-muted">{title}</p>
          <p
            className="mt-1 text-3xl font-[900] tabular-nums tracking-tight text-textStrong"
            style={{ fontVariantNumeric: 'tabular-nums' }}
          >
            {value}
          </p>
          {subtitle && <p className="mt-0.5 text-xs text-muted">{subtitle}</p>}
          {trend && (
            <span
              className={clsx(
                'mt-2 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-[800]',
                trendPositive
                  ? 'bg-green-50 text-green-700'
                  : 'bg-red-50 text-[color:var(--yd-color-danger)]',
              )}
            >
              {trendPositive ? '▲' : '▼'}
              {Math.abs(trend.value)}%{trend.label ? ` ${trend.label}` : ''}
            </span>
          )}
        </div>

        {icon && (
          <div
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-[color:var(--yd-color-primary)]"
            style={{
              background: 'radial-gradient(circle at center, rgba(127,29,29,0.10), rgba(127,29,29,0.04))',
            }}
          >
            {icon}
          </div>
        )}
      </div>
    </div>
  );
}
