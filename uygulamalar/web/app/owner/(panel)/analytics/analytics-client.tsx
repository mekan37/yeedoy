'use client';

import { useRouter } from 'next/navigation';
import {
  ResponsiveContainer,
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  PieChart, Pie, Cell,
} from 'recharts';
import type { HourBucketRow, ReservationStatusRow } from '@/src/lib/veri/owner/analitik-yardimcilari';

// ── Types (exported — page.tsx uses them) ────────────────────────────────────
export type DailyPoint    = { label: string; current: number; previous: number };
export type TrafficSource = { name: string; value: number; color: string; count: number };
export type ActionMetric  = {
  key: 'menuViews' | 'qrScans' | 'menuShares' | 'reservations';
  value: number;
  prev: number;
};

export interface AnalyticsClientProps {
  period: string;
  views: number;             viewsPrev: number;
  profileVisits: number;     profileVisitsPrev: number;
  phoneCalls: number;        phoneCallsPrev: number;
  directions: number;        directionsPrev: number;
  favorites: number;         favoritesPrev: number;
  dailyData:         DailyPoint[];
  trafficSources:    TrafficSource[];
  reservationStatus: ReservationStatusRow[];
  hourBuckets:       HourBucketRow[];
  bestDay:           string | null;
  bestHourRange:     string | null;
  actions:           ActionMetric[];
  totalInteractions: number;
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

const RESERVATION_STATUS_COLORS: Record<string, string> = {
  confirmed: '#16a34a',
  pending:   '#f59e0b',
  completed: '#2563eb',
  cancelled: '#dc2626',
};

const ACTION_META: Record<ActionMetric['key'], { label: string; iconBg: string; iconColor: string }> = {
  menuViews:    { label: 'Menü Görüntüleme', iconBg: '#eff6ff', iconColor: '#2563eb' },
  qrScans:      { label: 'QR Kod Tarama',     iconBg: '#f5f3ff', iconColor: '#7c3aed' },
  menuShares:   { label: 'Menü Paylaşımı',    iconBg: '#ecfdf5', iconColor: '#059669' },
  reservations: { label: 'Rezervasyon',       iconBg: '#fff7ed', iconColor: '#ea580c' },
};

function actionIcon(key: ActionMetric['key']) {
  switch (key) {
    case 'menuViews':    return <EyeIcon />;
    case 'qrScans':      return <QrIcon />;
    case 'menuShares':   return <ShareIcon />;
    case 'reservations': return <CalendarIcon />;
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────
function KpiCard({ label, value, prev, icon, iconBg, iconColor }: {
  label: string; value: number; prev: number; icon: React.ReactNode;
  iconBg: string; iconColor: string;
}) {
  const p = pct(value, prev);
  const up = p !== null && p >= 0;
  return (
    <div className="flex flex-col gap-3 rounded-2xl border border-[#f0f0f0] bg-white p-5 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
      <div className="flex items-center justify-between">
        <span className="flex h-9 w-9 items-center justify-center rounded-xl" style={{ background: iconBg, color: iconColor }}>{icon}</span>
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
  const total = data.reduce((sum, d) => sum + d.count, 0);
  return (
    <SectionCard title={title} subtitle={subtitle}>
      <div className="relative" style={{ height: 180 }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={data} cx="50%" cy="50%" innerRadius={52} outerRadius={80} paddingAngle={2} dataKey="value">
              {data.map((d) => <Cell key={d.name} fill={d.color} />)}
            </Pie>
            <Tooltip formatter={(v) => [`${v}%`, '']} />
          </PieChart>
        </ResponsiveContainer>
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
          <p className="text-[11px] font-[700] text-[#94a3b8]">Toplam</p>
          <p className="text-[20px] font-[900] text-[#1a1a2e]">{fmt(total)}</p>
        </div>
      </div>
      <div className="mt-3 flex flex-col gap-1.5">
        {data.map((d) => (
          <div key={d.name} className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: d.color }} />
              <span className="text-[12px] font-[600] text-[#475569]">{d.name}</span>
            </div>
            <span className="text-[12px] font-[800] text-[#1a1a2e]">%{d.value} · {fmt(d.count)}</span>
          </div>
        ))}
      </div>
    </SectionCard>
  );
}

// ── Reservation status card (handles empty) ──────────────────────────────────
function ReservationStatusCard({ rows }: { rows: ReservationStatusRow[] }) {
  const total = rows.reduce((sum, r) => sum + r.count, 0);
  if (total === 0) {
    return (
      <SectionCard title="Rezervasyon Durumu" subtitle="Dönem içindeki dağılım">
        <div className="flex flex-col items-center justify-center py-10 text-center">
          <NoDataIcon />
          <p className="mt-3 text-[13px] font-[700] text-[#94a3b8]">Henüz veri yok</p>
        </div>
      </SectionCard>
    );
  }
  return (
    <SectionCard title="Rezervasyon Durumu" subtitle="Dönem içindeki dağılım">
      <div className="flex flex-col gap-3">
        {rows.map((r) => (
          <div key={r.status} className="flex flex-col gap-1">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: RESERVATION_STATUS_COLORS[r.status] }} />
                <span className="text-[12px] font-[600] text-[#475569]">{r.label}</span>
              </div>
              <span className="text-[12px] font-[800] text-[#1a1a2e]">{fmt(r.count)}</span>
            </div>
            <div className="h-1.5 w-full rounded-full bg-[#f1f5f9]">
              <div className="h-1.5 rounded-full" style={{ width: `${r.pct}%`, background: RESERVATION_STATUS_COLORS[r.status] }} />
            </div>
          </div>
        ))}
      </div>
    </SectionCard>
  );
}

// ── Hour heatmap card (gün × 4 saatlik blok) ─────────────────────────────────
function HourHeatmapCard({ rows }: { rows: HourBucketRow[] }) {
  const allZero = rows.every((r) => r.counts.every((c) => c === 0));
  return (
    <SectionCard title="Popüler Saatler" subtitle="Gün ve saate göre görüntülenme yoğunluğu">
      {allZero ? (
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
                  <th className="w-[60px] pb-2 text-left font-[700] text-[#94a3b8]" />
                  {['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((d) => (
                    <th key={d} className="pb-2 text-center font-[800] text-[#475569]">{d}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.bucketLabel}>
                    <td className="py-1.5 pr-3 font-[700] text-[#475569] whitespace-nowrap">{row.bucketLabel}</td>
                    {row.counts.map((count, ci) => (
                      <td key={ci} className="py-1 px-1 text-center">
                        <div className="mx-auto flex h-8 w-full min-w-[32px] items-center justify-center rounded-lg text-[10px] font-[900]"
                          style={{
                            background: heatColor(row.norms[ci]),
                            color: row.norms[ci] >= 50 ? '#fff' : '#7f1d1d',
                            minWidth: 32,
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
  );
}

// ── Actions card ───────────────────────────────────────────────────────────
function ActionsCard({ actions }: { actions: ActionMetric[] }) {
  return (
    <SectionCard title="Eylemler" subtitle="Dönem içindeki etkileşimler">
      <div className="flex flex-col gap-3">
        {actions.map((a) => {
          const meta = ACTION_META[a.key];
          const p = pct(a.value, a.prev);
          const up = p !== null && p >= 0;
          return (
            <div key={a.key} className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <span className="flex h-8 w-8 items-center justify-center rounded-lg" style={{ background: meta.iconBg, color: meta.iconColor }}>
                  {actionIcon(a.key)}
                </span>
                <span className="text-[12px] font-[700] text-[#475569]">{meta.label}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-[900] text-[#1a1a2e]">{fmt(a.value)}</span>
                {p !== null && (
                  <span className={`text-[10px] font-[800] ${up ? 'text-[#16a34a]' : 'text-[#dc2626]'}`}>
                    {up ? '↑' : '↓'} %{Math.abs(p)}
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
      <button disabled title="Yakında aktif olacak"
        className="mt-4 flex w-full items-center justify-center gap-1.5 rounded-xl border border-[#e5e7eb] bg-[#fafafa] px-4 py-2.5 text-[12px] font-[800] text-[#94a3b8] opacity-60 cursor-not-allowed">
        Tüm Eylemleri Görüntüle
      </button>
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

// ── Main ─────────────────────────────────────────────────────────────────────
export function AnalyticsClient({
  period,
  views, viewsPrev,
  profileVisits, profileVisitsPrev,
  phoneCalls, phoneCallsPrev,
  directions, directionsPrev,
  favorites, favoritesPrev,
  dailyData,
  trafficSources,
  reservationStatus,
  hourBuckets,
  bestDay,
  bestHourRange,
  actions,
  totalInteractions,
}: AnalyticsClientProps) {
  const router = useRouter();

  function setPeriod(p: string) { router.push(`/owner/analytics?period=${p}`); }

  const periodLabel = PERIOD_OPTIONS.find((o) => o.key === period)?.label ?? 'Son 30 Gün';
  const compLabel   = period === '7d' ? '7' : period === '90d' ? '90' : '30';
  const xInterval   = dailyData.length > 14 ? Math.floor(dailyData.length / 6) - 1 : 0;

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
        <KpiCard label="Görüntülenme" value={views} prev={viewsPrev}
          icon={<EyeIcon />} iconBg="#eff6ff" iconColor="#2563eb" />
        <KpiCard label="Profil Ziyaretleri" value={profileVisits} prev={profileVisitsPrev}
          icon={<CursorIcon />} iconBg="#f5f3ff" iconColor="#7c3aed" />
        <KpiCard label="Telefon Aramaları" value={phoneCalls} prev={phoneCallsPrev}
          icon={<PhoneIcon />} iconBg="#ecfdf5" iconColor="#059669" />
        <KpiCard label="Yol Tarifi İstekleri" value={directions} prev={directionsPrev}
          icon={<MapIcon />} iconBg="#fff7ed" iconColor="#ea580c" />
        <KpiCard label="Favorilere Ekleme" value={favorites} prev={favoritesPrev}
          icon={<HeartIcon />} iconBg="#fdf2f8" iconColor="#db2777" />
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

      {/* Row 3: Rezervasyon Durumu | Popüler Saatler | Eylemler */}
      <div className="grid gap-4 xl:grid-cols-3">
        <ReservationStatusCard rows={reservationStatus} />
        <HourHeatmapCard rows={hourBuckets} />
        <ActionsCard actions={actions} />
      </div>

      {/* Summary bar */}
      <div className="flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-[#f0f0f0] bg-white px-6 py-4 shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
        <div>
          <p className="text-[14px] font-[900] text-[#1a1a2e]">Performans Özeti</p>
          <p className="mt-0.5 text-[12px] font-[600] text-[#94a3b8]">
            {periodLabel} toplam: {fmt(totalInteractions)} etkileşim
            {bestDay && ` · En iyi gün: ${bestDay}`}
            {bestHourRange && ` · En yoğun saat: ${bestHourRange}`}
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
function MapIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="3 11 22 2 13 21 11 13 3 11" /></svg>;
}
function CursorIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z" /></svg>;
}
function PhoneIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></svg>;
}
function QrIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><line x1="14" y1="14" x2="14" y2="21" /><line x1="21" y1="14" x2="21" y2="14.01" /><line x1="14" y1="17.5" x2="17.5" y2="17.5" /><line x1="17.5" y1="14" x2="17.5" y2="21" /><line x1="21" y1="17.5" x2="21" y2="21" /></svg>;
}
function ShareIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" /></svg>;
}
function CalendarIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" /></svg>;
}
function DownloadIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
function NoDataIcon() {
  return <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" /></svg>;
}
