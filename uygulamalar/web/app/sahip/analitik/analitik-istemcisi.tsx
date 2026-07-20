'use client';

import { type ReactNode } from 'react';
import {
  ResponsiveContainer,
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  PieChart, Pie, Cell,
} from 'recharts';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { YogunSaatlerKarti } from '@/src/ui/bilesenler/yogun-saatler-karti';
import type { HourBucketRow, ReservationStatusRow } from '@/src/lib/veri/owner/analitik-yardimcilari';
import type { YogunSaatSatiri } from '@/src/lib/veri/owner/mesgul-saatler';

// ── Types (export edilir — page.tsx bunları kullanır) ────────────────────────
export type GunlukNokta   = { label: string; guncel: number; onceki: number };
export type TrafikKaynagi = { name: string; value: number; color: string; count: number };
export type EylemMetrigi  = {
  key: 'menuViews' | 'qrScans' | 'whatsapp' | 'menuShares' | 'reservations';
  value: number;
  prev: number;
};

interface Props {
  etiket: string;
  isletmeSayisi: number;
  goruntulenme: number;         goruntulenmeOnceki: number;
  profilZiyaretleri: number;    profilZiyaretleriOnceki: number;
  telefonAramalari: number;     telefonAramalariOnceki: number;
  yolTarifi: number;            yolTarifiOnceki: number;
  favoriler: number;            favorilerOnceki: number;
  goruntulenmeGunluk: GunlukNokta[];
  trafikKaynaklari:   TrafikKaynagi[];
  rezervasyonDurumu:  ReservationStatusRow[];
  isiHaritasi:        HourBucketRow[];
  enIyiGun:            string | null;
  enYogunSaatAraligi:  string | null;
  eylemler:            EylemMetrigi[];
  toplamEtkilesim:     number;
  gunlukTrend:    { label: string; menu: number; qr: number }[];
  saatlikDagilim: { saat: string; sayi: number }[];
  olayVarMi: boolean;
  yogunSaatler: YogunSaatSatiri[];
}

// ── Yardımcılar ───────────────────────────────────────────────────────────────
function fmt(n: number) { return n.toLocaleString('tr-TR'); }
function pct(cur: number, prev: number): number | null {
  if (prev === 0) return null;
  return Math.round(((cur - prev) / prev) * 100);
}
function trendOf(cur: number, prev: number) {
  const p = pct(cur, prev);
  return p === null ? undefined : { value: p };
}
function heatColor(v: number) {
  const opacity = Math.max(v / 100, 0.04);
  return `rgba(127, 29, 29, ${opacity})`;
}

const DURUM_RENKLERI: Record<string, string> = {
  confirmed: 'var(--yd-color-success)',
  pending:   'var(--yd-color-warning)',
  completed: 'var(--yd-color-info)',
  cancelled: 'var(--yd-color-danger)',
};

const EYLEM_META: Record<EylemMetrigi['key'], { label: string; icon: ReactNode; renk: string }> = {
  menuViews:    { label: 'Menü Görüntüleme', icon: <EyeIcon />,      renk: 'var(--yd-color-info)' },
  qrScans:      { label: 'QR Kod Tarama',     icon: <QrIcon />,      renk: 'var(--yd-color-primary)' },
  whatsapp:     { label: 'WhatsApp Tıklama',  icon: <WhatsappIcon />, renk: 'var(--yd-color-success)' },
  menuShares:   { label: 'Menü Paylaşımı',    icon: <ShareIcon />,    renk: 'var(--yd-color-warning)' },
  reservations: { label: 'Rezervasyon',       icon: <CalendarIcon />, renk: 'var(--yd-color-danger)' },
};

