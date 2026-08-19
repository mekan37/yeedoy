'use client';

import Link from 'next/link';

type FeatureRow = {
  feature_key: string;
  label: string;
  enabled: boolean;
  limit_value: number | null;
  used: number;
};

export function PlanOzetIstemcisi({
  planTier,
  planLabel,
  features,
}: {
  planTier: string;
  planLabel: string;
  features: FeatureRow[];
}) {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div className="rounded-2xl border border-border bg-card p-5">
        <p className="text-xs font-bold uppercase tracking-wide text-muted">Kademeniz</p>
        <p className="mt-1 text-2xl font-black text-textStrong" data-plan-tier={planTier}>
          {planLabel}
        </p>
      </div>

      <div className="divide-y divide-border rounded-2xl border border-border bg-card">
        {features.map((feature) => (
          <div key={feature.feature_key} className="flex items-center justify-between gap-4 px-5 py-3">
            <span className="text-sm font-semibold text-textStrong">{feature.label}</span>
            {!feature.enabled ? (
              <span className="rounded-full bg-zinc-100 px-2.5 py-1 text-xs font-bold text-zinc-500">
                Kilitli
              </span>
            ) : feature.limit_value === null ? (
              <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold text-emerald-700">
                Sınırsız
              </span>
            ) : (
              <span className="rounded-full border border-border bg-bg px-2.5 py-1 text-xs font-bold text-textStrong">
                {feature.used} / {feature.limit_value}
              </span>
            )}
          </div>
        ))}
      </div>

      <Link
        href="/sahip/premium"
        className="flex min-h-10 items-center justify-center rounded-xl bg-(--yd-color-primary) px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90"
      >
        Planları Karşılaştır
      </Link>
    </div>
  );
}
