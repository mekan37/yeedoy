'use client';

import { useRouter } from 'next/navigation';
import {
  ResponsiveContainer,
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  BarChart, Bar,
  PieChart, Pie, Cell,
} from 'recharts';

// ── Types (exported — page.tsx uses them) ────────────────────────────────────
export type DailyPoint    = { label: string; current: number; previous: number };
export type TrafficSource = { name: string; value: number; color: string };
export type HeatmapRow    = { metric: string; counts: number[]; norms: number[] };
export type HourlyPoint   = { h: string; v: number };

export interface AnalyticsClientProps {
  period: string;
  views: number;      viewsPrev: number;
  favorites: number;  favoritesPrev: number;
  reviews: number;    reviewsPrev: number;
  directions: number; directionsPrev: number;
  searches: number;   searchesPrev: number;
  dailyData:      DailyPoint[];
  trafficSources: TrafficSource[];
  heatmapRows:    HeatmapRow[];
  hourlyData:     HourlyPoint[];
}

const PERIOD_OPTIONS = [
  { key: '7d',  label: 'Son 7 Gün' },
  { key: '30d', label: 'Son 30 Gün' },
  { key: '90d', label: 'Son 90 Gün' },
];

// ── Helpers ───────────────────────────────────────────────────────────────────
function pct(cur: number, prev: number): number | null {
  if (prev === 0) return null;
  return Math.round(((cur - prev) / prev) * 100);
}
function fmt(n: number) { return n.toLocaleString('tr-TR'); }
function heatColor(v: number) {
  if (v >= 90) return '#7f1d1d';
  if (v >= 70) return '#b91c1c';
  if (v >= 50) return '#dc2626';
  if (v >= 30) return '#f87171';
  if (v >= 10) return '#fca5a5';
  return '#fef2f2';
}

