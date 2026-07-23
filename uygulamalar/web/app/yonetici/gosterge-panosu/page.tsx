import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';

export const metadata: Metadata = {
  title: 'Genel Bakış | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminDashboardPage() {
  const supabase = await createSupabaseServerClient();

  const yediGunOnce = new Date(Date.now() - 7 * 86400000).toISOString();
  const otuzGunOnce = new Date(Date.now() - 30 * 86400000).toISOString();

  const [businessesRes, usersRes, menusRes, claimsRes, yeniIsletmeRes, yeniKullaniciRes, gunlukKayitlar] = await Promise.all([
    supabase.from('businesses').select('id', { count: 'exact', head: true }),
    supabase.from('user_profiles').select('user_id', { count: 'exact', head: true }),
    supabase.from('menus').select('id', { count: 'exact', head: true }),
    supabase.from('owner_claims').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    supabase.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', yediGunOnce),
    supabase.from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', yediGunOnce),
    // Son 30 günlük kullanıcı kayıt trendi
    (supabase as any)
      .from('user_profiles')
      .select('created_at')
      .gte('created_at', otuzGunOnce)
      .order('created_at', { ascending: true })
      .limit(1000),
  ]);

  // Günlük kayıt trendi
  const kayitlar = (gunlukKayitlar.data ?? []) as Array<{ created_at: string }>;
  const gunlukKayitSayisi: Record<string, number> = {};
  for (const k of kayitlar) {
    const d = new Date(k.created_at);
    const gun = `${d.getDate().toString().padStart(2,'0')}/${(d.getMonth()+1).toString().padStart(2,'0')}`;
    gunlukKayitSayisi[gun] = (gunlukKayitSayisi[gun] ?? 0) + 1;
  }
  const trendVerisi: { label: string; value: number }[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    const label = `${d.getDate().toString().padStart(2,'0')}/${(d.getMonth()+1).toString().padStart(2,'0')}`;
    trendVerisi.push({ label, value: gunlukKayitSayisi[label] ?? 0 });
  }

  const metrics = [
    { title: 'Toplam İşletme', value: businessesRes.count ?? 0, subtitle: `+${yeniIsletmeRes.count ?? 0} bu hafta`, icon: <BuildingIcon /> },
    { title: 'Toplam Kullanıcı', value: usersRes.count ?? 0, subtitle: `+${yeniKullaniciRes.count ?? 0} bu hafta`, icon: <UsersIcon /> },
    { title: 'Menüler', value: menusRes.count ?? 0, icon: <MenuIcon /> },
    { title: 'Bekleyen Talepler', value: claimsRes.count ?? 0, icon: <InboxIcon /> },
  ];

  // Hızlı eylem linkleri
  const hizliEylemler = [
    { href: '/yonetici/kuyruk', label: 'İnceleme Kuyruğu', count: claimsRes.count ?? 0, renk: 'text-warning' },
    { href: '/yonetici/fraud-tespiti', label: 'Fraud Tespiti', count: null, renk: 'text-danger' },
    { href: '/yonetici/feature-flags', label: 'Feature Flags', count: null, renk: 'text-info' },
    { href: '/yonetici/api-anahtarlari', label: 'API Anahtarları', count: null, renk: 'text-primary' },
  ];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Genel Bakış"
        description="Platform geneli özet istatistikler"
      />
      <PanelIcerikYuzeyi className="pt-6">
        {/* Ana metrikler */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {metrics.map((m) => (
            <MetricCard key={m.title} title={m.title} value={m.value} subtitle={m.subtitle} icon={m.icon} />
          ))}
        </div>

        <div className="mt-6 grid gap-6 lg:grid-cols-[1fr_280px]">
          {/* Kullanıcı kayıt trendi */}
          <PanelBolumKarti title="Kullanıcı Kayıt Trendi (Son 30 Gün)">
            <PlatformTrendGrafik veriler={trendVerisi} />
          </PanelBolumKarti>

          {/* Hızlı eylemler */}
          <PanelBolumKarti title="Hızlı Erişim">
            <div className="flex flex-col gap-2">
              {hizliEylemler.map(e => (
                <Link
                  key={e.href}
                  href={e.href}
                  className="flex items-center justify-between rounded-xl border border-border px-4 py-3 text-sm font-[700] text-textStrong hover:border-primary/30 hover:bg-cardAlt/50 transition-colors"
                >
                  <span>{e.label}</span>
                  {e.count !== null && e.count > 0 && (
                    <span className={`rounded-full bg-warning/15 px-2 py-0.5 text-[11px] font-[900] ${e.renk}`}>
                      {e.count}
                    </span>
                  )}
                  <span className="text-muted">→</span>
                </Link>
              ))}
            </div>
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

// ─── Platform Trend Grafik (SVG) ──────────────────────────────────────────────

function PlatformTrendGrafik({ veriler }: { veriler: { label: string; value: number }[] }) {
  const W = 560;
  const H = 120;
  const pad = { l: 36, r: 12, t: 12, b: 28 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;
  const maxVal = Math.max(...veriler.map(v => v.value), 1);
  const stepX = innerW / Math.max(veriler.length - 1, 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;

  const linePath = veriler.map((v, i) =>
    `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(v.value)}`
  ).join(' ');

  const areaPath = linePath +
    ` L${pad.l + (veriler.length - 1) * stepX},${pad.t + innerH}` +
    ` L${pad.l},${pad.t + innerH} Z`;

  const labelStep = Math.max(1, Math.floor(veriler.length / 6));

  return (
    <div className="overflow-x-auto">
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full" style={{ minWidth: 300 }}>
        <defs>
          <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--yd-color-primary)" stopOpacity="0.15" />
            <stop offset="100%" stopColor="var(--yd-color-primary)" stopOpacity="0" />
          </linearGradient>
        </defs>
        {[0, 0.5, 1].map(t => (
          <line key={t} x1={pad.l} y1={pad.t + scaleY(maxVal * t)} x2={pad.l + innerW} y2={pad.t + scaleY(maxVal * t)}
            stroke="var(--yd-color-border)" strokeWidth="1" strokeDasharray="4 4" />
        ))}
        <path d={areaPath} fill="url(#grad)" />
        <path d={linePath} fill="none" stroke="var(--yd-color-primary)" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
        {veriler.filter((_, i) => i % labelStep === 0 || i === veriler.length - 1).map((v, fi) => {
          const i = veriler.indexOf(v);
          return (
            <text key={fi} x={pad.l + i * stepX} y={H - 6} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">
              {v.label}
            </text>
          );
        })}
        {[0, maxVal].map((v, i) => (
          <text key={i} x={pad.l - 4} y={pad.t + scaleY(v) + 4} textAnchor="end" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">
            {v}
          </text>
        ))}
      </svg>
    </div>
  );
}

// ─── İkonlar ─────────────────────────────────────────────────────────────────

function BuildingIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>;
}
function UsersIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
function MenuIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>;
}
function InboxIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12" /><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" /></svg>;
}
