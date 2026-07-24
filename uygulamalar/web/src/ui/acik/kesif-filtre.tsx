'use client';

import { useState } from 'react';

const MUTFAKLAR = [
  'Türk Mutfağı',
  'Fast Food',
  'Dünya Mutfağı',
  'Tatlı & Fırın',
  'Kahvaltı',
  'İtalyan',
  'Japon',
  'Çin',
  'Meksika',
];

const SIRALAMA = [
  { value: 'onerilen',       label: 'Önerilen' },
  { value: 'en-yuksek-puan', label: 'En Yüksek Puan' },
  { value: 'en-yakin',       label: 'En Yakın' },
  { value: 'en-ucuz',        label: 'En Uygun Fiyat' },
  { value: 'yeni',           label: 'En Yeni' },
];

const FIYAT_ETIKET = ['₺', '₺₺', '₺₺₺', '₺₺₺₺'];

const PUAN_SECENEKLER = [
  { deger: 4.5, dolu: 4, yarim: true },
  { deger: 4.0, dolu: 4, yarim: false },
  { deger: 3.5, dolu: 3, yarim: true },
  { deger: 3.0, dolu: 3, yarim: false },
];

function YildizSatiri({ dolu, yarim }: { dolu: number; yarim: boolean }) {
  return (
    <span className="flex items-center gap-0.5">
      {Array.from({ length: 4 }, (_, i) => {
        const full = i < dolu;
        const half = !full && yarim && i === dolu;
        return (
          <svg key={i} viewBox="0 0 24 24" className={`h-3.5 w-3.5 ${full ? 'fill-amber-400 text-amber-400' : half ? 'fill-amber-200 text-amber-200' : 'fill-none stroke-amber-300 stroke-2'}`} aria-hidden="true">
            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
          </svg>
        );
      })}
    </span>
  );
}

