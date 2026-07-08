'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

// ── Tipler ───────────────────────────────────────────────────────────────────

export type IsletmeProp = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null; district: string | null;
  logoUrl: string | null; coverUrl: string | null;
  isVerified: boolean; reviewsCount: number; avgRating: number | null;
  priceLevel: string | null; medianPriceCents: number | null;
};

type KampanyaTuru = 'indirim' | '1a1b' | 'paket' | 'menu' | 'ucretsiz';

type BadgeLine = { metin: string; buyuk?: boolean };

type Kampanya = IsletmeProp & {
  tur: KampanyaTuru;
  badge: BadgeLine[];
  badgeRenk: string;
  aciklama: string;
  altKategori: string | null;
  gunKaldi: number;
  uyeOzel: boolean;
};

// ── Sabitler ─────────────────────────────────────────────────────────────────

const ALT_KAT: Record<string, string[]> = {
  Restoran:    ['Türk Mutfağı', 'İtalyan Mutfağı', 'Uzak Doğu', 'Dünya Mutfağı', 'Fast Food'],
  Kafe:        ['Kahve', 'Çay', 'Soğuk İçecek'],
  'Tatlıcı':  ['Pastane', 'Dondurma', 'Tatlı'],
  Mekan:       ['Bar', 'Pub', 'Lounge'],
  'Balık / Et':['Balık', 'Et', 'Steakhouse'],
  'Kahvaltı': ['Türk Kahvaltısı', 'Serpme', 'Büfe'],
};

const KAT_SEKMELER = ['Tümü', 'Restoran', 'Kafe', 'Tatlıcı', 'Fast Food', 'Kahvaltı'] as const;

const TUR_ETIKETLER: Record<KampanyaTuru, string> = {
  indirim: 'İndirim',
  '1a1b':  '1 Alana 1 Bedava',
  paket:   'Paket Fırsat',
  menu:    'Menü Fırsatı',
  ucretsiz:'Ücretsiz Teslimat',
};

const INDIRIM_LIST = [10, 15, 20, 25, 30];
const FIYAT_LIST   = [99, 129, 149, 179, 199, 229, 249];
const GUN_LIST     = [1, 2, 3, 4, 5, 6, 7];
const TUR_LIST: KampanyaTuru[] = ['indirim', 'indirim', '1a1b', 'paket', 'menu', 'ucretsiz', 'indirim'];

// ── Yardımcılar ──────────────────────────────────────────────────────────────

function hash(s: string): number {
  return (s.split('').reduce((a, c) => (a * 31 + c.charCodeAt(0)) | 0, 0) >>> 0);
}

function kampanyaOlustur(biz: IsletmeProp): Kampanya {
  const h   = hash(biz.id);
  const tur = TUR_LIST[h % TUR_LIST.length];
  const gun = GUN_LIST[h % GUN_LIST.length];
  const uyeOzel = h % 4 === 0;
  const fiyat   = FIYAT_LIST[h % FIYAT_LIST.length];
  const ind     = INDIRIM_LIST[h % INDIRIM_LIST.length];
  const catU    = (biz.category ?? 'MENÜ').toUpperCase();
  const altList = ALT_KAT[biz.category ?? ''];
  const altKat  = altList ? (altList[h % altList.length] ?? null) : null;

  let badge: BadgeLine[];
  let badgeRenk: string;
  let aciklama: string;

  switch (tur) {
    case 'indirim':
      badge     = [{ metin: `%${ind}`, buyuk: true }, { metin: 'İNDİRİM' }];
      badgeRenk = '#7f1d1d';
      aciklama  = `Tüm ${biz.category?.toLowerCase() ?? 'menü'} ürünlerinde %${ind} indirim!`;
      break;
    case '1a1b':
      badge     = [{ metin: '1 ALANA 1' }, { metin: 'BEDAVA', buyuk: true }];
      badgeRenk = '#15803d';
      aciklama  = 'Seçili ürün alana ikinci ücretsiz!';
      break;
    case 'paket':
      badge     = [{ metin: catU }, { metin: 'MENÜSÜ' }, { metin: `₺${fiyat}`, buyuk: true }];
      badgeRenk = '#b45309';
      aciklama  = `${biz.category ?? 'Özel'} menüsü sadece ₺${fiyat}!`;
      break;
    case 'menu':
      badge     = [{ metin: 'KAHVE' }, { metin: '+ TATLISI' }, { metin: `₺${fiyat}`, buyuk: true }];
      badgeRenk = '#0e7490';
      aciklama  = `Kahve + Tatlı keyfi sadece ₺${fiyat}!`;
      break;
    default: // ucretsiz
      badge     = [{ metin: 'ÜCRETSİZ' }, { metin: 'TESLİMAT', buyuk: false }];
      badgeRenk = '#16a34a';
      aciklama  = `₺${fiyat} ve üzeri siparişlerde ücretsiz teslimat!`;
  }

  return { ...biz, tur, badge, badgeRenk, aciklama, altKategori: altKat, gunKaldi: gun, uyeOzel };
}

