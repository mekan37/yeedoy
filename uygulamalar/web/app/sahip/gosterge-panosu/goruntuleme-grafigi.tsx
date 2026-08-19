'use client';

import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export type GunlukGoruntulenme = { gun: string; etiket: string; sayi: number };

interface Props {
  data: GunlukGoruntulenme[];
}

export function GoruntulenmeGrafigi({ data }: Props) {
  if (data.every((d) => d.sayi === 0)) {
    return (
      <div className="flex h-[220px] items-center justify-center text-sm text-muted">
        Bu dönemde görüntülenme verisi yok
      </div>
    );
  }

  return (
    <div className="h-[220px] w-full">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
          <defs>
            <linearGradient id="goruntulenmeGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="var(--yd-color-primary-strong)" stopOpacity={0.28} />
              <stop offset="100%" stopColor="var(--yd-color-primary-strong)" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="var(--yd-color-border)" />
          <XAxis
            dataKey="etiket"
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 11, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
          />
          <YAxis
            axisLine={false}
            tickLine={false}
            width={36}
            tick={{ fontSize: 11, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
          />
          <Tooltip content={<GrafikTooltip />} />
          <Area
            type="monotone"
            dataKey="sayi"
            stroke="var(--yd-color-primary-strong)"
            strokeWidth={2.5}
            fill="url(#goruntulenmeGrad)"
            dot={{ r: 3, fill: 'var(--yd-color-primary-strong)', strokeWidth: 0 }}
            activeDot={{ r: 5, fill: 'var(--yd-color-primary-strong)', strokeWidth: 0 }}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}

function GrafikTooltip({ active, payload, label }: { active?: boolean; payload?: Array<{ value: number }>; label?: string }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-border bg-card px-3 py-2 text-xs font-bold text-textStrong shadow-yd2">
      <p className="text-muted">{label}</p>
      <p className="mt-0.5 text-sm font-black text-(--yd-color-primary-strong)">{payload[0].value.toLocaleString('tr-TR')} görüntülenme</p>
    </div>
  );
}
