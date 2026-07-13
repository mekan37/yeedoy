'use client';

import {
  ResponsiveContainer,
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  BarChart, Bar,
  PieChart, Pie, Cell,
} from 'recharts';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';

// ── Tipler (page.tsx bu tipleri kullanır) ────────────────────────────────────
export type GunlukNokta = { label: string; guncel: number; onceki: number };
export type TrafikKaynagi = { ad: string; deger: number; renk: string };
export type IsiHaritasiSatiri = { metrik: string; sayilar: number[]; normlar: number[] };
export type SaatlikNokta = { saat: string; sayi: number };
export type MenuQrGunu = { label: string; menu: number; qr: number };

export interface AnalitikIstemcisiProps {
  etiket: string;
  gorunumler: number;         gorunumlerOnceki: number;
  favoriler: number;          favorilerOnceki: number;
  yorumlar: number;           yorumlarOnceki: number;
  aramalar: number;           aramalarOnceki: number;
  qrTaramalari: number;       qrTaramalariOnceki: number;
  whatsappTiklamalari: number; whatsappTiklamalariOnceki: number;
  isletmeSayisi: number;
  gunlukTrend: GunlukNokta[];
  trafikKaynaklari: TrafikKaynagi[];
  isiHaritasi: IsiHaritasiSatiri[];
  saatlikGoruntuleme: SaatlikNokta[];
  menuQrGunleri: MenuQrGunu[];
  saatlikDagilim: SaatlikNokta[];
}

// ── Yardımcılar ────────────────────────────────────────────────────────────────
function pct(cur: number, prev: number): number | null {
  if (prev === 0) return null;
  return Math.round(((cur - prev) / prev) * 100);
}
function fmt(n: number) { return n.toLocaleString('tr-TR'); }
function isiRengi(v: number) {
  if (v >= 90) return 'var(--yd-color-primary)';
  if (v >= 70) return 'var(--yd-color-danger)';
  if (v >= 50) return 'var(--yd-color-primary-strong)';
  if (v >= 30) return '#f87171';
  if (v >= 10) return '#fca5a5';
  return '#fef2f2';
}

// ── Donut kartı (boş durumu yönetir) ───────────────────────────────────────────
function DonutKarti({ title, subtitle, data }: {
  title: string; subtitle?: string; data: TrafikKaynagi[];
}) {
  if (data.length === 0) {
    return (
      <PanelBolumKarti title={title} description={subtitle}>
        <div className="flex flex-col items-center justify-center py-14 text-center">
          <VeriYokIkonu />
          <p className="mt-3 text-[13px] font-[700] text-muted">Henüz veri yok</p>
        </div>
      </PanelBolumKarti>
    );
  }
  return (
    <PanelBolumKarti title={title} description={subtitle}>
      <div style={{ height: 180 }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={data} cx="50%" cy="50%" innerRadius={52} outerRadius={80} paddingAngle={2} dataKey="deger">
              {data.map((d) => <Cell key={d.ad} fill={d.renk} />)}
            </Pie>
            <Tooltip formatter={(v) => [`${v}%`, '']} />
          </PieChart>
        </ResponsiveContainer>
      </div>
      <div className="mt-3 flex flex-col gap-1.5">
        {data.map((d) => (
          <div key={d.ad} className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: d.renk }} />
              <span className="text-[12px] font-[600] text-text">{d.ad}</span>
            </div>
            <span className="text-[12px] font-[800] text-textStrong">{d.deger}%</span>
          </div>
        ))}
      </div>
    </PanelBolumKarti>
  );
}

// ── Özel tooltip'ler ────────────────────────────────────────────────────────────
function CizgiTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-border bg-card p-3 shadow-lg text-[12px]">
      <p className="mb-1.5 font-[800] text-textStrong">{label}</p>
      {payload.map((p: any) => (
        <p key={p.name} className="font-[600]" style={{ color: p.color }}>
          {p.name === 'guncel' ? 'Bu Dönem' : 'Önceki Dönem'}: {fmt(p.value)}
        </p>
      ))}
    </div>
  );
}
function BarTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-xl border border-border bg-card p-3 shadow-lg text-[12px]">
      <p className="font-[800] text-textStrong">{label}:00</p>
      <p className="font-[600]" style={{ color: 'var(--yd-color-primary-strong)' }}>{fmt(payload[0].value)} görüntülenme</p>
    </div>
  );
}