function fiyatSembolu(pl: string | null | undefined, mc: number | null | undefined): string {
  if (pl === 'budget')  return '₺';
  if (pl === 'mid')     return '₺₺';
  if (pl === 'premium') return '₺₺₺';
  if (!mc) return '';
  if (mc < 15000) return '₺';
  if (mc < 40000) return '₺₺';
  return '₺₺₺';
}

// ── Kampanya kartı ────────────────────────────────────────────────────────────

function KampanyaKarti({ k }: { k: Kampanya }) {
  const img = buildMenuImageUrl(k.coverUrl ?? k.logoUrl ?? null, { width: 640, quality: 78 })
    ?? '/category-images/restoran.webp';

  return (
    <article className="group flex flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
      {/* Görsel */}
      <div className="relative w-full overflow-hidden" style={{ aspectRatio: '16/10' }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={img} alt={k.name} className="h-full w-full object-cover transition-transform group-hover:scale-105" loading="lazy" />

        {/* Alt gradient (timer okunabilirliği) */}
        <div className="absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-black/60 to-transparent" aria-hidden="true" />

        {/* Kampanya rozeti — sol üst */}
        <div
          className="absolute left-2.5 top-2.5 rounded-xl px-2.5 py-2 leading-tight"
          style={{ background: k.badgeRenk }}
        >
          {k.badge.map((line, i) => (
            <p
              key={i}
              className={`font-[900] text-white ${
                line.buyuk ? 'text-[18px] leading-none' : 'text-[10px] uppercase tracking-wide'
              }`}
            >
              {line.metin}
            </p>
          ))}
        </div>

        {/* Favori butonu — sağ üst */}
        <button
          type="button"
          aria-label="Favorilere ekle"
          className="absolute right-2.5 top-2.5 flex h-8 w-8 items-center justify-center rounded-full bg-white/90 text-muted shadow-md backdrop-blur transition-colors hover:text-primary"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </button>

        {/* Süre rozeti — sol alt */}
        <div className="absolute bottom-2.5 left-2.5 flex items-center gap-1 rounded-full bg-danger px-2.5 py-1 shadow">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
          </svg>
          <span className="text-[11px] font-[900] text-white">{k.gunKaldi} gün kaldı</span>
        </div>
      </div>

      {/* İçerik */}
      <div className="flex flex-col gap-1.5 p-3">
        <p className="text-base font-[900] text-textStrong leading-tight">{k.name}</p>
        <p className="text-[13px] font-[700] text-muted line-clamp-2 leading-snug">{k.aciklama}</p>
        <p className="text-[11px] font-[700] text-muted/70">
          {[k.category, k.altKategori].filter(Boolean).join(' · ')}
        </p>

        {/* Alt bilgi satırı */}
        <div className="mt-1 flex items-center gap-2 border-t border-border pt-2 text-[12px] font-[800]">
          {k.district ?? k.city ? (
            <span className="flex items-center gap-1 text-muted">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>
              </svg>
              {k.district ?? k.city}
            </span>
          ) : null}

          {k.avgRating != null && k.avgRating > 0 ? (
            <span className="flex items-center gap-1 text-amber-600">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
              </svg>
              {k.avgRating.toFixed(1)}
              {k.reviewsCount > 0 && (
                <span className="text-muted">({k.reviewsCount.toLocaleString('tr-TR')})</span>
              )}
            </span>
          ) : null}

          {k.uyeOzel && (
            <span className="ml-auto flex items-center gap-1 rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-[900] text-amber-700">
              👑 Üye Özel
            </span>
          )}
        </div>

        {/* Detay linki */}
        <Link
          href={`/b/${k.slug}`}
          className="mt-1 flex h-9 w-full items-center justify-center rounded-xl bg-primary text-sm font-[900] text-white transition-all hover:brightness-110"
        >
          Fırsatı Gör →
        </Link>
      </div>
    </article>
  );
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

type Props = { businesses: IsletmeProp[] };

export function KampanyalarCanli({ businesses }: Props) {
  const [aktifSekme, setAktifSekme] = useState<string>('Tümü');
  const [aktifTurler, setAktifTurler] = useState<Set<KampanyaTuru>>(new Set());
  const [aktifFiyat, setAktifFiyat] = useState<string>('');
  const [gecerlilik, setGecerlilik] = useState<'tumu' | 'bugun' | 'bu-hafta' | 'bu-ay'>('tumu');
  const [sort, setSort] = useState<'yeni' | 'puan' | 'bitis' | 'fiyat'>('yeni');
  const [konum, setKonum] = useState('');

  // Demo kampanya verisi oluştur (deterministik)
  const tumKampanyalar = useMemo(() => businesses.map(kampanyaOlustur), [businesses]);

  // Filtrele
  const filtered = useMemo(() => {
    let list = tumKampanyalar;

    if (aktifSekme !== 'Tümü') {
      if (aktifSekme === 'Fast Food') {
        list = list.filter((k) => k.category === 'Restoran' || k.altKategori === 'Fast Food');
      } else {
        list = list.filter((k) => k.category === aktifSekme);
      }
    }
    if (aktifTurler.size > 0) {
      list = list.filter((k) => aktifTurler.has(k.tur));
    }
    if (aktifFiyat) {
      list = list.filter((k) => fiyatSembolu(k.priceLevel, k.medianPriceCents) === aktifFiyat);
    }
    if (gecerlilik === 'bugun') {
      list = list.filter((k) => k.gunKaldi === 1);
    } else if (gecerlilik === 'bu-hafta') {
      list = list.filter((k) => k.gunKaldi <= 7);
    }

    return list;
  }, [tumKampanyalar, aktifSekme, aktifTurler, aktifFiyat, gecerlilik]);

  // Sırala
  const sorted = useMemo(() => {
    return [...filtered].sort((a, b) => {
      if (sort === 'puan')   return (b.avgRating ?? 0) - (a.avgRating ?? 0);
      if (sort === 'bitis')  return a.gunKaldi - b.gunKaldi;
      if (sort === 'fiyat')  return (a.medianPriceCents ?? 0) - (b.medianPriceCents ?? 0);
      return b.reviewsCount - a.reviewsCount; // yeni: en popüler
    });
  }, [filtered, sort]);

  // Checkbox toggle
  function toggleTur(tur: KampanyaTuru) {
    setAktifTurler((prev) => {
      const next = new Set(prev);
      if (next.has(tur)) next.delete(tur);
      else next.add(tur);
      return next;
    });
  }

  function filtreleriTemizle() {
    setAktifSekme('Tümü');
    setAktifTurler(new Set());
    setAktifFiyat('');
    setGecerlilik('tumu');
    setKonum('');
  }

  const hasFilter = aktifSekme !== 'Tümü' || aktifTurler.size > 0 || aktifFiyat || gecerlilik !== 'tumu';

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">

        {/* ── Başlık + kategori sekmeleri ──────────────────────────────── */}
        <div className="mb-6 flex flex-wrap items-start gap-4">
          {/* Sol: başlık */}
          <div className="shrink-0">
            <h1 className="text-2xl font-[900] text-textStrong sm:text-3xl">Kampanyalar 🎉</h1>
            <p className="mt-1 text-sm font-[700] text-muted">En güncel lezzet fırsatlarını kaçırma!</p>
          </div>

          {/* Orta: sekme + sıralama */}
          <div className="flex flex-1 flex-wrap items-center justify-end gap-2">
            <nav className="flex flex-wrap gap-1.5" aria-label="Kategori filtresi">
              {KAT_SEKMELER.map((sek) => (
                <button
                  key={sek}
                  type="button"
                  onClick={() => setAktifSekme(sek)}
                  className={`flex items-center gap-1.5 rounded-xl px-3.5 py-2 text-xs font-[900] transition-all ${
                    aktifSekme === sek
                      ? 'bg-primary text-white shadow-yd1'
                      : 'border border-border bg-card text-textStrong hover:border-primary/40 hover:text-primary'
                  }`}
                >
                  {sek === 'Tümü' && (
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                      <path d="M4 6h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4zM4 12h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4zM4 18h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4z"/>
                    </svg>
                  )}
                  {sek}
                </button>
              ))}
            </nav>

            {/* Sırala dropdown */}
            <div className="relative">
              <select
                value={sort}
                onChange={(e) => setSort(e.target.value as typeof sort)}
                className="appearance-none rounded-xl border border-border bg-card py-2 pl-3 pr-8 text-xs font-[900] text-textStrong outline-none transition focus:border-primary"
              >
                <option value="yeni">En Popüler</option>
                <option value="puan">En Yüksek Puan</option>
                <option value="bitis">Bitiş Tarihi</option>
                <option value="fiyat">En İyi Fiyat</option>
              </select>
              <span className="pointer-events-none absolute inset-y-0 right-2.5 flex items-center text-muted" aria-hidden="true">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                  <path d="m6 9 6 6 6-6"/>
                </svg>
              </span>
            </div>
          </div>
        </div>

        {/* ── İki sütun ────────────────────────────────────────────────── */}
        <div className="flex flex-col gap-6 lg:flex-row lg:items-start">

          {/* Sol filtre sidebar */}
          <aside className="w-full space-y-6 rounded-2xl border border-border bg-card p-5 shadow-yd1 lg:w-56 lg:shrink-0 lg:sticky lg:top-20 lg:self-start">
            <p className="text-sm font-[900] text-textStrong">Filtrele</p>

            {/* Konum */}
            <div className="space-y-1.5">
              <label className="text-xs font-[800] text-muted">Konum</label>
              <div className="relative">
                <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-muted" aria-hidden="true">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>
                  </svg>
                </span>
                <input
                  type="text"
                  value={konum}
                  onChange={(e) => setKonum(e.target.value)}
                  placeholder="Şehir veya ilçe..."
                  className="w-full rounded-xl border border-border bg-surface py-2.5 pl-9 pr-3 text-sm font-[700] text-textStrong placeholder:text-muted focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>

            {/* Kategori dropdown */}
            <div className="space-y-1.5">
              <label className="text-xs font-[800] text-muted">Kategori</label>
              <div className="relative">
                <select
                  value={aktifSekme}
                  onChange={(e) => setAktifSekme(e.target.value)}
                  className="w-full appearance-none rounded-xl border border-border bg-surface py-2.5 pl-3 pr-8 text-sm font-[800] text-textStrong focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                >
                  {KAT_SEKMELER.map((k) => <option key={k} value={k}>{k}</option>)}
                </select>
                <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-muted" aria-hidden="true">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="m6 9 6 6 6-6"/></svg>
                </span>
              </div>
            </div>

            {/* Kampanya Türü */}
            <div className="space-y-2">
              <p className="text-xs font-[800] text-muted">Kampanya Türü</p>
              {(Object.entries(TUR_ETIKETLER) as [KampanyaTuru, string][]).map(([tur, etiket]) => (
                <label key={tur} className="flex cursor-pointer items-center gap-2.5">
                  <input
                    type="checkbox"
                    checked={aktifTurler.has(tur)}
                    onChange={() => toggleTur(tur)}
                    className="h-4 w-4 cursor-pointer rounded accent-primary"
                  />
                  <span className="text-sm font-[700] text-textStrong">{etiket}</span>
                </label>
              ))}
            </div>

            {/* Fiyat Aralığı */}
            <div className="space-y-2">
              <p className="text-xs font-[800] text-muted">Fiyat Aralığı</p>
              <div className="flex gap-1.5">
                {['₺', '₺₺', '₺₺₺', '₺₺₺₺'].map((f) => (
                  <button
                    key={f}
                    type="button"
                    onClick={() => setAktifFiyat(aktifFiyat === f ? '' : f)}
                    className={`flex-1 rounded-lg border py-2 text-xs font-[900] transition-all ${
                      aktifFiyat === f
                        ? 'border-primary bg-primary text-white'
                        : 'border-border bg-surface text-textStrong hover:border-primary/40 hover:text-primary'
                    }`}
                  >
                    {f}
                  </button>
                ))}
              </div>
            </div>

            {/* Geçerlilik */}
            <div className="space-y-2">
              <p className="text-xs font-[800] text-muted">Geçerlilik</p>
              {([['tumu', 'Tümü'], ['bugun', 'Bugün'], ['bu-hafta', 'Bu Hafta'], ['bu-ay', 'Bu Ay']] as const).map(([val, etiket]) => (
                <label key={val} className="flex cursor-pointer items-center gap-2.5">
                  <input
                    type="radio"
                    name="gecerlilik"
                    checked={gecerlilik === val}
                    onChange={() => setGecerlilik(val)}
                    className="h-4 w-4 cursor-pointer accent-primary"
                  />
                  <span className="text-sm font-[700] text-textStrong">{etiket}</span>
                </label>
              ))}
            </div>

            {/* Temizle */}
            {hasFilter && (
              <button
                type="button"
                onClick={filtreleriTemizle}
                className="flex w-full items-center justify-center gap-1.5 rounded-xl border border-border bg-surface py-2.5 text-xs font-[800] text-muted transition-colors hover:border-danger/40 hover:text-danger"
              >
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                  <path d="M18 6 6 18M6 6l12 12"/>
                </svg>
                Filtreleri Temizle
              </button>
            )}
          </aside>

          {/* Sağ: kart grid + banner */}
          <div className="flex-1 min-w-0">
            {!sorted.length ? (
              <div className="rounded-2xl border border-border bg-card p-12 text-center">
                <p className="text-base font-[900] text-textStrong">Sonuç bulunamadı</p>
                <p className="mt-2 text-sm font-[700] text-muted">Farklı filtreler deneyin</p>
                {hasFilter && (
                  <button
                    type="button"
                    onClick={filtreleriTemizle}
                    className="mt-4 text-sm font-[900] text-primary hover:underline"
                  >
                    Filtreleri temizle →
                  </button>
                )}
              </div>
            ) : (
              <>
                <p className="mb-4 text-xs font-[800] text-muted">{sorted.length} kampanya listelendi</p>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
                  {sorted.map((k) => <KampanyaKarti key={k.id} k={k} />)}
                </div>
              </>
            )}

            {/* CTA banner — giriş yap */}
            <div className="mt-10 flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-primary/20 bg-primary/5 px-5 py-5">
              <div className="flex items-center gap-3">
                <span className="text-2xl" aria-hidden="true">🎁</span>
                <div>
                  <p className="text-sm font-[900] text-textStrong">Sana özel kampanyalar için giriş yap!</p>
                  <p className="mt-0.5 text-xs font-[700] text-muted">
                    Beğendiklerine göre sana özel fırsatları kaçırma.
                  </p>
                </div>
              </div>
              <Link
                href="/giris"
                className="flex h-10 items-center rounded-xl bg-primary px-5 text-sm font-[900] text-white shadow-sm transition-all hover:brightness-110 whitespace-nowrap"
              >
                Giriş Yap / Üye Ol
              </Link>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