// ── KPI Card ─────────────────────────────────────────────────────────────────
function KpiCard({ label, value, prev, icon }: {
  label: string; value: number; prev: number; icon: React.ReactNode;
}) {
  const p = pct(value, prev);
  const up = p !== null && p >= 0;
  return (
    <div className="flex flex-col gap-3 rounded-2xl border border-[#f0f0f0] bg-white p-5 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
      <div className="flex items-center justify-between">
        <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#fef2f2] text-[#dc2626]">{icon}</span>
        {p !== null ? (
          <span className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-[800] ${
            up ? 'bg-[#dcfce7] text-[#16a34a]' : 'bg-[#fee2e2] text-[#dc2626]'
          }`}>{up ? '↑' : '↓'} {Math.abs(p)}%</span>
        ) : (
          <span className="rounded-full bg-[#f1f5f9] px-2 py-0.5 text-[11px] font-[700] text-[#94a3b8]">—</span>
        )}
      </div>
      <div>
        <p className="text-[26px] font-[900] text-[#1a1a2e] leading-tight">{fmt(value)}</p>
        <p className="mt-0.5 text-[12px] font-[600] text-[#94a3b8]">{label}</p>
      </div>
      {p !== null && <p className="text-[11px] text-[#94a3b8] font-[600]">Önceki dönem: {fmt(prev)}</p>}
    </div>
  );
}

// ── Section Card ──────────────────────────────────────────────────────────────
function SectionCard({ title, subtitle, children, className = '' }: {
  title: string; subtitle?: string; children: React.ReactNode; className?: string;
}) {
  return (
    <div className={`rounded-2xl border border-[#f0f0f0] bg-white shadow-[0_1px_3px_rgba(0,0,0,0.04)] ${className}`}>
      <div className="border-b border-[#f0f0f0] px-5 py-4">
        <p className="text-[14px] font-[800] text-[#1a1a2e]">{title}</p>
        {subtitle && <p className="mt-0.5 text-[11px] font-[600] text-[#94a3b8]">{subtitle}</p>}
      </div>
      <div className="p-5">{children}</div>
    </div>
  );
}

// ── Donut card (handles empty) ─────────────────────────────────────────────
function DonutCard({ title, subtitle, data }: {
  title: string; subtitle?: string; data: TrafficSource[];
}) {
  if (data.length === 0) {
    return (
      <SectionCard title={title} subtitle={subtitle}>
        <div className="flex flex-col items-center justify-center py-14 text-center">
          <NoDataIcon />
          <p className="mt-3 text-[13px] font-[700] text-[#94a3b8]">Henüz veri yok</p>
        </div>
      </SectionCard>
    );
  }
  return (
    <SectionCard title={title} subtitle={subtitle}>
      <div style={{ height: 180 }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={data} cx="50%" cy="50%" innerRadius={52} outerRadius={80} paddingAngle={2} dataKey="value">
              {data.map((d) => <Cell key={d.name} fill={d.color} />)}
            </Pie>
            <Tooltip formatter={(v) => [`${v}%`, '']} />
          </PieChart>
        </ResponsiveContainer>
      </div>
      <div className="mt-3 flex flex-col gap-1.5">
        {data.map((d) => (
          <div key={d.name} className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: d.color }} />
              <span className="text-[12px] font-[600] text-[#475569]">{d.name}</span>
            </div>
            <span className="text-[12px] font-[800] text-[#1a1a2e]">{d.value}%</span>
          </div>
        ))}
      </div>
    </SectionCard>
  );
}

// ── Custom Tooltips ───────────────────────────────────────────────────────────
function LineTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-[#f0f0f0] bg-white p-3 shadow-lg text-[12px]">
      <p className="mb-1.5 font-[800] text-[#1a1a2e]">{label}</p>
      {payload.map((p: any) => (
        <p key={p.name} className="font-[600]" style={{ color: p.color }}>
          {p.name === 'current' ? 'Bu Dönem' : 'Önceki Dönem'}: {fmt(p.value)}
        </p>
      ))}
    </div>
  );
}
function BarTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-[#f0f0f0] bg-white p-3 shadow-lg text-[12px]">
      <p className="font-[800] text-[#1a1a2e]">{label}:00</p>
      <p className="font-[600] text-[#dc2626]">{fmt(payload[0].value)} görüntülenme</p>
    </div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export function AnalyticsClient({
  period,
  views, viewsPrev,
  favorites, favoritesPrev,
  reviews, reviewsPrev,
  directions, directionsPrev,
  searches, searchesPrev,
  dailyData,
  trafficSources,
  heatmapRows,
  hourlyData,
}: AnalyticsClientProps) {
  const router = useRouter();

  function setPeriod(p: string) { router.push(`/owner/analytics?period=${p}`); }

  const periodLabel = PERIOD_OPTIONS.find((o) => o.key === period)?.label ?? 'Son 30 Gün';
  const compLabel   = period === '7d' ? '7' : period === '90d' ? '90' : '30';
  const xInterval   = dailyData.length > 14 ? Math.floor(dailyData.length / 6) - 1 : 0;
  const totalMetrics = views + favorites + reviews + directions;

  return (
    <div className="flex flex-col gap-5 px-6 pb-8 pt-2">

      {/* Period selector */}
      <div className="flex items-center gap-2">
        <div className="flex items-center rounded-xl border border-[#e5e7eb] bg-white p-1 gap-1">
          {PERIOD_OPTIONS.map((o) => (
            <button key={o.key} onClick={() => setPeriod(o.key)}
              className={`rounded-lg px-3 py-1.5 text-[12px] font-[800] transition-all cursor-pointer ${
                period === o.key ? 'bg-[#7f1d1d] text-white shadow-sm' : 'text-[#475569] hover:bg-[#f8fafc]'
              }`}>
              {o.label}
            </button>
          ))}
        </div>
        <span className="text-[12px] font-[600] text-[#94a3b8]">Önceki {compLabel} günle karşılaştırma</span>
      </div>

      {/* KPI Row */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-5">
        <KpiCard label="Görüntülenme"   value={views}      prev={viewsPrev}      icon={<EyeIcon />} />
        <KpiCard label="Favori"         value={favorites}  prev={favoritesPrev}  icon={<HeartIcon />} />
        <KpiCard label="Yorum"          value={reviews}    prev={reviewsPrev}    icon={<StarIcon />} />
        <KpiCard label="Yol Tarifi"     value={directions} prev={directionsPrev} icon={<MapIcon />} />
        <KpiCard label="Arama Görünümü" value={searches}   prev={searchesPrev}   icon={<SearchIcon />} />
      </div>

      {/* Row 2: Line chart + Traffic sources */}
      <div className="grid gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <SectionCard title="Görüntülenme Grafiği" subtitle={`${periodLabel} — günlük trend`}>
            <div className="mb-3 flex items-center gap-4 text-[11px] font-[700]">
              <span className="flex items-center gap-1.5 text-[#dc2626]">
                <span className="h-0.5 w-5 rounded bg-[#dc2626]" />Bu Dönem
              </span>
              <span className="flex items-center gap-1.5 text-[#94a3b8]">
                <span className="h-px w-5 rounded" style={{ borderTop: '1.5px dashed #94a3b8', display: 'block' }} />Önceki Dönem
              </span>
            </div>
            <div style={{ height: 220 }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={dailyData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="label" tick={{ fontSize: 10, fill: '#94a3b8', fontWeight: 600 }}
                    interval={xInterval} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: '#94a3b8', fontWeight: 600 }}
                    tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip content={<LineTooltip />} />
                  <Line type="monotone" dataKey="current"  stroke="#dc2626" strokeWidth={2}
                    dot={false} activeDot={{ r: 5, fill: '#dc2626' }} />
                  <Line type="monotone" dataKey="previous" stroke="#94a3b8" strokeWidth={1.5}
                    strokeDasharray="5 4" dot={false} activeDot={{ r: 4, fill: '#94a3b8' }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </SectionCard>
        </div>
        <DonutCard title="Ziyaretçi Kaynakları" subtitle="Kaynak bazlı trafik dağılımı" data={trafficSources} />
      </div>

      {/* Row 3: Heatmap */}
      <SectionCard title="Günlere Göre Performans" subtitle="Haftalık metrik yoğunluğu (gerçek veri)">
        {heatmapRows.length === 0 || heatmapRows.every(r => r.counts.every(c => c === 0)) ? (
          <div className="flex flex-col items-center justify-center py-10 text-center">
            <NoDataIcon />
            <p className="mt-3 text-[13px] font-[700] text-[#94a3b8]">Henüz veri yok</p>
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-[11px]">
                <thead>
                  <tr>
                    <th className="w-[110px] pb-2 text-left font-[700] text-[#94a3b8]" />
                    {['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((d) => (
                      <th key={d} className="pb-2 text-center font-[800] text-[#475569]">{d}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {heatmapRows.map((row) => (
                    <tr key={row.metric}>
                      <td className="py-1.5 pr-3 font-[700] text-[#475569] whitespace-nowrap">{row.metric}</td>
                      {row.counts.map((count, ci) => (
                        <td key={ci} className="py-1 px-1 text-center">
                          <div className="mx-auto flex h-8 w-full min-w-[36px] items-center justify-center rounded-lg text-[10px] font-[900]"
                            style={{
                              background: heatColor(row.norms[ci]),
                              color: row.norms[ci] >= 50 ? '#fff' : '#7f1d1d',
                              minWidth: 36,
                            }}>
                            {count}
                          </div>
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="mt-4 flex items-center gap-2">
              <span className="text-[10px] font-[600] text-[#94a3b8]">Az</span>
              {['#fef2f2', '#fca5a5', '#f87171', '#dc2626', '#b91c1c', '#7f1d1d'].map((c) => (
                <span key={c} className="h-3 flex-1 rounded" style={{ background: c }} />
              ))}
              <span className="text-[10px] font-[600] text-[#94a3b8]">Çok</span>
            </div>
          </>
        )}
      </SectionCard>

      {/* Row 4: Bar chart */}
      <SectionCard title="Popüler Saatler" subtitle="Saatlik görüntülenme dağılımı (gerçek veri)">
        {hourlyData.every(h => h.v === 0) ? (
          <div className="flex flex-col items-center justify-center py-10 text-center">
            <NoDataIcon />
            <p className="mt-3 text-[13px] font-[700] text-[#94a3b8]">Henüz veri yok</p>
          </div>
        ) : (
          <div style={{ height: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={hourlyData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
                <XAxis dataKey="h" tick={{ fontSize: 9, fill: '#94a3b8', fontWeight: 600 }}
                  tickLine={false} axisLine={false} interval={2} />
                <YAxis tick={{ fontSize: 10, fill: '#94a3b8', fontWeight: 600 }}
                  tickLine={false} axisLine={false} allowDecimals={false} />
                <Tooltip content={<BarTooltip />} cursor={{ fill: '#fef2f2' }} />
                <Bar dataKey="v" fill="#dc2626" radius={[4, 4, 0, 0]} maxBarSize={18} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </SectionCard>

      {/* Summary bar */}
      <div className="flex items-center justify-between rounded-2xl border border-[#f0f0f0] bg-white px-6 py-4 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
        <div>
          <p className="text-[14px] font-[900] text-[#1a1a2e]">Performans Özeti</p>
          <p className="mt-0.5 text-[12px] font-[600] text-[#94a3b8]">
            {periodLabel} toplam: {fmt(totalMetrics)} etkileşim
          </p>
        </div>
        <button disabled title="Yakında aktif olacak"
          className="flex items-center gap-2 rounded-xl border border-[#e5e7eb] bg-[#fafafa] px-4 py-2.5 text-[12px] font-[800] text-[#94a3b8] opacity-60 cursor-not-allowed">
          <DownloadIcon />
          Detaylı Raporu İndir
        </button>
      </div>
    </div>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────────────
function EyeIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
function HeartIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" /></svg>;
}
function StarIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>;
}
function MapIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="3 11 22 2 13 21 11 13 3 11" /></svg>;
}
function SearchIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>;
}
function DownloadIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
function NoDataIcon() {
  return <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" /></svg>;
}