// ── Ana bileşen ─────────────────────────────────────────────────────────────────
export function AnalitikIstemcisi({
  etiket,
  gorunumler, gorunumlerOnceki,
  favoriler, favorilerOnceki,
  yorumlar, yorumlarOnceki,
  aramalar, aramalarOnceki,
  qrTaramalari, qrTaramalariOnceki,
  whatsappTiklamalari, whatsappTiklamalariOnceki,
  isletmeSayisi,
  gunlukTrend,
  trafikKaynaklari,
  isiHaritasi,
  saatlikGoruntuleme,
  menuQrGunleri,
  saatlikDagilim,
}: AnalitikIstemcisiProps) {
  const xAralik = gunlukTrend.length > 14 ? Math.floor(gunlukTrend.length / 6) - 1 : 0;

  const metrikler: { title: string; value: number; prev?: number; icon: React.ReactNode }[] = [
    { title: 'Görüntülenme', value: gorunumler, prev: gorunumlerOnceki, icon: <GozIkonu /> },
    { title: 'Favori', value: favoriler, prev: favorilerOnceki, icon: <KalpIkonu /> },
    { title: 'Yorum', value: yorumlar, prev: yorumlarOnceki, icon: <YildizIkonu /> },
    { title: 'Arama Görünümü', value: aramalar, prev: aramalarOnceki, icon: <AramaIkonu /> },
    { title: 'QR Tarama', value: qrTaramalari, prev: qrTaramalariOnceki, icon: <QrIkonu /> },
    { title: 'WhatsApp Tıklama', value: whatsappTiklamalari, prev: whatsappTiklamalariOnceki, icon: <TelefonIkonu /> },
    { title: 'İşletme Sayısı', value: isletmeSayisi, icon: <BinaIkonu /> },
  ];

  return (
    <div className="flex flex-col gap-5">
      <span className="text-[12px] font-[600] text-muted">Önceki {aralikSayi(etiket)} ile karşılaştırma</span>

      {/* KPI satırı */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
        {metrikler.map((m) => {
          const p = m.prev !== undefined ? pct(m.value, m.prev) : null;
          return (
            <MetricCard
              key={m.title}
              title={m.title}
              value={fmt(m.value)}
              subtitle={etiket}
              icon={m.icon}
              trend={p !== null ? { value: p } : undefined}
            />
          );
        })}
      </div>

      {/* Görüntülenme trendi + trafik kaynakları */}
      <div className="grid gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <PanelBolumKarti title="Görüntülenme Grafiği" description={`${etiket} — günlük trend, önceki dönemle karşılaştırma`}>
            <div className="mb-3 flex items-center gap-4 text-[11px] font-[700]">
              <span className="flex items-center gap-1.5" style={{ color: 'var(--yd-color-primary-strong)' }}>
                <span className="h-0.5 w-5 rounded" style={{ background: 'var(--yd-color-primary-strong)' }} />Bu Dönem
              </span>
              <span className="flex items-center gap-1.5 text-muted">
                <span className="h-px w-5 rounded" style={{ borderTop: '1.5px dashed var(--yd-color-muted)', display: 'block' }} />Önceki Dönem
              </span>
            </div>
            <div style={{ height: 220 }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={gunlukTrend} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--yd-color-border)" />
                  <XAxis dataKey="label" tick={{ fontSize: 10, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
                    interval={xAralik} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
                    tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip content={<CizgiTooltip />} />
                  <Line type="monotone" dataKey="guncel" stroke="var(--yd-color-primary-strong)" strokeWidth={2}
                    dot={false} activeDot={{ r: 5, fill: 'var(--yd-color-primary-strong)' }} />
                  <Line type="monotone" dataKey="onceki" stroke="var(--yd-color-muted)" strokeWidth={1.5}
                    strokeDasharray="5 4" dot={false} activeDot={{ r: 4, fill: 'var(--yd-color-muted)' }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </PanelBolumKarti>
        </div>
        <DonutKarti title="Ziyaretçi Kaynakları" subtitle="Kaynak bazlı trafik dağılımı" data={trafikKaynaklari} />
      </div>

      {/* Menü/QR günlük trend (sahip'in mevcut SVG grafiği) */}
      {menuQrGunleri.length > 0 && (
        <PanelBolumKarti title="Günlük Menü & QR Trend">
          <MenuQrTrendGrafik gunler={menuQrGunleri} />
        </PanelBolumKarti>
      )}

      {/* Haftanın günü ısı haritası */}
      <PanelBolumKarti title="Günlere Göre Performans" description="Haftalık metrik yoğunluğu (gerçek veri)">
        {isiHaritasi.length === 0 || isiHaritasi.every((r) => r.sayilar.every((c) => c === 0)) ? (
          <div className="flex flex-col items-center justify-center py-10 text-center">
            <VeriYokIkonu />
            <p className="mt-3 text-[13px] font-[700] text-muted">Henüz veri yok</p>
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-[11px]">
                <thead>
                  <tr>
                    <th className="w-[110px] pb-2 text-left font-[700] text-muted" />
                    {['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((d) => (
                      <th key={d} className="pb-2 text-center font-[800] text-text">{d}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {isiHaritasi.map((row) => (
                    <tr key={row.metrik}>
                      <td className="py-1.5 pr-3 font-[700] text-text whitespace-nowrap">{row.metrik}</td>
                      {row.sayilar.map((sayi, ci) => (
                        <td key={ci} className="py-1 px-1 text-center">
                          <div className="mx-auto flex h-8 w-full min-w-[36px] items-center justify-center rounded-lg text-[10px] font-[900]"
                            style={{
                              background: isiRengi(row.normlar[ci]),
                              color: row.normlar[ci] >= 50 ? '#fff' : 'var(--yd-color-primary)',
                              minWidth: 36,
                            }}>
                            {sayi}
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
              {['#fef2f2', '#fca5a5', '#f87171', 'var(--yd-color-primary-strong)', 'var(--yd-color-danger)', 'var(--yd-color-primary)'].map((c) => (
                <span key={c} className="h-3 flex-1 rounded" style={{ background: c }} />
              ))}
              <span className="text-[10px] font-[600] text-muted">Çok</span>
            </div>
          </>
        )}
      </PanelBolumKarti>

      {/* Saatlik dağılımlar: görüntülenme bazlı (recharts) + tüm etkinlikler (sahip'in mevcut SVG grafiği) */}
      <div className="grid gap-4 xl:grid-cols-2">
        <PanelBolumKarti title="Görüntülenme Saatleri" description="Saatlik görüntülenme dağılımı (gerçek veri)">
          {saatlikGoruntuleme.every((h) => h.sayi === 0) ? (
            <div className="flex flex-col items-center justify-center py-10 text-center">
              <VeriYokIkonu />
              <p className="mt-3 text-[13px] font-[700] text-muted">Henüz veri yok</p>
            </div>
          ) : (
            <div style={{ height: 220 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={saatlikGoruntuleme.map((h) => ({ h: h.saat, v: h.sayi }))} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--yd-color-border)" vertical={false} />
                  <XAxis dataKey="h" tick={{ fontSize: 9, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
                    tickLine={false} axisLine={false} interval={2} />
                  <YAxis tick={{ fontSize: 10, fill: 'var(--yd-color-muted)', fontWeight: 600 }}
                    tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip content={<BarTooltip />} cursor={{ fill: 'var(--yd-color-card-alt)' }} />
                  <Bar dataKey="v" fill="var(--yd-color-primary-strong)" radius={[4, 4, 0, 0]} maxBarSize={18} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </PanelBolumKarti>

        <PanelBolumKarti title="Saatlik Dağılım" description="Yoğun saatler — tüm etkinlikler (gerçek veri)">
          <SaatlikDagilimGrafik saatler={saatlikDagilim} />
        </PanelBolumKarti>
      </div>

      {/* Özet çubuğu */}
      <div className="flex items-center justify-between rounded-2xl border border-border bg-card px-6 py-4 shadow-sm">
        <div>
          <p className="text-[14px] font-[900] text-textStrong">Performans Özeti</p>
          <p className="mt-0.5 text-[12px] font-[600] text-muted">
            {etiket} toplam: {fmt(gorunumler + favoriler + yorumlar + aramalar + qrTaramalari + whatsappTiklamalari)} etkileşim
          </p>
        </div>
        <button disabled title="Yakında aktif olacak"
          className="flex items-center gap-2 rounded-xl border border-border bg-bg px-4 py-2.5 text-[12px] font-[800] text-muted opacity-60 cursor-not-allowed">
          <IndirIkonu />
          Detaylı Raporu İndir
        </button>
      </div>
    </div>
  );
}

function aralikSayi(etiket: string): string {
  if (etiket.includes('7')) return '7 gün';
  if (etiket.includes('90')) return '90 gün';
  return '30 gün';
}

// ── Menü/QR Trend Grafiği (SVG, sahip'in mevcut bileşeni) ───────────────────────
function MenuQrTrendGrafik({ gunler }: { gunler: MenuQrGunu[] }) {
  const W = 600;
  const H = 160;
  const pad = { l: 40, r: 16, t: 16, b: 32 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;

  const maxVal = Math.max(...gunler.flatMap((g) => [g.menu, g.qr]), 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;
  const stepX = innerW / Math.max(gunler.length - 1, 1);

  const menuYol = gunler.map((g, i) =>
    `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(g.menu)}`
  ).join(' ');
  const qrYol = gunler.map((g, i) =>
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
        {[0, 0.25, 0.5, 0.75, 1].map((t) => (
          <line key={t} x1={pad.l} y1={pad.t + scaleY(maxVal * t)} x2={pad.l + innerW} y2={pad.t + scaleY(maxVal * t)}
            stroke="var(--yd-color-border)" strokeWidth="1" strokeDasharray="4 4" />
        ))}
        {/* Lines */}
        <path d={menuYol} fill="none" stroke="var(--yd-color-primary)" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        <path d={qrYol} fill="none" stroke="var(--yd-color-info)" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        {/* Dots */}
        {gunler.map((g, i) => (
          <g key={i}>
            <circle cx={pad.l + i * stepX} cy={pad.t + scaleY(g.menu)} r="3" fill="var(--yd-color-primary)" />
            <circle cx={pad.l + i * stepX} cy={pad.t + scaleY(g.qr)} r="3" fill="var(--yd-color-info)" />
          </g>
        ))}
        {/* X axis labels */}
        {gunler.filter((_, i) => i % Math.max(1, Math.floor(gunler.length / 7)) === 0 || i === gunler.length - 1).map((g, fi) => {
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

// ── Saatlik Dağılım Grafiği (SVG, sahip'in mevcut bileşeni) ─────────────────────
function SaatlikDagilimGrafik({ saatler }: { saatler: SaatlikNokta[] }) {
  const maxVal = Math.max(...saatler.map((s) => s.sayi), 1);

  return (
    <div>
      <p className="mb-2 text-xs text-muted">Yoğun saatler — tüm etkinlikler</p>
      <div className="flex items-end gap-0.5 h-24">
        {saatler.map(({ saat, sayi }) => {
          const oran = (sayi / maxVal) * 100;
          const yuksek = oran > 70;
          return (
            <div
              key={saat}
              className="relative flex-1 group cursor-default"
              style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}
              title={`${saat}: ${sayi} etkinlik`}
            >
              <div
                className={`rounded-t transition-all ${yuksek ? 'bg-primary' : 'bg-primary/40'}`}
                style={{ height: `${Math.max(oran, 2)}%` }}
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
function GozIkonu() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
function KalpIkonu() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" /></svg>;
}
function YildizIkonu() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>;
}
function AramaIkonu() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>;
}
function QrIkonu() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /></svg>;
}
function TelefonIkonu() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12.7a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.61 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6.18 6.18l.98-.98a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></svg>;
}
function BinaIkonu() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>;
}
function IndirIkonu() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
}
function VeriYokIkonu() {
  return <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--yd-color-border-strong)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" /></svg>;
}