export function KesifFiltreSidebar() {
  const [konum, setKonum]             = useState('Yenimahalle, Ankara');
  const [siralama, setSiralama]       = useState('onerilen');
  const [mutfaklar, setMutfaklar]     = useState<string[]>([]);
  const [tumMutfak, setTumMutfak]     = useState(false);
  const [maxFiyat, setMaxFiyat]       = useState(3);
  const [sadaceAcik, setSadaceAcik]   = useState(true);
  const [tumHepsini, setTumHepsini]   = useState(false);
  const [minPuan, setMinPuan]         = useState<number | null>(null);

  const gosterilen = tumMutfak ? MUTFAKLAR : MUTFAKLAR.slice(0, 5);

  function toggleMutfak(m: string) {
    setMutfaklar(prev => prev.includes(m) ? prev.filter(x => x !== m) : [...prev, m]);
  }

  function temizle() {
    setMutfaklar([]);
    setMaxFiyat(3);
    setSadaceAcik(false);
    setTumHepsini(false);
    setMinPuan(null);
  }

  return (
    <div className="sticky top-24 rounded-2xl border border-border bg-card p-4 shadow-yd1">
      <h2 className="mb-4 text-base font-black text-textStrong">Filtrele</h2>

      {/* Konum */}
      <div className="mb-5">
        <p className="mb-2 text-sm font-extrabold text-textStrong">Konum</p>
        <div className="flex items-center gap-2 rounded-xl border border-border bg-bg px-3 py-2.5">
          <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 fill-none stroke-current stroke-2 text-muted" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />
          </svg>
          <input
            type="text"
            value={konum}
            onChange={(e) => setKonum(e.target.value)}
            className="min-w-0 flex-1 bg-transparent text-sm text-textStrong outline-hidden"
          />
          <button type="button" aria-label="Konumumu kullan" className="shrink-0 text-muted hover:text-primary">
            <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <circle cx="12" cy="12" r="3" /><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" />
            </svg>
          </button>
        </div>
      </div>

      {/* Sıralama */}
      <div className="mb-5">
        <p className="mb-2 text-sm font-extrabold text-textStrong">Sıralama</p>
        <div className="relative">
          <select
            value={siralama}
            onChange={(e) => setSiralama(e.target.value)}
            className="w-full appearance-none rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong outline-hidden focus:border-primary"
          >
            {SIRALAMA.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
          <svg viewBox="0 0 24 24" className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 fill-none stroke-current stroke-2 text-muted" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <polyline points="6 9 12 15 18 9" />
          </svg>
        </div>
      </div>

      {/* Mutfak */}
      <div className="mb-5">
        <p className="mb-2 text-sm font-extrabold text-textStrong">Mutfak</p>
        <div className="space-y-2">
          {gosterilen.map(m => (
            <label key={m} className="flex cursor-pointer items-center gap-2">
              <input
                type="checkbox"
                checked={mutfaklar.includes(m)}
                onChange={() => toggleMutfak(m)}
                className="h-4 w-4 cursor-pointer rounded accent-primary"
              />
              <span className="text-sm text-textStrong">{m}</span>
            </label>
          ))}
        </div>
        <button
          type="button"
          onClick={() => setTumMutfak(v => !v)}
          className="mt-2 text-sm font-extrabold text-primary hover:underline"
        >
          {tumMutfak ? 'Daha az gör' : 'Tümünü Gör'}
        </button>
      </div>

      {/* Fiyat Aralığı */}
      <div className="mb-5">
        <p className="mb-2 text-sm font-extrabold text-textStrong">Fiyat Aralığı</p>
        <input
          type="range"
          min="0"
          max="3"
          value={maxFiyat}
          onChange={(e) => setMaxFiyat(Number(e.target.value))}
          className="w-full accent-primary"
        />
        <div className="mt-2 flex justify-between text-xs font-bold text-muted">
          {FIYAT_ETIKET.map((l, i) => (
            <span key={l} className={i <= maxFiyat ? 'text-textStrong' : ''}>{l}</span>
          ))}
        </div>
      </div>

      {/* Açık / Kapalı */}
      <div className="mb-5">
        <p className="mb-2 text-sm font-extrabold text-textStrong">Açık / Kapalı</p>
        <div className="space-y-2">
          <label className="flex cursor-pointer items-center gap-2">
            <input
              type="checkbox"
              checked={sadaceAcik}
              onChange={(e) => setSadaceAcik(e.target.checked)}
              className="h-4 w-4 cursor-pointer rounded accent-primary"
            />
            <span className="text-sm text-textStrong">Şu an açık olanlar</span>
          </label>
          <label className="flex cursor-pointer items-center gap-2">
            <input
              type="checkbox"
              checked={tumHepsini}
              onChange={(e) => setTumHepsini(e.target.checked)}
              className="h-4 w-4 cursor-pointer rounded accent-primary"
            />
            <span className="text-sm text-textStrong">Tümü</span>
          </label>
        </div>
      </div>

      {/* Puan */}
      <div className="mb-6">
        <p className="mb-2 text-sm font-extrabold text-textStrong">Puan</p>
        <div className="space-y-2">
          {PUAN_SECENEKLER.map(({ deger, dolu, yarim }) => (
            <label key={deger} className="flex cursor-pointer items-center gap-2">
              <input
                type="checkbox"
                checked={minPuan === deger}
                onChange={() => setMinPuan(prev => prev === deger ? null : deger)}
                className="h-4 w-4 cursor-pointer rounded accent-primary"
              />
              <span className="flex items-center gap-1.5 text-sm">
                <YildizSatiri dolu={dolu} yarim={yarim} />
                <span className="text-textStrong">{deger} ve üzeri</span>
              </span>
            </label>
          ))}
        </div>
      </div>

      {/* Temizle */}
      <button
        type="button"
        onClick={temizle}
        className="flex w-full items-center justify-center gap-2 rounded-xl border border-border bg-bg py-2.5 text-sm font-extrabold text-textStrong transition-colors hover:bg-cardAlt"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" />
          <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
        </svg>
        Filtreleri Temizle
      </button>
    </div>
  );
}