// ── Ana bileşen ────────────────────────────────────────────────────────────────
export function AnalitikIstemcisi({
  etiket,
  isletmeSayisi,
  goruntulenme, goruntulenmeOnceki,
  profilZiyaretleri, profilZiyaretleriOnceki,
  telefonAramalari, telefonAramalariOnceki,
  yolTarifi, yolTarifiOnceki,
  favoriler, favorilerOnceki,
  goruntulenmeGunluk,
  trafikKaynaklari,
  rezervasyonDurumu,
  isiHaritasi,
  enIyiGun,
  enYogunSaatAraligi,
  eylemler,
  toplamEtkilesim,
  gunlukTrend,
  saatlikDagilim,
  olayVarMi,
  yogunSaatler,
}: Props) {
  const xInterval = goruntulenmeGunluk.length > 14 ? Math.floor(goruntulenmeGunluk.length / 6) - 1 : 0;

  return (
    <div className="mx-auto w-full max-w-[1520px] px-6 pb-10 pt-2">

      {/* KPI Satırı */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        <MetricCard title="Görüntülenme" value={fmt(goruntulenme)} subtitle={etiket}
          icon={<EyeIcon />} trend={trendOf(goruntulenme, goruntulenmeOnceki)} />
        <MetricCard title="Profil Ziyaretleri" value={fmt(profilZiyaretleri)} subtitle={etiket}
          icon={<CursorIcon />} trend={trendOf(profilZiyaretleri, profilZiyaretleriOnceki)} />
        <MetricCard title="Telefon Aramaları" value={fmt(telefonAramalari)} subtitle={etiket}
          icon={<PhoneIcon />} trend={trendOf(telefonAramalari, telefonAramalariOnceki)} />
        <MetricCard title="Yol Tarifi İstekleri" value={fmt(yolTarifi)} subtitle={etiket}
          icon={<MapIcon />} trend={trendOf(yolTarifi, yolTarifiOnceki)} />
        <MetricCard title="Favorilere Ekleme" value={fmt(favoriler)} subtitle={etiket}
          icon={<HeartIcon />} trend={trendOf(favoriler, favorilerOnceki)} />
        <MetricCard title="İşletme Sayısı" value={isletmeSayisi} subtitle={etiket}
          icon={<BuildingIcon />} />
      </div>

      {/* Görüntülenme grafiği + Ziyaretçi kaynakları */}
      <div className="mt-6 grid gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <PanelBolumKarti title="Görüntülenme Grafiği" description={`${etiket} — günlük trend`}>
            <div className="mb-3 flex items-center gap-4 text-[11px] font-[700]">
              <span className="flex items-center gap-1.5 text-[color:var(--yd-color-primary-strong)]">
                <span className="h-0.5 w-5 rounded bg-[color:var(--yd-color-primary-strong)]" />Bu Dönem
              </span>
              <span className="flex items-center gap-1.5 text-muted">
                <span className="h-px w-5 rounded" style={{ borderTop: '1.5px dashed var(--yd-color-muted)', display: 'block' }} />Önceki Dönem
              </span>
            </div>
            <div style={{ height: 220 }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={goruntulenmeGunluk} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--yd-color-border)" />
                  <XAxis dataKey="label" tick={{ fontSize: 10, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
                    interval={xInterval} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
                    tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip content={<CizgiTooltip />} />
                  <Line type="monotone" dataKey="guncel" stroke="var(--yd-color-primary-strong)" strokeWidth={2}
                    dot={false} activeDot={{ r: 5 }} />
                  <Line type="monotone" dataKey="onceki" stroke="var(--yd-color-muted)" strokeWidth={1.5}
                    strokeDasharray="5 4" dot={false} activeDot={{ r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </PanelBolumKarti>
        </div>
        <DonutKarti title="Ziyaretçi Kaynakları" subtitle="Kaynak bazlı trafik dağılımı" veri={trafikKaynaklari} />
      </div>

      {/* Rezervasyon Durumu | Popüler Saatler | Eylemler */}
      <div className="mt-4 grid gap-4 xl:grid-cols-3">
        <RezervasyonDurumuKarti satirlar={rezervasyonDurumu} />
        <IsiHaritasiKarti satirlar={isiHaritasi} />
        <EylemlerKarti eylemler={eylemler} />
      </div>

      {/* Performans Özeti */}
      <div className="mt-4 flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-border bg-card px-6 py-4 shadow-sm">
        <div>
          <p className="text-[14px] font-[900] text-textStrong">Performans Özeti</p>
          <p className="mt-0.5 text-[12px] font-[600] text-muted">
            {etiket} toplam: {fmt(toplamEtkilesim)} etkileşim
            {enIyiGun && ` · En iyi gün: ${enIyiGun}`}
            {enYogunSaatAraligi && ` · En yoğun saat: ${enYogunSaatAraligi}`}
          </p>
        </div>
        <button disabled title="Yakında aktif olacak"
          className="flex cursor-not-allowed items-center gap-2 rounded-xl border border-border bg-cardAlt px-4 py-2.5 text-[12px] font-[800] text-muted opacity-60">
          <DownloadIcon />
          Detaylı Raporu İndir
        </button>
      </div>

      {/* Günlük Trend — sahip'e özgü (menü görüntüleme / QR tarama) */}
      {gunlukTrend.length > 0 && (
        <PanelBolumKarti title="Günlük Trend" className="mt-6">
          <TrendGrafik gunler={gunlukTrend} />
        </PanelBolumKarti>
      )}

      {/* Saatlik Dağılım — sahip'e özgü (0-23 saat, tüm etkinlikler) */}
      {olayVarMi && (
        <PanelBolumKarti title="Saatlik Dağılım" className="mt-6">
          <SaatlikDagilimGrafik saatler={saatlikDagilim} />
        </PanelBolumKarti>
      )}

      {/* Yoğun Saatler — sahip'e özgü (get_business_busy_hours_v1, son 28 gün) */}
      <PanelBolumKarti
        title="Yoğun Saatler"
        description="İlk işletmenize ait saat bazlı yoğunluk analizi"
        className="mt-6"
      >
        <YogunSaatlerKarti veriler={yogunSaatler} />
      </PanelBolumKarti>
    </div>
  );
}

// ── Donut kart (Ziyaretçi Kaynakları) ─────────────────────────────────────────
function DonutKarti({ title, subtitle, veri }: { title: string; subtitle?: string; veri: TrafikKaynagi[] }) {
  if (veri.length === 0) {
    return (
      <PanelBolumKarti title={title} description={subtitle}>
        <PanelEmptyState icon={<NoDataIcon />} title="Henüz veri yok" />
      </PanelBolumKarti>
    );
  }
  const toplam = veri.reduce((sum, d) => sum + d.count, 0);
  return (
    <PanelBolumKarti title={title} description={subtitle}>
      <div className="relative" style={{ height: 180 }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={veri} cx="50%" cy="50%" innerRadius={52} outerRadius={80} paddingAngle={2} dataKey="value">
              {veri.map((d) => <Cell key={d.name} fill={d.color} />)}
            </Pie>
            <Tooltip formatter={(v) => [`${v}%`, '']} />
          </PieChart>
        </ResponsiveContainer>
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
          <p className="text-[11px] font-[700] text-muted">Toplam</p>
          <p className="text-[20px] font-[900] text-textStrong">{fmt(toplam)}</p>
        </div>
      </div>
      <div className="mt-3 flex flex-col gap-1.5">
        {veri.map((d) => (
          <div key={d.name} className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: d.color }} />
              <span className="text-[12px] font-[600] text-textStrong/80">{d.name}</span>
            </div>
            <span className="text-[12px] font-[800] text-textStrong">%{d.value} · {fmt(d.count)}</span>
          </div>
        ))}
      </div>
    </PanelBolumKarti>
  );
}

// ── Rezervasyon Durumu kartı ───────────────────────────────────────────────────
function RezervasyonDurumuKarti({ satirlar }: { satirlar: ReservationStatusRow[] }) {
  const toplam = satirlar.reduce((sum, r) => sum + r.count, 0);
  return (
    <PanelBolumKarti title="Rezervasyon Durumu" description="Dönem içindeki dağılım">
      {toplam === 0 ? (
        <PanelEmptyState icon={<NoDataIcon />} title="Henüz veri yok" />
      ) : (
        <div className="flex flex-col gap-3">
          {satirlar.map((r) => (
            <div key={r.status} className="flex flex-col gap-1">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: DURUM_RENKLERI[r.status] }} />
                  <span className="text-[12px] font-[600] text-textStrong/80">{r.label}</span>
                </div>
                <span className="text-[12px] font-[800] text-textStrong">{fmt(r.count)}</span>
              </div>
              <div className="h-1.5 w-full rounded-full bg-border">
                <div className="h-1.5 rounded-full" style={{ width: `${r.pct}%`, background: DURUM_RENKLERI[r.status] }} />
              </div>
            </div>
          ))}
        </div>
      )}
    </PanelBolumKarti>
  );
}

// ── Popüler Saatler ısı haritası (gün × 4 saatlik blok) ───────────────────────
function IsiHaritasiKarti({ satirlar }: { satirlar: HourBucketRow[] }) {
  const hepsiSifir = satirlar.every((r) => r.counts.every((c) => c === 0));
  return (
    <PanelBolumKarti title="Popüler Saatler" description="Gün ve saate göre görüntülenme yoğunluğu">
      {hepsiSifir ? (
        <PanelEmptyState icon={<NoDataIcon />} title="Henüz veri yok" />
      ) : (
        <>
          <div className="overflow-x-auto">
            <table className="w-full text-[11px]">
              <thead>
                <tr>
                  <th className="w-[60px] pb-2 text-left font-[700] text-muted" />
                  {['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((d) => (
                    <th key={d} className="pb-2 text-center font-[800] text-textStrong/80">{d}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {satirlar.map((row) => (
                  <tr key={row.bucketLabel}>
                    <td className="whitespace-nowrap py-1.5 pr-3 font-[700] text-textStrong/80">{row.bucketLabel}</td>
                    {row.counts.map((count, ci) => (
                      <td key={ci} className="px-1 py-1 text-center">
                        <div
                          className="mx-auto flex h-8 w-full min-w-[32px] items-center justify-center rounded-lg text-[10px] font-[900]"
                          style={{
                            background: heatColor(row.norms[ci]),
                            color: row.norms[ci] >= 50 ? '#fff' : 'var(--yd-color-primary)',
                            minWidth: 32,
                          }}
                        >
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
            <span className="text-[10px] font-[600] text-muted">Az</span>
            {[0.08, 0.24, 0.42, 0.6, 0.8, 1].map((o) => (
              <span key={o} className="h-3 flex-1 rounded" style={{ background: `rgba(127,29,29,${o})` }} />
            ))}
            <span className="text-[10px] font-[600] text-muted">Çok</span>
          </div>
        </>
      )}
    </PanelBolumKarti>
  );
}

// ── Eylemler kartı ─────────────────────────────────────────────────────────────
function EylemlerKarti({ eylemler }: { eylemler: EylemMetrigi[] }) {
  return (
    <PanelBolumKarti title="Eylemler" description="Dönem içindeki etkileşimler">
      <div className="flex flex-col gap-3">
        {eylemler.map((e) => {
          const meta = EYLEM_META[e.key];
          const p = pct(e.value, e.prev);
          const up = p !== null && p >= 0;
          return (
            <div key={e.key} className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-black/[0.04]" style={{ color: meta.renk }}>
                  {meta.icon}
                </span>
                <span className="text-[12px] font-[700] text-textStrong/80">{meta.label}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-[900] text-textStrong">{fmt(e.value)}</span>
                {p !== null && (
                  <span className={`text-[10px] font-[800] ${up ? 'text-[color:var(--yd-color-success)]' : 'text-[color:var(--yd-color-danger)]'}`}>
                    {up ? '↑' : '↓'} %{Math.abs(p)}
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </PanelBolumKarti>
  );
}

// ── Görüntülenme grafiği tooltip'i ─────────────────────────────────────────────
function CizgiTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-border bg-card p-3 text-[12px] shadow-lg">
      <p className="mb-1.5 font-[800] text-textStrong">{label}</p>
      {payload.map((p: any) => (
        <p key={p.name} className="font-[600]" style={{ color: p.color }}>
          {p.name === 'guncel' ? 'Bu Dönem' : 'Önceki Dönem'}: {fmt(p.value)}
        </p>
      ))}
    </div>
  );
}

// ── Günlük Trend grafiği — sahip'e özgü (SVG inline) ──────────────────────────
function TrendGrafik({ gunler }: { gunler: { label: string; menu: number; qr: number }[] }) {
  const W = 600;
  const H = 160;
  const pad = { l: 40, r: 16, t: 16, b: 32 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;

  const maxVal = Math.max(...gunler.flatMap(g => [g.menu, g.qr]), 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;
  const stepX = innerW / Math.max(gunler.length - 1, 1);

  const menuPath = gunler.map((g, i) =>
    `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(g.menu)}`
  ).join(' ');
  const qrPath = gunler.map((g, i) =>
    `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(g.qr)}`
  ).join(' ');

  return (
    <div className="overflow-x-auto">
      <div className="flex items-center gap-4 mb-2">
        <span className="flex items-center gap-1.5 text-xs font-[700] text-primary">
          <span className="h-2 w-4 rounded-full bg-primary inline-block" /> Menü Görüntüleme
        </span>
        <span className="flex items-center gap-1.5 text-xs font-[700] text-info">
          <span className="h-2 w-4 rounded-full bg-info inline-block" /> QR Tarama
        </span>
      </div>
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full max-w-2xl" style={{ minWidth: 320 }}>
        {/* Grid lines */}
        {[0, 0.25, 0.5, 0.75, 1].map(t => (
          <line key={t} x1={pad.l} y1={pad.t + scaleY(maxVal * t)} x2={pad.l + innerW} y2={pad.t + scaleY(maxVal * t)}
            stroke="var(--yd-color-border)" strokeWidth="1" strokeDasharray="4 4" />
        ))}
        {/* Lines */}
        <path d={menuPath} fill="none" stroke="var(--yd-color-primary)" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        <path d={qrPath} fill="none" stroke="var(--yd-color-info)" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        {/* Dots */}
        {gunler.map((g, i) => (
          <g key={i}>
            <circle cx={pad.l + i * stepX} cy={pad.t + scaleY(g.menu)} r="3" fill="var(--yd-color-primary)" />
            <circle cx={pad.l + i * stepX} cy={pad.t + scaleY(g.qr)} r="3" fill="var(--yd-color-info)" />
          </g>
        ))}
        {/* X axis labels */}
        {gunler.filter((_, i) => i % Math.max(1, Math.floor(gunler.length / 7)) === 0 || i === gunler.length - 1).map((g, fi, arr) => {
          const i = gunler.indexOf(g);
          return (
            <text key={fi} x={pad.l + i * stepX} y={H - 6} textAnchor="middle"
              fontSize="10" fill="var(--yd-color-muted)" fontFamily="inherit">
              {g.label}
            </text>
          );
        })}
      </svg>
    </div>
  );
}

// ── Saatlik Dağılım grafiği — sahip'e özgü ─────────────────────────────────────
function SaatlikDagilimGrafik({ saatler }: { saatler: { saat: string; sayi: number }[] }) {
  const maxVal = Math.max(...saatler.map(s => s.sayi), 1);

  return (
    <div>
      <p className="mb-2 text-xs text-muted">Yoğun saatler — tüm etkinlikler</p>
      <div className="flex items-end gap-0.5 h-24">
        {saatler.map(({ saat, sayi }) => {
          const p = (sayi / maxVal) * 100;
          const isHigh = p > 70;
          return (
            <div
              key={saat}
              className="relative flex-1 group cursor-default"
              style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}
              title={`${saat}: ${sayi} etkinlik`}
            >
              <div
                className={`rounded-t transition-all ${isHigh ? 'bg-primary' : 'bg-primary/40'}`}
                style={{ height: `${Math.max(p, 2)}%` }}
              />
            </div>
          );
        })}
      </div>
      <div className="flex justify-between mt-1">
        <span className="text-[10px] text-muted">0:00</span>
        <span className="text-[10px] text-muted">6:00</span>
        <span className="text-[10px] text-muted">12:00</span>
        <span className="text-[10px] text-muted">18:00</span>
        <span className="text-[10px] text-muted">23:00</span>
      </div>
    </div>
  );
}

// ── İkonlar ─────────────────────────────────────────────────────────────────────
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
function WhatsappIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" /></svg>;
}
function BuildingIcon() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>;
}
function DownloadIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
function NoDataIcon() {
  return <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" /></svg>;
}
