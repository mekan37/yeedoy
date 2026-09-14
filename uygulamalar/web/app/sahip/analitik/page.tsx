import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getYogunSaatler } from '@/src/lib/veri/owner/mesgul-saatler';
import {
  buildHourBucketHeatmapFromCounts,
  findBestDay,
  findBestHourRange,
  reservationStatusBreakdown,
} from '@/src/lib/veri/owner/analitik-yardimcilari';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { AnalitikIstemcisi } from './analitik-istemcisi';
import type { GunlukNokta, TrafikKaynagi, EylemMetrigi } from './analitik-istemcisi';
import { TarihAraligiSecici, type AralikSecenegi } from './tarih-araligi-secici';

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

function formatTarihAraligi(gunSayisi: number): string {
  const end = new Date();
  const start = new Date(end.getTime() - (gunSayisi - 1) * 86400000);
  const startStr = start.toLocaleDateString('tr-TR', { day: 'numeric', month: 'long' });
  const endStr = end.toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' });
  return `${startStr} - ${endStr}`;
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

type AnalyticsPipelineResult = {
  daily_views_current: { day: string; count: number }[];
  daily_views_previous: { day: string; count: number }[];
  source_breakdown: { source: string | null; count: number }[];
  heatmap_counts: { hour: number; weekday: number; count: number }[];
  daily_local_trend: { day: string; menu_views: number; qr_scans: number }[];
  hourly_distribution: { hour: number; count: number }[];
  has_current_events: boolean;
};

// ─── Sayfa ────────────────────────────────────────────────────────────────────

interface Props {
  searchParams: Promise<Record<string, string | undefined>>;
}

export default async function OwnerAnalyticsPage({ searchParams }: Props) {
  const params = await searchParams;
  const aralik = parseAralik(params.aralik);
  const etiket = aralikEtiket[aralik];
  const gunSayisiIstenen = aralikGun[aralik];

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase, user.id, 'id, name')
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

  const { data: planData } = (await (supabase).rpc('get_my_plan_v1', {
    p_business_id: businessIds[0],
  })) as { data: { features: Array<{ feature_key: string; limit_value: number | null }> } | null };

  const analitikLimit =
    planData?.features.find((f) => f.feature_key === 'analytics_range_days')?.limit_value ?? 7;

  // Kullanıcı URL'den ?aralik=90g gönderse bile (UI bypass), aşağıdaki tüm hesaplamalar
  // (since/sincePrev/goruntulenmeGunluk/vb.) bu clamp'lenmiş değeri kullanır.
  const gunSayisi = Math.min(gunSayisiIstenen, analitikLimit);

  const now       = Date.now();
  const since     = new Date(now - gunSayisi * 86400000).toISOString();
  const sincePrev = new Date(now - 2 * gunSayisi * 86400000).toISOString();

  // Yoğun saatler: ilk işletme için RPC çağrısı (tek business_id alıyor)
  const yogunSaatler = await getYogunSaatler(businessIds[0]);

  const sb = supabase;

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
    // Isı haritası + ziyaretçi kaynakları + günlük trend için DB-taraflı agregasyon
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

    // Önceden burada 100.000 satıra kadar ham event çekilip Node.js'te
    // 4 ayrı agregasyon yapılıyordu — limit aşımında sessiz veri kaybı
    // riski + gereksiz veri transferi vardı. owner_analytics_pipeline_v1
    // aynı hesaplamaları DB'de yapıp yalnızca önceden agregelenmiş
    // sonuçları (en fazla birkaç yüz satır) döndürüyor.
    sb.rpc('owner_analytics_pipeline_v1', {
      p_business_ids: businessIds,
      p_since_prev: sincePrev,
      p_since: since,
      p_view_events: GORUNTULENME_OLAYLARI,
    }) as unknown as Promise<{ data: AnalyticsPipelineResult | null }>,
  ]);

  const pipeline: AnalyticsPipelineResult = rawEvents.data ?? {
    daily_views_current: [], daily_views_previous: [], source_breakdown: [],
    heatmap_counts: [], daily_local_trend: [], hourly_distribution: [], has_current_events: false,
  };

  // ── Görüntülenme grafiği: bu dönem vs önceki dönem ──────────────────────────
  const guncelGunMap: Record<string, number> = {};
  for (const row of pipeline.daily_views_current) guncelGunMap[row.day] = row.count;
  const oncekiGunMap: Record<string, number> = {};
  for (const row of pipeline.daily_views_previous) oncekiGunMap[row.day] = row.count;

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
  for (const row of pipeline.source_breakdown) {
    const etik = KAYNAK_ETIKETLERI[row.source ?? ''] ?? 'Diğer';
    kaynakMap[etik] = (kaynakMap[etik] ?? 0) + row.count;
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
  const isiHaritasi = buildHourBucketHeatmapFromCounts(pipeline.heatmap_counts);

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
  // d.getFullYear()/getHours() gibi yerel-saat metodları server process'inin
  // çalıştığı saat dilimini kullanıyordu (Vercel'de UTC) — pipeline RPC'si de
  // aynı UTC gün/saat kesimini kullanıyor, davranış korunuyor.
  const gunlukMenu: Record<string, number> = {};
  const gunlukQr: Record<string, number> = {};
  for (const row of pipeline.daily_local_trend) {
    gunlukMenu[row.day] = row.menu_views;
    gunlukQr[row.day] = row.qr_scans;
  }
  const saatlikDagilim: Record<string, number> = {};
  for (const row of pipeline.hourly_distribution) {
    saatlikDagilim[String(row.hour).padStart(2, '0')] = row.count;
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

  const aralikSecenekleri: AralikSecenegi[] = [
    { aralik: '7g', etiket: 'Son 7 Gün', tarihAraligi: formatTarihAraligi(7), locked: analitikLimit < 7 },
    { aralik: '30g', etiket: 'Son 30 Gün', tarihAraligi: formatTarihAraligi(30), locked: analitikLimit < 30 },
    { aralik: '90g', etiket: 'Son 90 Gün', tarihAraligi: formatTarihAraligi(90), locked: analitikLimit < 90 },
  ];
  const aktifSecenek = aralikSecenekleri.find((s) => s.aralik === aralik)!;

  return (
    <div className="flex flex-col">
      <div className="flex flex-col gap-3 px-6 pt-6 pb-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-textStrong">İstatistikler</h1>
          <p className="mt-1 text-sm text-muted">
            İşletmenizin performansını detaylı olarak inceleyin ve gelişiminizi takip edin.
          </p>
        </div>
        <TarihAraligiSecici
          aktif={aralik}
          aktifTarihAraligi={aktifSecenek.tarihAraligi}
          secenekler={aralikSecenekleri}
          karsilastirmaEtiketi={`Önceki ${gunSayisi} Gün`}
        />
      </div>
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
        olayVarMi={pipeline.has_current_events}
        yogunSaatler={yogunSaatler}
      />
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
