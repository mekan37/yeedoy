import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getYogunSaatler } from '@/src/lib/veri/owner/mesgul-saatler';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { YogunSaatlerKarti } from '@/src/ui/bilesenler/yogun-saatler-karti';
import { AnalitikIstemcisi } from './analitik-istemcisi';
import type {
  GunlukNokta,
  TrafikKaynagi,
  IsiHaritasiSatiri,
  SaatlikNokta,
  MenuQrGunu,
} from './analitik-istemcisi';

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
  menu_page: 'Menü',
  discover: 'Keşfet',
  discover_search: 'Keşfet',
  discover_list: 'Keşfet',
};
const KAYNAK_RENKLERI = [
  'var(--yd-color-primary)',
  'var(--yd-color-primary-strong)',
  'var(--yd-color-danger)',
  'var(--yd-color-warning)',
  'var(--yd-color-info)',
];

// JS getDay() → görünen sütun sırası: [Pzt,Sal,Çar,Per,Cum,Cmt,Paz] → getDay()=[1,2,3,4,5,6,0]
const GUN_SIRASI = [1, 2, 3, 4, 5, 6, 0];

function isiHaritasiSatiriOlustur(metrik: string, hamGunBazli: number[]): IsiHaritasiSatiri {
  const sayilar = GUN_SIRASI.map((d) => hamGunBazli[d] ?? 0);
  const max = Math.max(...sayilar, 1);
  const normlar = sayilar.map((c) => Math.round((c / max) * 100));
  return { metrik, sayilar, normlar };
}

