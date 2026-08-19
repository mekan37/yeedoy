'use client';

import Link from 'next/link';
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import { cityDistribution, type CokluSubeBranch } from '../coklu-sube-yardimcilari';

const RENKLER = [
  'var(--yd-color-primary-strong)',
  '#2563eb',
  '#059669',
  '#d97706',
  '#7c3aed',
  '#0891b2',
];

export function SehirDagilimi({ branches }: { branches: CokluSubeBranch[] }) {
  const distribution = cityDistribution(branches);
  const total = branches.length;

  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Şube Dağılımı</h3>
      {distribution.length === 0 ? (
        <p className="text-xs text-muted">Henüz şube yok.</p>
      ) : (
        <>
          <div className="relative mx-auto h-40 w-40">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={distribution}
                  dataKey="count"
                  nameKey="city"
                  innerRadius={48}
                  outerRadius={70}
                  paddingAngle={distribution.length > 1 ? 2 : 0}
                  stroke="none"
                >
                  {distribution.map((entry, i) => (
                    <Cell key={entry.city} fill={RENKLER[i % RENKLER.length]} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-2xl font-black text-textStrong">{total}</span>
              <span className="text-[11px] font-bold text-muted">Şube</span>
            </div>
          </div>

          <div className="mt-4 flex flex-col gap-1.5">
            {distribution.map((item, i) => (
              <div key={item.city} className="flex items-center justify-between gap-2 text-sm">
                <span className="flex min-w-0 items-center gap-2 truncate text-textStrong">
                  <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: RENKLER[i % RENKLER.length] }} />
                  <span className="truncate">{item.city}</span>
                </span>
                <span className="shrink-0 text-xs font-bold text-muted">{item.count}</span>
              </div>
            ))}
          </div>
        </>
      )}

      <Link
        href="/kesif/harita"
        target="_blank"
        rel="noopener noreferrer"
        className="mt-4 block rounded-xl border border-border px-3 py-2 text-center text-xs font-bold text-textStrong hover:bg-bg"
      >
        Haritada Görüntüle ↗
      </Link>
    </div>
  );
}
