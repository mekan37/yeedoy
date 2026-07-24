import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getYogunSaatler } from '@/src/lib/veri/owner/mesgul-saatler';
import {
  buildHourBucketHeatmap,
  findBestDay,
  findBestHourRange,
  reservationStatusBreakdown,
} from '@/src/lib/veri/owner/analitik-yardimcilari';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { AnalitikIstemcisi } from './analitik-istemcisi';
import type { GunlukNokta, TrafikKaynagi, EylemMetrigi } from './analitik-istemcisi';

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

// Gerçek `source` değerleri → görünen etiketler
const KAYNAK_ETIKETLERI: Record<string, string> = {
  web_next_public: 'Doğrudan',
  menu_page:       'Menü',
  discover:        'Keşfet',
  discover_search: 'Keşfet',
  discover_list:   'Keşfet',
};
const KAYNAK_RENKLERI = [
  'var(--yd-color-primary)',
  'var(--yd-color-info)',
  'var(--yd-color-success)',
  'var(--yd-color-warning)',
  'var(--yd-color-danger)',
];

const GORUNTULENME_OLAYLARI = ['menu_view', 'business_impression', 'menu_link_opened', 'business_page_view'];

// ─── Sayfa ────────────────────────────────────────────────────────────────────

interface Props {
  searchParams: Promise<Record<string, string | undefined>>;
}

