'use client';

import { useState, useRef, useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import dynamic from 'next/dynamic';

type Tab = 'yakin' | 'sehirler' | 'kayitli';
type Konum = { ilce: string; sehir: string };

// Leaflet SSR guard
const KonumGoruntuleyici = dynamic(() => import('@/src/components/maps/KonumGoruntuleyici'), {
  ssr: false,
  loading: () => <div className="h-full w-full animate-pulse bg-slate-100" />,
});

// ── Sabit koordinatlar ────────────────────────────────────────────────────────
const KONUM_LAT_LNG: Record<string, [number, number]> = {
  'Yenimahalle': [39.9334, 32.8114],
  'Çankaya':     [39.9035, 32.8597],
  'Keçiören':    [39.9792, 32.8538],
  'Etimesgut':   [39.9526, 32.6797],
  'Altındağ':    [39.9371, 32.8858],
  'Sincan':      [39.9726, 32.5826],
  'Mamak':       [39.9200, 32.9200],
  'Ankara':      [39.9334, 32.8597],
  'İstanbul':    [41.0082, 28.9784],
  'İzmir':       [38.4192, 27.1287],
  'Bursa':       [40.1885, 29.0610],
  'Antalya':     [36.8969, 30.7133],
  'Adana':       [37.0000, 35.3213],
  'Konya':       [37.8714, 32.4846],
  'Gaziantep':   [37.0662, 37.3833],
  'Mersin':      [36.8000, 34.6333],
  'Kayseri':     [38.7205, 35.4826],
  'Eskişehir':   [39.7767, 30.5206],
  'Trabzon':     [41.0015, 39.7178],
  'Samsun':      [41.2867, 36.3300],
  'Malatya':     [38.3552, 38.3095],
  'Diyarbakır':  [37.9144, 40.2306],
  'Balıkesir':   [39.6484, 27.8826],
  'Denizli':     [37.7765, 29.0864],
  'Manisa':      [38.6191, 27.4289],
  'Muğla':       [37.2153, 28.3636],
  'Sakarya':     [40.6940, 30.4358],
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

const TUM_SEHIRLER = [
  'Ankara', 'İstanbul', 'İzmir', 'Bursa', 'Antalya',
  'Adana', 'Konya', 'Gaziantep', 'Mersin', 'Kayseri',
  'Eskişehir', 'Trabzon', 'Samsun', 'Malatya', 'Diyarbakır',
  'Balıkesir', 'Denizli', 'Manisa', 'Muğla', 'Sakarya',
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
  const aramaRef              = useRef<HTMLInputElement>(null);

  useEffect(() => { setMounted(true); }, []);

  useEffect(() => {
    try {
      const kayitli = localStorage.getItem(DEPO_KEY);
      if (kayitli) setSecili(JSON.parse(kayitli) as Konum);
    } catch { /* ignore */ }
  }, []);

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
    ? TUM_SEHIRLER.filter(s => s.toLocaleLowerCase('tr').includes(arama.toLocaleLowerCase('tr')))
    : TUM_SEHIRLER;

  // ── Modal JSX ──────────────────────────────────────────────────────────────
  const modal = acik ? (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4" role="dialog" aria-modal="true" aria-label="Konum Seç">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={kapat} aria-hidden="true" />

      {/* Kart */}
      <div className="relative z-10 flex h-[600px] w-full max-w-[900px] overflow-hidden rounded-3xl bg-card shadow-yd3">

        {/* ── Sol panel ──────────────────────────────────────────────────── */}
        <div className="flex w-[360px] shrink-0 flex-col border-r border-border">

          {/* Başlık */}
          <div className="flex items-start justify-between p-6 pb-4">
            <div>
              <h2 className="text-xl font-[900] text-textStrong">Konum Seç</h2>
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
                className={`relative flex items-center gap-1.5 pb-3 pr-4 text-xs font-[800] transition-colors ${tab === key ? 'text-primary' : 'text-muted hover:text-textStrong'}`}>
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
                  <p className="text-sm font-[800] text-textStrong">Yakınımı otomatik algıla</p>
                  <p className="mt-0.5 text-xs text-muted">Konum iznin açık olduğunda sana en yakın mekanları göstereceğiz.</p>
                </div>
                <button type="button"
                  onClick={() => { navigator.geolocation?.getCurrentPosition(() => konumSec({ ilce: 'Mevcut Konum', sehir: '' })); }}
                  className="shrink-0 rounded-xl bg-primary px-3 py-2 text-xs font-[900] text-white hover:brightness-110">
                  İzin Ver
                </button>
              </div>

              <p className="mb-3 text-sm font-[900] text-textStrong">Yakındaki Popüler Konumlar</p>
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
                          <p className={`text-sm font-[800] ${secildi ? 'text-primary' : 'text-textStrong'}`}>{k.ilce}</p>
                          <p className="text-xs text-muted">{k.sehir}</p>
                        </div>
                        {mevcut
                          ? <span className="flex items-center gap-1 text-xs font-[800] text-primary">Mevcut Konum <CheckIcon /></span>
                          : <ChevronRight />}
                      </button>
                    </li>
                  );
                })}
              </ul>
            </>)}

            {/* Şehirler */}
            {tab === 'sehirler' && (
              <ul className="space-y-1.5">
                {filtreliSehirler.map((s) => {
                  const k: Konum = { ilce: s, sehir: 'Türkiye' };
                  const secildi = aktifKonum?.ilce === s;
                  return (
                    <li key={s}>
                      <button type="button" onClick={() => konumSec(k)}
                        className={`flex w-full items-center gap-3 rounded-2xl border px-4 py-3 text-left transition-all ${secildi ? 'border-primary/30 bg-primary/5' : 'border-border bg-card hover:bg-cardAlt'}`}>
                        <PinIcon className={`h-4 w-4 shrink-0 fill-none stroke-2 ${secildi ? 'stroke-primary' : 'stroke-muted'}`} />
                        <span className={`text-sm font-[800] ${secildi ? 'text-primary' : 'text-textStrong'}`}>{s}</span>
                        {secildi && <span className="ml-auto"><CheckIcon /></span>}
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}

            {/* Kayıtlı */}
            {tab === 'kayitli' && (
              <div className="flex flex-col items-center justify-center py-12 text-center">
                <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-cardAlt">
                  <svg viewBox="0 0 24 24" className="h-7 w-7 fill-none stroke-muted stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                  </svg>
                </div>
                <p className="text-sm font-[800] text-textStrong">Kayıtlı konum yok</p>
                <p className="mt-1 text-xs text-muted">Sık kullandığın konumları buraya kaydedebilirsin.</p>
              </div>
            )}
          </div>

          {/* Alt butonlar */}
          <div className="flex gap-2 border-t border-border p-4">
            <button type="button" onClick={kapat}
              className="flex h-11 flex-1 items-center justify-center rounded-2xl border border-border bg-cardAlt text-sm font-[800] text-textStrong hover:bg-card">
              İptal
            </button>
            <button type="button" onClick={onayla} disabled={!aktifKonum}
              className="flex h-11 flex-[2] items-center justify-center gap-2 rounded-2xl bg-primary text-sm font-[900] text-white shadow-sm hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50">
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
                className="min-w-0 flex-1 bg-transparent text-sm text-textStrong placeholder:text-muted outline-none" />
            </div>
            <button type="button"
              onClick={() => { navigator.geolocation?.getCurrentPosition(() => konumSec({ ilce: 'Mevcut Konum', sehir: '' })); }}
              className="flex shrink-0 items-center gap-1.5 rounded-xl px-3 py-2.5 text-sm font-[800] text-primary hover:bg-primary/5">
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
              <div className="absolute left-3 top-3 z-[400] flex items-center gap-2 rounded-2xl bg-white px-3 py-2 shadow-yd2">
                <PinIcon className="h-4 w-4 shrink-0 fill-none stroke-primary stroke-2" />
                <div>
                  <p className="text-sm font-[900] text-primary">{konumYaz(aktifKonum)}</p>
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
              <p className="text-[10px] font-[800] uppercase tracking-wide text-muted">Seçilen Konum</p>
              <p className="text-sm font-[900] text-textStrong">{aktifKonum ? konumYaz(aktifKonum) : '—'}</p>
            </div>
            <button type="button" onClick={() => setTab('yakin')}
              className="flex items-center gap-1 text-sm font-[800] text-primary hover:underline">
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
        className="flex items-center gap-1.5 rounded-xl border border-border bg-cardAlt px-3 py-2 text-sm transition-colors hover:border-primary/40 hover:bg-card focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
        aria-label="Konum seç" aria-haspopup="dialog">
        <PinIcon className="h-4 w-4 shrink-0 fill-none stroke-primary stroke-2" />
        <span className="max-w-[120px] truncate font-[800] text-textStrong">
          {secili ? konumYaz(secili) : 'Konum seç'}
        </span>
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 shrink-0 fill-none stroke-current stroke-2 text-muted" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      {/* Portal: backdrop-blur stacking context'ini atlatır */}
      {mounted && createPortal(modal, document.body)}
    </>
  );
}
