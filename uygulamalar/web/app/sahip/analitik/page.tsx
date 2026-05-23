import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Analitik | Sahip Paneli',
  robots: { index: false, follow: false },
};

// ─── Aralık yardımcısı ────────────────────────────────────────────────────────

type Aralik = '7g' | '30g' | '90g';

const aralikGun: Record<Aralik, number> = { '7g': 7, '30g': 30, '90g': 90 };
const aralikEtiket: Record<Aralik, string> = { '7g': 'Son 7 gün', '30g': 'Son 30 gün', '90g': 'Son 90 gün' };

function parseAralik(raw: string | undefined): Aralik {
  if (raw === '7g' || raw === '90g') return raw;
  return '30g';
}

// ─── Sayfa ────────────────────────────────────────────────────────────────────

interface Props {
  searchParams: Promise<Record<string, string | undefined>>;
}

export default async function OwnerAnalyticsPage({ searchParams }: Props) {
  const params = await searchParams;
  const aralik = parseAralik(params.aralik);
  const etiket = aralikEtiket[aralik];

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b: { id: string }) => b.id);

  const since = new Date(Date.now() - aralikGun[aralik] * 24 * 60 * 60 * 1000).toISOString();

  const [menuViewsRes, qrScansRes, whatsappRes, siparisRes, gunlukOlaylar] = await Promise.all([
    businessIds.length > 0
      ? supabase
          .from('analytics_events')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .eq('event_name', 'menu_view')
          .gte('created_at', since)
      : Promise.resolve({ count: 0 }),
    businessIds.length > 0
      ? supabase
          .from('analytics_events')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .eq('event_name', 'qr_scan')
          .gte('created_at', since)
      : Promise.resolve({ count: 0 }),
    businessIds.length > 0
      ? supabase
          .from('analytics_events')
          .select('id', { count: 'exact', head: true })
          .in('business_id', businessIds)
          .eq('event_name', 'whatsapp_click')
          .gte('created_at', since)
      : Promise.resolve({ count: 0 }),
    // Sipariş geliri — son aralik
    businessIds.length > 0
      ? (supabase as any)
          .from('table_order_items')
          .select('price, quantity, created_at')
          .in('business_id', businessIds)
          .gte('created_at', since)
      : Promise.resolve({ data: [] }),
    // Günlük event sayıları (trend grafiği için)
    businessIds.length > 0
      ? (supabase as any)
          .from('analytics_events')
          .select('created_at, event_name')
          .in('business_id', businessIds)
          .gte('created_at', since)
          .limit(5000)
      : Promise.resolve({ data: [] }),
  ]);

  // Sipariş geliri hesapla
  const siparisItems = (siparisRes.data ?? []) as Array<{ price: number; quantity: number; created_at: string }>;
  const toplamGelir = siparisItems.reduce((s, r) => s + (r.price ?? 0) * (r.quantity ?? 1), 0);

  // Günlük trend verisi
  const olaylar = (gunlukOlaylar.data ?? []) as Array<{ created_at: string; event_name: string }>;
  const gunSayisi = aralikGun[aralik];

  const gunlukMenu: Record<string, number> = {};
  const gunlukQr: Record<string, number> = {};
  const saatlikDagilim: Record<string, number> = {};

  for (const o of olaylar) {
    const d = new Date(o.created_at);
    const gun = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    const saat = String(d.getHours()).padStart(2,'0');
    if (o.event_name === 'menu_view') gunlukMenu[gun] = (gunlukMenu[gun] ?? 0) + 1;
    if (o.event_name === 'qr_scan') gunlukQr[gun] = (gunlukQr[gun] ?? 0) + 1;
    saatlikDagilim[saat] = (saatlikDagilim[saat] ?? 0) + 1;
  }

  // Son N günün listesi
  const gunListesi: { label: string; menu: number; qr: number }[] = [];
  for (let i = Math.min(gunSayisi - 1, 13); i >= 0; i--) {
    const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
    const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    const label = i === 0 ? 'Bugün' : `${d.getDate()}/${d.getMonth()+1}`;
    gunListesi.push({ label, menu: gunlukMenu[key] ?? 0, qr: gunlukQr[key] ?? 0 });
  }

  // Saatlik dağılım 0-23
  const saatlerVeri: { saat: string; sayi: number }[] = [];
  for (let h = 0; h < 24; h++) {
    const k = String(h).padStart(2, '0');
    saatlerVeri.push({ saat: `${h}:00`, sayi: saatlikDagilim[k] ?? 0 });
  }

  const metrics = [
    { title: 'Menü Görüntüleme',  value: menuViewsRes.count ?? 0,  subtitle: etiket, icon: <EyeIcon /> },
    { title: 'QR Tarama',         value: qrScansRes.count ?? 0,    subtitle: etiket, icon: <QrIcon /> },
    { title: 'WhatsApp Tıklama',  value: whatsappRes.count ?? 0,   subtitle: etiket, icon: <PhoneIcon /> },
    { title: 'Toplam Gelir',      value: `₺${toplamGelir.toFixed(0)}`, subtitle: etiket, icon: <TLIcon /> },
  ];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Analitik"
        description={`Performans özeti — ${etiket.toLowerCase()}`}
        actions={<AralikSecici aktif={aralik} />}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {metrics.map((m) => (
            <MetricCard
              key={m.title}
              title={m.title}
              value={m.value.toLocaleString('tr-TR')}
              subtitle={m.subtitle}
              icon={m.icon}
            />
          ))}
        </div>

        {/* Günlük trend grafiği */}
        {gunListesi.length > 0 && (
          <PanelBolumKarti title="Günlük Trend" className="mt-6">
            <TrendGrafik gunler={gunListesi} />
          </PanelBolumKarti>
        )}

        {/* Saatlik dağılım */}
        {olaylar.length > 0 && (
          <PanelBolumKarti title="Saatlik Dağılım" className="mt-6">
            <SaatlikDagilimGrafik saatler={saatlerVeri} />
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

// ─── Zaman aralığı seçici (link-based, permalink uyumlu) ─────────────────────

function AralikSecici({ aktif }: { aktif: Aralik }) {
  const secenekler: { aralik: Aralik; etiket: string }[] = [
    { aralik: '7g',  etiket: '7 gün' },
    { aralik: '30g', etiket: '30 gün' },
    { aralik: '90g', etiket: '90 gün' },
  ];

  return (
    <div className="flex items-center gap-1 rounded-xl border border-border bg-cardAlt p-1">
      {secenekler.map(({ aralik, etiket }) => {
        const isActive = aralik === aktif;
        return (
          <Link
            key={aralik}
            href={`/sahip/analitik?aralik=${aralik}`}
            aria-current={isActive ? 'page' : undefined}
            className={[
              'min-h-[32px] rounded-lg px-3 text-xs font-[700] transition-all duration-150',
              isActive
                ? 'btn-primary text-white'
                : 'text-muted hover:text-textStrong',
            ].join(' ')}
          >
            {etiket}
          </Link>
        );
      })}
    </div>
  );
}

// ─── İkonlar ─────────────────────────────────────────────────────────────────

function EyeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
  );
}

function PhoneIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12.7a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.61 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6.18 6.18l.98-.98a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" />
    </svg>
  );
}

function TLIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="7" y1="5" x2="17" y2="5" /><line x1="7" y1="12" x2="14" y2="12" /><path d="M9 5v14" /><path d="M14 12v4a2 2 0 0 0 2 2h1" />
    </svg>
  );
}

// ─── Trend Grafik (SVG inline) ────────────────────────────────────────────────

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

// ─── Saatlik Dağılım Grafik ───────────────────────────────────────────────────

function SaatlikDagilimGrafik({ saatler }: { saatler: { saat: string; sayi: number }[] }) {
  const maxVal = Math.max(...saatler.map(s => s.sayi), 1);
  const barWidth = Math.floor(100 / saatler.length);

  return (
    <div>
      <p className="mb-2 text-xs text-muted">Yoğun saatler — tüm etkinlikler</p>
      <div className="flex items-end gap-0.5 h-24">
        {saatler.map(({ saat, sayi }) => {
          const pct = (sayi / maxVal) * 100;
          const isHigh = pct > 70;
          return (
            <div
              key={saat}
              className="relative flex-1 group cursor-default"
              style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}
              title={`${saat}: ${sayi} etkinlik`}
            >
              <div
                className={`rounded-t transition-all ${isHigh ? 'bg-primary' : 'bg-primary/40'}`}
                style={{ height: `${Math.max(pct, 2)}%` }}
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