export default async function OwnerAnalyticsPage({ searchParams }: Props) {
  const params = await searchParams;
  const aralik = parseAralik(params.aralik);
  const etiket = aralikEtiket[aralik];
  const gunSayisi = aralikGun[aralik];

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b: { id: string }) => b.id);

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Sahip" title="Analitik" description="İşletme performans analitiği" />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState
            icon={<BuildingIcon />}
            title="İşletme bulunamadı"
            description="İstatistikleri görmek için önce bir işletme ekleyin."
          />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const now       = Date.now();
  const since     = new Date(now - gunSayisi * 86400000).toISOString();
  const sincePrev = new Date(now - 2 * gunSayisi * 86400000).toISOString();

  // Yoğun saatler: ilk işletme için RPC çağrısı (tek business_id alıyor)
  const yogunSaatler = await getYogunSaatler(businessIds[0]);

  const sb = supabase as any;

  // ── Paralel sorgular ────────────────────────────────────────────────────────
  const [
    viewsCurr,    viewsPrev_,
    favCurr,      favPrev_,
    profileCurr,  profilePrev_,
    phoneCurr,    phonePrev_,
    dirCurr,      dirPrev_,
    menuViewCurr, menuViewPrev_,
    qrCurr,       qrPrev_,
    whatsappCurr, whatsappPrev_,
    shareCurr,    sharePrev_,
    resCurr,      resPrev_,
    resStatusRows,
    // Isı haritası + ziyaretçi kaynakları + günlük trend için ham olay satırları
    rawEvents,
  ] = await Promise.all([
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', GORUNTULENME_OLAYLARI).gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', GORUNTULENME_OLAYLARI)
      .gte('created_at', sincePrev).lt('created_at', since),

    sb.from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', since),
    sb.from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', sincePrev).lt('created_at', since),

    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_page_view').gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_page_view')
      .gte('created_at', sincePrev).lt('created_at', since),

    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_phone_click').gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_phone_click')
      .gte('created_at', sincePrev).lt('created_at', since),

    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_directions_click').gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_directions_click')
      .gte('created_at', sincePrev).lt('created_at', since),

    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_view').gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_view')
      .gte('created_at', sincePrev).lt('created_at', since),

    // NOT: gerçek tracking pipeline (src/lib/analytics.ts → log_event_v1) QR taramasını
    // 'qr_scanned' olarak kaydediyor ('qr_scan' değil) — bkz. src/lib/analytics.ts.
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'qr_scanned').gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'qr_scanned')
      .gte('created_at', sincePrev).lt('created_at', since),

    // NOT: gerçek event adı 'business_whatsapp_click' ('whatsapp_click' değil).
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_whatsapp_click').gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'business_whatsapp_click')
      .gte('created_at', sincePrev).lt('created_at', since),

    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_shared').gte('created_at', since),
    sb.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'menu_shared')
      .gte('created_at', sincePrev).lt('created_at', since),

    sb.from('reservations').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', since),
    sb.from('reservations').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', sincePrev).lt('created_at', since),

    sb.from('reservations').select('status')
      .in('business_id', businessIds).gte('created_at', since).limit(10000),

    sb.from('analytics_events')
      .select('created_at, event_name, source')
      .in('business_id', businessIds)
      .gte('created_at', sincePrev)
      .limit(100000),
  ]);

  type HamOlay = { created_at: string; event_name: string; source: string | null };
  const tumHamOlaylar: HamOlay[] = rawEvents.data ?? [];

  // Güncel dönem / önceki dönem ayrımı
  const simdiMs = now - gunSayisi * 86400000;
  const guncelOlaylar  = tumHamOlaylar.filter((e) => new Date(e.created_at).getTime() >= simdiMs);
  const oncekiOlaylar  = tumHamOlaylar.filter((e) => new Date(e.created_at).getTime() <  simdiMs);

  // ── Görüntülenme grafiği: bu dönem vs önceki dönem ──────────────────────────
  const GORUNTULENME_SET = new Set(GORUNTULENME_OLAYLARI);
  const guncelGunMap: Record<string, number> = {};
  const oncekiGunMap: Record<string, number> = {};

  for (const e of guncelOlaylar) {
    if (GORUNTULENME_SET.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      guncelGunMap[k] = (guncelGunMap[k] ?? 0) + 1;
    }
  }
  for (const e of oncekiOlaylar) {
    if (GORUNTULENME_SET.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      oncekiGunMap[k] = (oncekiGunMap[k] ?? 0) + 1;
    }
  }

  const goruntulenmeGunluk: GunlukNokta[] = Array.from({ length: gunSayisi }, (_, i) => {
    const d          = new Date(now - (gunSayisi - 1 - i) * 86400000);
    const guncelKey  = d.toISOString().split('T')[0];
    const oncekiKey  = new Date(d.getTime() - gunSayisi * 86400000).toISOString().split('T')[0];
    return {
      label:   d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' }),
      guncel:  guncelGunMap[guncelKey] ?? 0,
      onceki:  oncekiGunMap[oncekiKey] ?? 0,
    };
  });

  // ── Ziyaretçi kaynakları (bu dönem) ─────────────────────────────────────────
  const kaynakMap: Record<string, number> = {};
  for (const e of guncelOlaylar) {
    const etik = KAYNAK_ETIKETLERI[e.source ?? ''] ?? 'Diğer';
    kaynakMap[etik] = (kaynakMap[etik] ?? 0) + 1;
  }
  const kaynakToplam = Object.values(kaynakMap).reduce((a, b) => a + b, 0);
  const trafikKaynaklari: TrafikKaynagi[] = Object.entries(kaynakMap)
    .sort((a, b) => b[1] - a[1])
    .map(([name, count], i) => ({
      name,
      count,
      value: kaynakToplam > 0 ? Math.round((count / kaynakToplam) * 1000) / 10 : 0,
      color: KAYNAK_RENKLERI[Math.min(i, KAYNAK_RENKLERI.length - 1)],
    }));

  // ── Popüler saatler: gün × 4 saatlik blok ısı haritası (Europe/Istanbul) ────
  const isiHaritasi = buildHourBucketHeatmap(
    guncelOlaylar.filter((e) => GORUNTULENME_SET.has(e.event_name)),
  );

  // ── Eylemler listesi ─────────────────────────────────────────────────────────
  const eylemler: EylemMetrigi[] = [
    { key: 'menuViews',    value: menuViewCurr.count ?? 0, prev: menuViewPrev_.count ?? 0 },
    { key: 'qrScans',      value: qrCurr.count ?? 0,       prev: qrPrev_.count ?? 0 },
    { key: 'whatsapp',     value: whatsappCurr.count ?? 0, prev: whatsappPrev_.count ?? 0 },
    { key: 'menuShares',   value: shareCurr.count ?? 0,    prev: sharePrev_.count ?? 0 },
    { key: 'reservations', value: resCurr.count ?? 0,      prev: resPrev_.count ?? 0 },
  ];

  const rezervasyonDurumu = reservationStatusBreakdown(
    (resStatusRows.data ?? []) as { status: string }[],
  );

  const enIyiGun = findBestDay(goruntulenmeGunluk.map((g) => ({ label: g.label, current: g.guncel })));
  const enYogunSaatAraligi = findBestHourRange(isiHaritasi);
  const toplamEtkilesim =
    (viewsCurr.count ?? 0) + (favCurr.count ?? 0) + (phoneCurr.count ?? 0) + (dirCurr.count ?? 0);

  // ── Sahip'e özgü: günlük menü/QR trendi + saatlik dağılım ────────────────────
  const gunlukMenu: Record<string, number> = {};
  const gunlukQr: Record<string, number> = {};
  const saatlikDagilim: Record<string, number> = {};

  for (const o of guncelOlaylar) {
    const d = new Date(o.created_at);
    const gun = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    const saat = String(d.getHours()).padStart(2,'0');
    if (o.event_name === 'menu_view') gunlukMenu[gun] = (gunlukMenu[gun] ?? 0) + 1;
    if (o.event_name === 'qr_scanned') gunlukQr[gun] = (gunlukQr[gun] ?? 0) + 1;
    saatlikDagilim[saat] = (saatlikDagilim[saat] ?? 0) + 1;
  }

  // Son N günün listesi
  const gunlukTrend: { label: string; menu: number; qr: number }[] = [];
  for (let i = Math.min(gunSayisi - 1, 13); i >= 0; i--) {
    const d = new Date(now - i * 86400000);
    const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    const label = i === 0 ? 'Bugün' : `${d.getDate()}/${d.getMonth()+1}`;
    gunlukTrend.push({ label, menu: gunlukMenu[key] ?? 0, qr: gunlukQr[key] ?? 0 });
  }

  // Saatlik dağılım 0-23
  const saatlikVeri: { saat: string; sayi: number }[] = [];
  for (let h = 0; h < 24; h++) {
    const k = String(h).padStart(2, '0');
    saatlikVeri.push({ saat: `${h}:00`, sayi: saatlikDagilim[k] ?? 0 });
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
        title="Analitik"
        description={`İşletme performans analitiği — ${etiket.toLowerCase()}`}
        actions={<AralikSecici aktif={aralik} />}
      />
      <AnalitikIstemcisi
        etiket={etiket}
        isletmeSayisi={businessIds.length}
        goruntulenme={viewsCurr.count ?? 0}                goruntulenmeOnceki={viewsPrev_.count ?? 0}
        profilZiyaretleri={profileCurr.count ?? 0}          profilZiyaretleriOnceki={profilePrev_.count ?? 0}
        telefonAramalari={phoneCurr.count ?? 0}              telefonAramalariOnceki={phonePrev_.count ?? 0}
        yolTarifi={dirCurr.count ?? 0}                       yolTarifiOnceki={dirPrev_.count ?? 0}
        favoriler={favCurr.count ?? 0}                       favorilerOnceki={favPrev_.count ?? 0}
        goruntulenmeGunluk={goruntulenmeGunluk}
        trafikKaynaklari={trafikKaynaklari}
        rezervasyonDurumu={rezervasyonDurumu}
        isiHaritasi={isiHaritasi}
        enIyiGun={enIyiGun}
        enYogunSaatAraligi={enYogunSaatAraligi}
        eylemler={eylemler}
        toplamEtkilesim={toplamEtkilesim}
        gunlukTrend={gunlukTrend}
        saatlikDagilim={saatlikVeri}
        olayVarMi={guncelOlaylar.length > 0}
        yogunSaatler={yogunSaatler}
      />
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
              'min-h-[32px] rounded-lg px-3 text-xs font-bold transition-all duration-150',
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

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" />
    </svg>
  );
}