const GORUNTULEME_OLAYLARI = ['menu_view', 'business_impression', 'menu_link_opened', 'business_page_view'];
const ARAMA_OLAYLARI = ['discovery_impression', 'business_impression'];

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
        <PanelSayfaBasligi eyebrow="Owner" title="Analitik" description="İşletme performans analitiği" />
        <PanelIcerikYuzeyi className="pt-6">
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border bg-bg py-20 text-center">
            <p className="text-base font-[800] text-textStrong">İşletme bulunamadı</p>
            <p className="mt-1 text-sm text-muted">İstatistikleri görmek için önce bir işletme ekleyin.</p>
          </div>
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const su = Date.now();
  const suankiBaslangic = new Date(su - gunSayisi * 86400000).toISOString();
  const oncekiBaslangic = new Date(su - 2 * gunSayisi * 86400000).toISOString();
  const suankiBaslangicMs = su - gunSayisi * 86400000;

  // ── Paralel sorgular ────────────────────────────────────────────────────────
  const [
    gorunumlerSimdi, gorunumlerOnceki,
    favorilerSimdi, favorilerOnceki,
    yorumlarSimdi, yorumlarOnceki,
    aramalarSimdi, aramalarOnceki,
    qrSimdi, qrOnceki,
    whatsappSimdi, whatsappOnceki,
    // Grafikler/kırılımlar için ham event satırları (bu dönem + önceki dönem)
    hamOlaylarRes,
    // Isı haritası için favori ve yorum satırları (bu dönem)
    favoriSatirlariRes,
    yorumSatirlariRes,
  ] = await Promise.all([
    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', GORUNTULEME_OLAYLARI).gte('created_at', suankiBaslangic),
    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', GORUNTULEME_OLAYLARI)
      .gte('created_at', oncekiBaslangic).lt('created_at', suankiBaslangic),

    supabase.from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', suankiBaslangic),
    supabase.from('favorites').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).gte('created_at', oncekiBaslangic).lt('created_at', suankiBaslangic),

    supabase.from('business_reviews').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('status', 'approved').gte('created_at', suankiBaslangic),
    supabase.from('business_reviews').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('status', 'approved')
      .gte('created_at', oncekiBaslangic).lt('created_at', suankiBaslangic),

    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', ARAMA_OLAYLARI).gte('created_at', suankiBaslangic),
    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).in('event_name', ARAMA_OLAYLARI)
      .gte('created_at', oncekiBaslangic).lt('created_at', suankiBaslangic),

    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'qr_scan').gte('created_at', suankiBaslangic),
    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'qr_scan')
      .gte('created_at', oncekiBaslangic).lt('created_at', suankiBaslangic),

    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'whatsapp_click').gte('created_at', suankiBaslangic),
    supabase.from('analytics_events').select('id', { count: 'exact', head: true })
      .in('business_id', businessIds).eq('event_name', 'whatsapp_click')
      .gte('created_at', oncekiBaslangic).lt('created_at', suankiBaslangic),

    (supabase as any).from('analytics_events')
      .select('created_at, event_name, source')
      .in('business_id', businessIds)
      .gte('created_at', oncekiBaslangic)
      .limit(100000),

    supabase.from('favorites')
      .select('created_at')
      .in('business_id', businessIds)
      .gte('created_at', suankiBaslangic)
      .limit(50000),

    supabase.from('business_reviews')
      .select('created_at')
      .in('business_id', businessIds)
      .eq('status', 'approved')
      .gte('created_at', suankiBaslangic)
      .limit(50000),
  ]);

  // Yoğun saatler: ilk işletme için RPC çağrısı (tek business_id alıyor)
  const yogunSaatler = await getYogunSaatler(businessIds[0]);

  type HamOlay = { created_at: string; event_name: string; source: string | null };
  type TarihSatiri = { created_at: string };

  const tumHamOlaylar: HamOlay[] = hamOlaylarRes.data ?? [];
  const guncelOlaylar = tumHamOlaylar.filter((e) => new Date(e.created_at).getTime() >= suankiBaslangicMs);
  const oncekiOlaylar = tumHamOlaylar.filter((e) => new Date(e.created_at).getTime() < suankiBaslangicMs);

  // ── Günlük görüntülenme trendi (bu dönem vs önceki dönem) ────────────────────
  const gorunumOlaySeti = new Set(GORUNTULEME_OLAYLARI);
  const guncelGunHaritasi: Record<string, number> = {};
  const oncekiGunHaritasi: Record<string, number> = {};

  for (const e of guncelOlaylar) {
    if (gorunumOlaySeti.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      guncelGunHaritasi[k] = (guncelGunHaritasi[k] ?? 0) + 1;
    }
  }
  for (const e of oncekiOlaylar) {
    if (gorunumOlaySeti.has(e.event_name)) {
      const k = e.created_at.split('T')[0];
      oncekiGunHaritasi[k] = (oncekiGunHaritasi[k] ?? 0) + 1;
    }
  }

  const gunlukTrend: GunlukNokta[] = Array.from({ length: gunSayisi }, (_, i) => {
    const d = new Date(su - (gunSayisi - 1 - i) * 86400000);
    const guncelAnahtar = d.toISOString().split('T')[0];
    const oncekiAnahtar = new Date(d.getTime() - gunSayisi * 86400000).toISOString().split('T')[0];
    return {
      label: d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' }),
      guncel: guncelGunHaritasi[guncelAnahtar] ?? 0,
      onceki: oncekiGunHaritasi[oncekiAnahtar] ?? 0,
    };
  });

  // ── Trafik kaynağı kırılımı (bu dönem) ────────────────────────────────────────
  const kaynakHaritasi: Record<string, number> = {};
  for (const e of guncelOlaylar) {
    const etiketAdi = KAYNAK_ETIKETLERI[e.source ?? ''] ?? 'Diğer';
    kaynakHaritasi[etiketAdi] = (kaynakHaritasi[etiketAdi] ?? 0) + 1;
  }
  const kaynakToplam = Object.values(kaynakHaritasi).reduce((a, b) => a + b, 0);
  const trafikKaynaklari: TrafikKaynagi[] = Object.entries(kaynakHaritasi)
    .sort((a, b) => b[1] - a[1])
    .map(([ad, sayi], i) => ({
      ad,
      deger: kaynakToplam > 0 ? Math.round((sayi / kaynakToplam) * 1000) / 10 : 0,
      renk: KAYNAK_RENKLERI[Math.min(i, KAYNAK_RENKLERI.length - 1)],
    }));

  // ── Haftanın günü ısı haritası (görüntülenme/favori/yorum/arama) ─────────────
  const gunBazliGoruntuleme: number[] = Array(7).fill(0);
  const gunBazliArama: number[] = Array(7).fill(0);
  const gunBazliFavori: number[] = Array(7).fill(0);
  const gunBazliYorum: number[] = Array(7).fill(0);

  for (const e of guncelOlaylar) {
    const d = new Date(e.created_at).getDay();
    if (['menu_view', 'menu_link_opened'].includes(e.event_name)) gunBazliGoruntuleme[d]++;
    if (['discovery_impression', 'business_impression'].includes(e.event_name)) gunBazliArama[d]++;
  }
  for (const f of (favoriSatirlariRes.data ?? []) as TarihSatiri[]) {
    gunBazliFavori[new Date(f.created_at).getDay()]++;
  }
  for (const r of (yorumSatirlariRes.data ?? []) as TarihSatiri[]) {
    gunBazliYorum[new Date(r.created_at).getDay()]++;
  }

  const isiHaritasi: IsiHaritasiSatiri[] = [
    isiHaritasiSatiriOlustur('Görüntülenme', gunBazliGoruntuleme),
    isiHaritasiSatiriOlustur('Favori', gunBazliFavori),
    isiHaritasiSatiriOlustur('Yorum', gunBazliYorum),
    isiHaritasiSatiriOlustur('Arama', gunBazliArama),
  ];

  // ── Görüntülenme bazlı saatlik dağılım (bu dönem) ─────────────────────────────
  const saatHaritasi = Array<number>(24).fill(0);
  for (const e of guncelOlaylar) {
    if (gorunumOlaySeti.has(e.event_name)) {
      saatHaritasi[new Date(e.created_at).getHours()]++;
    }
  }
  const saatlikGoruntuleme: SaatlikNokta[] = saatHaritasi.map((v, i) => ({
    saat: i.toString().padStart(2, '0'),
    sayi: v,
  }));

  // ── Menü/QR günlük trend + tüm olayların saatlik dağılımı (sahip'in mevcut özelliği) ─
  const gunlukMenu: Record<string, number> = {};
  const gunlukQr: Record<string, number> = {};
  const saatlikDagilim: Record<string, number> = {};

  for (const o of guncelOlaylar) {
    const d = new Date(o.created_at);
    const gun = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    const saat = String(d.getHours()).padStart(2, '0');
    if (o.event_name === 'menu_view') gunlukMenu[gun] = (gunlukMenu[gun] ?? 0) + 1;
    if (o.event_name === 'qr_scan') gunlukQr[gun] = (gunlukQr[gun] ?? 0) + 1;
    saatlikDagilim[saat] = (saatlikDagilim[saat] ?? 0) + 1;
  }

  const menuQrGunleri: MenuQrGunu[] = [];
  for (let i = Math.min(gunSayisi - 1, 13); i >= 0; i--) {
    const d = new Date(su - i * 86400000);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    const label = i === 0 ? 'Bugün' : `${d.getDate()}/${d.getMonth() + 1}`;
    menuQrGunleri.push({ label, menu: gunlukMenu[key] ?? 0, qr: gunlukQr[key] ?? 0 });
  }

  const saatlikDagilimVerisi: SaatlikNokta[] = [];
  for (let h = 0; h < 24; h++) {
    const k = String(h).padStart(2, '0');
    saatlikDagilimVerisi.push({ saat: `${h}:00`, sayi: saatlikDagilim[k] ?? 0 });
  }

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Analitik"
        description={`Performans özeti — ${etiket.toLowerCase()}`}
        actions={<AralikSecici aktif={aralik} />}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <AnalitikIstemcisi
          etiket={etiket}
          gorunumler={gorunumlerSimdi.count ?? 0}
          gorunumlerOnceki={gorunumlerOnceki.count ?? 0}
          favoriler={favorilerSimdi.count ?? 0}
          favorilerOnceki={favorilerOnceki.count ?? 0}
          yorumlar={yorumlarSimdi.count ?? 0}
          yorumlarOnceki={yorumlarOnceki.count ?? 0}
          aramalar={aramalarSimdi.count ?? 0}
          aramalarOnceki={aramalarOnceki.count ?? 0}
          qrTaramalari={qrSimdi.count ?? 0}
          qrTaramalariOnceki={qrOnceki.count ?? 0}
          whatsappTiklamalari={whatsappSimdi.count ?? 0}
          whatsappTiklamalariOnceki={whatsappOnceki.count ?? 0}
          isletmeSayisi={businessIds.length}
          gunlukTrend={gunlukTrend}
          trafikKaynaklari={trafikKaynaklari}
          isiHaritasi={isiHaritasi}
          saatlikGoruntuleme={saatlikGoruntuleme}
          menuQrGunleri={menuQrGunleri}
          saatlikDagilim={saatlikDagilimVerisi}
        />

        {/* Yoğun Saatler — get_business_busy_hours_v1 (son 28 gün) */}
        <PanelBolumKarti
          title="Yoğun Saatler"
          description="İlk işletmenize ait saat bazlı yoğunluk analizi"
          className="mt-6"
        >
          <YogunSaatlerKarti veriler={yogunSaatler} />
        </PanelBolumKarti>
      </PanelIcerikYuzeyi>
    </div>
  );
}

// ─── Zaman aralığı seçici (link-based, permalink uyumlu) ─────────────────────

function AralikSecici({ aktif }: { aktif: Aralik }) {
  const secenekler: { aralik: Aralik; etiket: string }[] = [
    { aralik: '7g', etiket: '7 gün' },
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
