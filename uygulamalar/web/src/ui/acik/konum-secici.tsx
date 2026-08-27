'use client';

import { useState, useRef, useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import dynamic from 'next/dynamic';
import { createSupabaseBrowserClient } from '@/src/lib/taban-istemci';

type Tab = 'yakin' | 'sehirler' | 'kayitli';
type Konum = { ilce: string; sehir: string };

// Leaflet SSR guard
const KonumGoruntuleyici = dynamic(() => import('@/src/components/maps/KonumGoruntuleyici'), {
  ssr: false,
  loading: () => <div className="h-full w-full animate-pulse bg-slate-100" />,
});

// ── Sabit koordinatlar ────────────────────────────────────────────────────────
// Ankara ilçeleri (Yakınımda sekmesindeki popüler konumlar için) + Türkiye'nin
// 81 ilinin merkez koordinatları (RPC'den gelen gerçek şehir adları için).
const KONUM_LAT_LNG: Record<string, [number, number]> = {
  'Yenimahalle': [39.9334, 32.8114],
  'Çankaya':     [39.9035, 32.8597],
  'Keçiören':    [39.9792, 32.8538],
  'Etimesgut':   [39.9526, 32.6797],
  'Altındağ':    [39.9371, 32.8858],
  'Sincan':      [39.9726, 32.5826],
  'Mamak':       [39.9200, 32.9200],
  'Adana': [37.0000, 35.3213], 'Adıyaman': [37.7648, 38.2786], 'Afyonkarahisar': [38.7507, 30.5567],
  'Ağrı': [39.7191, 43.0503], 'Aksaray': [38.3687, 34.0360], 'Amasya': [40.6499, 35.8353],
  'Ankara': [39.9334, 32.8597], 'Antalya': [36.8969, 30.7133], 'Ardahan': [41.1105, 42.7022],
  'Artvin': [41.1828, 41.8183], 'Aydın': [37.8560, 27.8416], 'Balıkesir': [39.6484, 27.8826],
  'Bartın': [41.5811, 32.4610], 'Batman': [37.8812, 41.1351], 'Bayburt': [40.2552, 40.2249],
  'Bilecik': [40.1451, 29.9799], 'Bingöl': [38.8855, 40.4966], 'Bitlis': [38.4006, 42.1095],
  'Bolu': [40.7392, 31.6089], 'Burdur': [37.7203, 30.2908], 'Bursa': [40.1885, 29.0610],
  'Çanakkale': [40.1553, 26.4142], 'Çankırı': [40.6013, 33.6134], 'Çorum': [40.5506, 34.9556],
  'Denizli': [37.7765, 29.0864], 'Diyarbakır': [37.9144, 40.2306], 'Düzce': [40.8438, 31.1565],
  'Edirne': [41.6771, 26.5557], 'Elazığ': [38.6810, 39.2264], 'Erzincan': [39.7500, 39.5000],
  'Erzurum': [39.9000, 41.2700], 'Eskişehir': [39.7767, 30.5206], 'Gaziantep': [37.0662, 37.3833],
  'Giresun': [40.9128, 38.3895], 'Gümüşhane': [40.4386, 39.5086], 'Hakkari': [37.5744, 43.7408],
  'Hatay': [36.4018, 36.3498], 'Iğdır': [39.9167, 44.0333], 'Isparta': [37.7648, 30.5566],
  'İstanbul': [41.0082, 28.9784], 'İzmir': [38.4192, 27.1287], 'Kahramanmaraş': [37.5753, 36.9228],
  'Karabük': [41.2061, 32.6204], 'Karaman': [37.1759, 33.2287], 'Kars': [40.6013, 43.0975],
  'Kastamonu': [41.3887, 33.7827], 'Kayseri': [38.7205, 35.4826], 'Kilis': [36.7184, 37.1212],
  'Kırıkkale': [39.8468, 33.5153], 'Kırklareli': [41.7333, 27.2167], 'Kırşehir': [39.1425, 34.1709],
  'Kocaeli': [40.8533, 29.8815], 'Konya': [37.8714, 32.4846], 'Kütahya': [39.4167, 29.9833],
  'Malatya': [38.3552, 38.3095], 'Manisa': [38.6191, 27.4289], 'Mardin': [37.3212, 40.7245],
  'Mersin': [36.8000, 34.6333], 'Muğla': [37.2153, 28.3636], 'Muş': [38.9462, 41.7539],
  'Nevşehir': [38.6939, 34.6857], 'Niğde': [37.9667, 34.6833], 'Ordu': [40.9839, 37.8764],
  'Osmaniye': [37.0742, 36.2478], 'Rize': [41.0201, 40.5234], 'Sakarya': [40.6940, 30.4358],
  'Samsun': [41.2867, 36.3300], 'Siirt': [37.9333, 41.9500], 'Sinop': [42.0231, 35.1531],
  'Sivas': [39.7477, 37.0179], 'Şanlıurfa': [37.1591, 38.7969], 'Şırnak': [37.4187, 42.4918],
  'Tekirdağ': [40.9833, 27.5167], 'Tokat': [40.3167, 36.5500], 'Trabzon': [41.0015, 39.7178],
  'Tunceli': [39.3074, 39.4388], 'Uşak': [38.6823, 29.4082], 'Van': [38.4891, 43.4089],
  'Yalova': [40.6500, 29.2667], 'Yozgat': [39.8181, 34.8147], 'Zonguldak': [41.4564, 31.7987],
};

const VARSAYILAN_MERKEZ: [number, number] = [39.9334, 32.8597]; // Ankara

function merkezBul(k: Konum | null): [number, number] {
  if (!k) return VARSAYILAN_MERKEZ;
  return KONUM_LAT_LNG[k.ilce] ?? KONUM_LAT_LNG[k.sehir] ?? VARSAYILAN_MERKEZ;
}

const POPULER_KONUMLAR: Konum[] = [
  { ilce: 'Yenimahalle', sehir: 'Ankara' },
  { ilce: 'Çankaya',     sehir: 'Ankara' },
  { ilce: 'Keçiören',    sehir: 'Ankara' },
  { ilce: 'Etimesgut',   sehir: 'Ankara' },
  { ilce: 'Altındağ',    sehir: 'Ankara' },
];

// Gerçek işletme verisi gelene kadar (veya RPC başarısız olursa) gösterilecek
// düşük riskli varsayılan liste — get_public_business_cities_v1 RPC'si gerçek
// taranan şehirleri sayımla döndürünce bunun yerini alır.
const VARSAYILAN_SEHIRLER = [
  'Ankara', 'Antalya', 'Bursa', 'İstanbul', 'İzmir',
];

const DEPO_KEY = 'yd_konum';

function konumYaz(k: Konum) {
  return k.sehir ? `${k.ilce}, ${k.sehir}` : k.ilce;
}

// ── SVG ikonlar ───────────────────────────────────────────────────────────────
function PinIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={className ?? 'h-4 w-4 fill-none stroke-current stroke-2'} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />
    </svg>
  );
}
function ChevronRight() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2 text-muted" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}
function CheckIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-primary stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
function XIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}
function SearchIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 fill-none stroke-current stroke-2 text-muted" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  );
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────
export function KonumSecici() {
  const [secili, setSecili]   = useState<Konum | null>(null);
  const [gecici, setGecici]   = useState<Konum | null>(null);
  const [acik, setAcik]       = useState(false);
  const [tab, setTab]         = useState<Tab>('yakin');
  const [arama, setArama]     = useState('');
  const [mounted, setMounted] = useState(false);
  const [sehirler, setSehirler] = useState<string[]>(VARSAYILAN_SEHIRLER);
  const [sehirlerYukleniyor, setSehirlerYukleniyor] = useState(false);
  const sehirlerYuklendiRef  = useRef(false);
  const aramaRef              = useRef<HTMLInputElement>(null);

  // SSR/istemci hydration güvenliği için mount bayrağı — derive-from-render'a taşınamaz.
  // eslint-disable-next-line react-hooks/set-state-in-effect
  useEffect(() => { setMounted(true); }, []);

  useEffect(() => {
    try {
      const kayitli = localStorage.getItem(DEPO_KEY);
      // localStorage okuması UI dışı bir kaynaktan senkronizasyon.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      if (kayitli) setSecili(JSON.parse(kayitli) as Konum);
    } catch { /* ignore */ }
  }, []);

  // Gerçek taranan şehir listesini modal ilk açıldığında bir kez çek —
  // sabit/kısa bir liste yerine işletme sayısına göre sıralı gerçek şehirler.
  useEffect(() => {
    if (!acik || sehirlerYuklendiRef.current) return;
    sehirlerYuklendiRef.current = true;
    setSehirlerYukleniyor(true);
    (async () => {
      try {
        const sb = createSupabaseBrowserClient();
        const { data, error } = await (sb as any).rpc('get_public_business_cities_v1', { p_limit: 80 });
        if (error) throw error;
        const cities = ((data ?? []) as Array<{ city: string }>).map((r) => r.city).filter(Boolean);
        // RPC işletme sayısına göre sıralı döner (en sık kullanılan ilk 80 şehri seçmek için) —
        // aranabilirlik için gösterimde alfabetik sıraya çeviriyoruz.
        cities.sort((a, b) => a.localeCompare(b, 'tr'));
        if (cities.length > 0) setSehirler(cities);
      } catch {
        // Sessizce varsayılan listede kal
      } finally {
        setSehirlerYukleniyor(false);
      }
    })();
  }, [acik]);

  const kapat = useCallback(() => {
    setAcik(false);
    setGecici(null);
    setArama('');
  }, []);

  useEffect(() => {
    if (!acik) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') kapat(); };
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    setTimeout(() => aramaRef.current?.focus(), 80);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [acik, kapat]);

  function konumSec(k: Konum) { setGecici(k); }

  function onayla() {
    const hedef = gecici ?? secili;
    if (hedef) {
      setSecili(hedef);
      try { localStorage.setItem(DEPO_KEY, JSON.stringify(hedef)); } catch { /* ignore */ }
    }
    kapat();
  }

  const aktifKonum = gecici ?? secili;
  const haritaMerkezi = merkezBul(aktifKonum);

  const filtreliSehirler = arama.trim()
    ? sehirler.filter(s => s.toLocaleLowerCase('tr').includes(arama.toLocaleLowerCase('tr')))
    : sehirler;

  // ── Modal JSX ──────────────────────────────────────────────────────────────
  const modal = acik ? (
    <div className="fixed inset-0 z-9999 flex items-center justify-center p-4" role="dialog" aria-modal="true" aria-label="Konum Seç">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50 backdrop-blur-xs" onClick={kapat} aria-hidden="true" />

      {/* Kart */}
      <div className="relative z-10 flex h-[600px] w-full max-w-[900px] overflow-hidden rounded-3xl bg-card shadow-yd3">

        {/* ── Sol panel ──────────────────────────────────────────────────── */}
        <div className="flex w-[360px] shrink-0 flex-col border-r border-border">

          {/* Başlık */}
          <div className="flex items-start justify-between p-6 pb-4">
            <div>
              <h2 className="text-xl font-black text-textStrong">Konum Seç</h2>
              <p className="mt-1 text-sm leading-relaxed text-muted">
                Sana en yakın lezzetleri ve fırsatları gösterebilmemiz için konumunu seç.
              </p>
            </div>
            <button type="button" onClick={kapat} aria-label="Kapat" className="ml-3 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-muted hover:bg-cardAlt hover:text-textStrong">
              <XIcon />
            </button>
          </div>

          {/* Tablar */}
          <div className="flex border-b border-border px-5">
            {([
              { key: 'yakin' as Tab, label: 'Yakınımda', iconEl: <PinIcon className="h-3.5 w-3.5 fill-none stroke-current stroke-2" /> },
              { key: 'sehirler' as Tab, label: 'Şehirler', iconEl: (
                <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="7" height="7" />
                </svg>
              )},
              { key: 'kayitli' as Tab, label: 'Kayıtlı Konumlarım', iconEl: (
                <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                </svg>
              )},
            ]).map(({ key, label, iconEl }) => (
              <button key={key} type="button" onClick={() => setTab(key)}
                className={`relative flex items-center gap-1.5 pb-3 pr-4 text-xs font-extrabold transition-colors ${tab === key ? 'text-primary' : 'text-muted hover:text-textStrong'}`}>
                {iconEl}{label}
                {tab === key && <span className="absolute bottom-0 left-0 right-4 h-0.5 rounded-full bg-primary" />}
              </button>
            ))}
          </div>

          {/* Tab içeriği */}
          <div className="flex-1 overflow-y-auto p-4">

            {/* Yakınımda */}
            {tab === 'yakin' && (<>
              <div className="mb-4 flex items-center gap-3 rounded-2xl border border-border bg-cardAlt p-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/10">
                  <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-primary stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <circle cx="12" cy="12" r="3" /><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" />
                  </svg>
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-extrabold text-textStrong">Yakınımı otomatik algıla</p>
                  <p className="mt-0.5 text-xs text-muted">Konum iznin açık olduğunda sana en yakın mekanları göstereceğiz.</p>
                </div>
                <button type="button"
                  onClick={() => { navigator.geolocation?.getCurrentPosition(() => konumSec({ ilce: 'Mevcut Konum', sehir: '' })); }}
                  className="shrink-0 rounded-xl bg-primary px-3 py-2 text-xs font-black text-white hover:brightness-110">
                  İzin Ver
                </button>
              </div>

              <p className="mb-3 text-sm font-black text-textStrong">Yakındaki Popüler Konumlar</p>
              <ul className="space-y-1.5">
                {POPULER_KONUMLAR.map((k) => {
                  const secildi = aktifKonum?.ilce === k.ilce && aktifKonum?.sehir === k.sehir;
                  const mevcut  = secili?.ilce === k.ilce && secili?.sehir === k.sehir;
                  return (
                    <li key={k.ilce}>
                      <button type="button" onClick={() => konumSec(k)}
                        className={`flex w-full items-center gap-3 rounded-2xl border px-4 py-3 text-left transition-all ${secildi ? 'border-primary/30 bg-primary/5' : 'border-border bg-card hover:bg-cardAlt'}`}>
                        <PinIcon className={`h-4 w-4 shrink-0 fill-none stroke-2 ${secildi ? 'stroke-primary' : 'stroke-muted'}`} />
                        <div className="min-w-0 flex-1">
                          <p className={`text-sm font-extrabold ${secildi ? 'text-primary' : 'text-textStrong'}`}>{k.ilce}</p>
                          <p className="text-xs text-muted">{k.sehir}</p>
                        </div>
                        {mevcut
                          ? <span className="flex items-center gap-1 text-xs font-extrabold text-primary">Mevcut Konum <CheckIcon /></span>
                          : <ChevronRight />}
                      </button>
                    </li>
                  );
                })}
              </ul>
            </>)}

            {/* Şehirler */}
            {tab === 'sehirler' && (
              <>
                {sehirlerYukleniyor && sehirler === VARSAYILAN_SEHIRLER && (
                  <p className="mb-3 text-xs text-muted">Şehirler yükleniyor…</p>
                )}
                {filtreliSehirler.length === 0 ? (
                  <p className="py-8 text-center text-sm text-muted">Şehir bulunamadı.</p>
                ) : (
              <ul className="space-y-1.5">
                {filtreliSehirler.map((s) => {
                  const k: Konum = { ilce: s, sehir: 'Türkiye' };
                  const secildi = aktifKonum?.ilce === s;
                  return (
                    <li key={s}>
                      <button type="button" onClick={() => konumSec(k)}
                        className={`flex w-full items-center gap-3 rounded-2xl border px-4 py-3 text-left transition-all ${secildi ? 'border-primary/30 bg-primary/5' : 'border-border bg-card hover:bg-cardAlt'}`}>
                        <PinIcon className={`h-4 w-4 shrink-0 fill-none stroke-2 ${secildi ? 'stroke-primary' : 'stroke-muted'}`} />
                        <span className={`text-sm font-extrabold ${secildi ? 'text-primary' : 'text-textStrong'}`}>{s}</span>
                        {secildi && <span className="ml-auto"><CheckIcon /></span>}
                      </button>
                    </li>
                  );
                })}
              </ul>
                )}
              </>
            )}

            {/* Kayıtlı */}
            {tab === 'kayitli' && (
              <div className="flex flex-col items-center justify-center py-12 text-center">
                <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-cardAlt">
                  <svg viewBox="0 0 24 24" className="h-7 w-7 fill-none stroke-muted stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                  </svg>
                </div>
                <p className="text-sm font-extrabold text-textStrong">Kayıtlı konum yok</p>
                <p className="mt-1 text-xs text-muted">Sık kullandığın konumları buraya kaydedebilirsin.</p>
              </div>
            )}
          </div>

          {/* Alt butonlar */}
          <div className="flex gap-2 border-t border-border p-4">
            <button type="button" onClick={kapat}
              className="flex h-11 flex-1 items-center justify-center rounded-2xl border border-border bg-cardAlt text-sm font-extrabold text-textStrong hover:bg-card">
              İptal
            </button>
            <button type="button" onClick={onayla} disabled={!aktifKonum}
              className="flex h-11 flex-2 items-center justify-center gap-2 rounded-2xl bg-primary text-sm font-black text-white shadow-xs hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50">
              <PinIcon className="h-4 w-4 fill-none stroke-white stroke-2" />
              Bu konumu kullan
            </button>
          </div>
        </div>

        {/* ── Sağ panel ──────────────────────────────────────────────────── */}
        <div className="flex min-w-0 flex-1 flex-col">

          {/* Arama bar */}
          <div className="flex items-center gap-2 border-b border-border p-4">
            <div className="flex flex-1 items-center gap-2 rounded-xl border border-border bg-cardAlt px-3 py-2.5">
              <SearchIcon />
              <input ref={aramaRef} type="text" value={arama}
                onChange={e => { setArama(e.target.value); setTab('sehirler'); }}
                placeholder="Şehir, ilçe veya mahalle ara..."
                className="min-w-0 flex-1 bg-transparent text-sm text-textStrong placeholder:text-muted outline-hidden" />
            </div>
            <button type="button"
              onClick={() => { navigator.geolocation?.getCurrentPosition(() => konumSec({ ilce: 'Mevcut Konum', sehir: '' })); }}
              className="flex shrink-0 items-center gap-1.5 rounded-xl px-3 py-2.5 text-sm font-extrabold text-primary hover:bg-primary/5">
              <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-primary stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <circle cx="12" cy="12" r="3" /><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" />
              </svg>
              Mevcut konumumu kullan
            </button>
          </div>

          {/* Harita */}
          <div className="relative flex-1 overflow-hidden">
            {/* Konum chip */}
            {aktifKonum && (
              <div className="absolute left-3 top-3 z-400 flex items-center gap-2 rounded-2xl bg-white px-3 py-2 shadow-yd2">
                <PinIcon className="h-4 w-4 shrink-0 fill-none stroke-primary stroke-2" />
                <div>
                  <p className="text-sm font-black text-primary">{konumYaz(aktifKonum)}</p>
                  <p className="text-[10px] text-muted">Mevcut konum</p>
                </div>
              </div>
            )}
            <KonumGoruntuleyici center={haritaMerkezi} />
          </div>

          {/* Seçilen konum bar */}
          <div className="flex items-center gap-3 border-t border-border px-4 py-3.5">
            <PinIcon className="h-5 w-5 shrink-0 fill-none stroke-primary stroke-2" />
            <div className="min-w-0 flex-1">
              <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Seçilen Konum</p>
              <p className="text-sm font-black text-textStrong">{aktifKonum ? konumYaz(aktifKonum) : '—'}</p>
            </div>
            <button type="button" onClick={() => setTab('yakin')}
              className="flex items-center gap-1 text-sm font-extrabold text-primary hover:underline">
              Değiştir <ChevronRight />
            </button>
          </div>
        </div>

      </div>
    </div>
  ) : null;

  return (
    <>
      {/* Pill tetikleyici */}
      <button type="button"
        onClick={() => { setAcik(true); setGecici(secili); }}
        className="flex items-center gap-1.5 rounded-xl border border-border bg-cardAlt px-3 py-2 text-sm transition-colors hover:border-primary/40 hover:bg-card focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
        aria-label="Konum seç" aria-haspopup="dialog">
        <PinIcon className="h-4 w-4 shrink-0 fill-none stroke-primary stroke-2" />
        <span className="max-w-[120px] truncate font-extrabold text-textStrong">
          {secili ? konumYaz(secili) : 'Konum seç'}
        </span>
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 shrink-0 fill-none stroke-current stroke-2 text-muted" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      {/* Portal: backdrop-blur-sm stacking context'ini atlatır */}
      {mounted && createPortal(modal, document.body)}
    </>
  );
}
