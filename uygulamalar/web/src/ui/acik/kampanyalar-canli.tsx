'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import {
  type KampanyaTuru,
  type BadgeLine,
  TUR_ETIKETLER,
  TUR_RENK,
  gunKaldiHesapla,
  kampanyaBadge,
} from '@/src/lib/kampanya-sunum';

// ── Tipler ───────────────────────────────────────────────────────────────────

export type IsletmeProp = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null; district: string | null;
  logoUrl: string | null; coverUrl: string | null;
  isVerified: boolean; reviewsCount: number; avgRating: number | null;
  priceLevel: string | null; medianPriceCents: number | null;
};

// Sunucudan gelen ham kampanya + işletme verisi (public.campaigns tablosu — owner
// panelinden gerçekten oluşturulmuş kampanyalar, RLS: sadece status='active' olanlar).
export type KampanyaGirdi = IsletmeProp & {
  campaignId: string;
  campaignTitle: string;
  campaignDescription: string | null;
  campaignType: KampanyaTuru;
  discountPercent: number | null;
  campaignImageUrl: string | null;
  endsAt: string | null;
};

type Kampanya = IsletmeProp & {
  campaignId: string;
  tur: KampanyaTuru;
  badge: BadgeLine[];
  badgeRenk: string;
  baslik: string;
  aciklama: string;
  imageUrl: string | null;
  gunKaldi: number | null;
};

// ── Sabitler ─────────────────────────────────────────────────────────────────

const KAT_SEKMELER = ['Tümü', 'Restoran', 'Kafe', 'Tatlıcı', 'Fast Food', 'Kahvaltı'] as const;

function kampanyaDonustur(veri: KampanyaGirdi): Kampanya {
  return {
    ...veri,
    campaignId: veri.campaignId,
    tur: veri.campaignType,
    badge: kampanyaBadge(veri.campaignType, veri.discountPercent),
    badgeRenk: TUR_RENK[veri.campaignType],
    baslik: veri.campaignTitle,
    aciklama: veri.campaignDescription?.trim() || veri.campaignTitle,
    imageUrl: veri.campaignImageUrl,
    gunKaldi: gunKaldiHesapla(veri.endsAt),
  };
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
  const img = buildMenuImageUrl(k.imageUrl ?? k.coverUrl ?? k.logoUrl ?? null, { width: 640, quality: 78 })
    ?? '/category-images/restoran.webp';

  return (
    <article className="group flex flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
      {/* Görsel */}
      <div className="relative w-full overflow-hidden" style={{ aspectRatio: '16/10' }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={img} alt={k.baslik} className="h-full w-full object-cover transition-transform group-hover:scale-105" loading="lazy" />

        {/* Alt gradient (timer okunabilirliği) */}
        <div className="absolute inset-x-0 bottom-0 h-16 bg-linear-to-t from-black/60 to-transparent" aria-hidden="true" />

        {/* Kampanya rozeti — sol üst */}
        <div
          className="absolute left-2.5 top-2.5 rounded-xl px-2.5 py-2 leading-tight"
          style={{ background: k.badgeRenk }}
        >
          {k.badge.map((line, i) => (
            <p
              key={i}
              className={`font-black text-white ${
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
          className="absolute right-2.5 top-2.5 flex h-8 w-8 items-center justify-center rounded-full bg-white/90 text-muted shadow-md backdrop-blur-sm transition-colors hover:text-primary"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </button>

        {/* Süre rozeti — sol alt (bitiş tarihi olmayan kampanyalarda gösterilmez) */}
        {k.gunKaldi != null && (
          <div className="absolute bottom-2.5 left-2.5 flex items-center gap-1 rounded-full bg-danger px-2.5 py-1 shadow-sm">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
              <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
            </svg>
            <span className="text-[11px] font-black text-white">
              {k.gunKaldi === 0 ? 'Son gün' : `${k.gunKaldi} gün kaldı`}
            </span>
          </div>
        )}
      </div>

      {/* İçerik */}
      <div className="flex flex-col gap-1.5 p-3">
        <p className="text-base font-black text-textStrong leading-tight">{k.baslik}</p>
        <p className="text-[13px] font-bold text-muted line-clamp-2 leading-snug">{k.aciklama}</p>
        <p className="text-[11px] font-bold text-muted">
          {[k.name, k.category].filter(Boolean).join(' · ')}
        </p>

        {/* Alt bilgi satırı */}
        <div className="mt-1 flex items-center gap-2 border-t border-border pt-2 text-[12px] font-extrabold">
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
        </div>

        {/* Detay linki */}
        <Link
          href={`/isletme/${k.slug}?tab=kampanyalar`}
          className="mt-1 flex h-9 w-full items-center justify-center rounded-xl bg-primary text-sm font-black text-white transition-all hover:brightness-110"
        >
          Fırsatı Gör →
        </Link>
      </div>
    </article>
  );
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

type Props = { campaigns: KampanyaGirdi[] };

export function KampanyalarCanli({ campaigns }: Props) {
  const [aktifSekme, setAktifSekme] = useState<string>('Tümü');
  const [aktifTurler, setAktifTurler] = useState<Set<KampanyaTuru>>(new Set());
  const [aktifFiyat, setAktifFiyat] = useState<string>('');
  const [gecerlilik, setGecerlilik] = useState<'tumu' | 'bugun' | 'bu-hafta' | 'bu-ay'>('tumu');
  const [sort, setSort] = useState<'yeni' | 'puan' | 'bitis' | 'fiyat'>('yeni');
  const [konum, setKonum] = useState('');

  const tumKampanyalar = useMemo(() => campaigns.map(kampanyaDonustur), [campaigns]);

  // Filtrele
  const filtered = useMemo(() => {
    let list = tumKampanyalar;

    if (aktifSekme !== 'Tümü') {
      list = list.filter((k) => k.category === aktifSekme);
    }
    if (aktifTurler.size > 0) {
      list = list.filter((k) => aktifTurler.has(k.tur));
    }
    if (aktifFiyat) {
      list = list.filter((k) => fiyatSembolu(k.priceLevel, k.medianPriceCents) === aktifFiyat);
    }
    if (konum.trim()) {
      const q = konum.trim().toLocaleLowerCase('tr');
      list = list.filter((k) =>
        (k.city?.toLocaleLowerCase('tr').includes(q) ?? false) ||
        (k.district?.toLocaleLowerCase('tr').includes(q) ?? false));
    }
    if (gecerlilik === 'bugun') {
      list = list.filter((k) => k.gunKaldi != null && k.gunKaldi <= 1);
    } else if (gecerlilik === 'bu-hafta') {
      list = list.filter((k) => k.gunKaldi != null && k.gunKaldi <= 7);
    } else if (gecerlilik === 'bu-ay') {
      list = list.filter((k) => k.gunKaldi != null && k.gunKaldi <= 30);
    }

    return list;
  }, [tumKampanyalar, aktifSekme, aktifTurler, aktifFiyat, gecerlilik, konum]);

  // Sırala
  const sorted = useMemo(() => {
    return [...filtered].sort((a, b) => {
      if (sort === 'puan')   return (b.avgRating ?? 0) - (a.avgRating ?? 0);
      if (sort === 'bitis')  return (a.gunKaldi ?? Infinity) - (b.gunKaldi ?? Infinity);
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

  const hasFilter = aktifSekme !== 'Tümü' || aktifTurler.size > 0 || !!aktifFiyat || gecerlilik !== 'tumu' || !!konum;

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">

        {/* ── Başlık + kategori sekmeleri ──────────────────────────────── */}
        <div className="mb-6 flex flex-wrap items-start gap-4">
          {/* Sol: başlık */}
          <div className="shrink-0">
            <h1 className="text-2xl font-black text-textStrong sm:text-3xl">Kampanyalar 🎉</h1>
            <p className="mt-1 text-sm font-bold text-muted">En güncel lezzet fırsatlarını kaçırma!</p>
          </div>

          {/* Orta: sekme + sıralama */}
          <div className="flex flex-1 flex-wrap items-center justify-end gap-2">
            <nav className="flex flex-wrap gap-1.5" aria-label="Kategori filtresi">
              {KAT_SEKMELER.map((sek) => (
                <button
                  key={sek}
                  type="button"
                  onClick={() => setAktifSekme(sek)}
                  className={`flex items-center gap-1.5 rounded-xl px-3.5 py-2 text-xs font-black transition-all ${
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
                className="appearance-none rounded-xl border border-border bg-card py-2 pl-3 pr-8 text-xs font-black text-textStrong outline-hidden transition focus:border-primary"
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
            <p className="text-sm font-black text-textStrong">Filtrele</p>

            {/* Konum */}
            <div className="space-y-1.5">
              <label className="text-xs font-extrabold text-muted">Konum</label>
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
                  className="w-full rounded-xl border border-border bg-surface py-2.5 pl-9 pr-3 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>

            {/* Kategori dropdown */}
            <div className="space-y-1.5">
              <label className="text-xs font-extrabold text-muted">Kategori</label>
              <div className="relative">
                <select
                  value={aktifSekme}
                  onChange={(e) => setAktifSekme(e.target.value)}
                  className="w-full appearance-none rounded-xl border border-border bg-surface py-2.5 pl-3 pr-8 text-sm font-extrabold text-textStrong focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
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
              <p className="text-xs font-extrabold text-muted">Kampanya Türü</p>
              {(Object.entries(TUR_ETIKETLER) as [KampanyaTuru, string][]).map(([tur, etiket]) => (
                <label key={tur} className="flex cursor-pointer items-center gap-2.5">
                  <input
                    type="checkbox"
                    checked={aktifTurler.has(tur)}
                    onChange={() => toggleTur(tur)}
                    className="h-4 w-4 cursor-pointer rounded accent-primary"
                  />
                  <span className="text-sm font-bold text-textStrong">{etiket}</span>
                </label>
              ))}
            </div>

            {/* Fiyat Aralığı */}
            <div className="space-y-2">
              <p className="text-xs font-extrabold text-muted">Fiyat Aralığı</p>
              <div className="flex gap-1.5">
                {['₺', '₺₺', '₺₺₺', '₺₺₺₺'].map((f) => (
                  <button
                    key={f}
                    type="button"
                    onClick={() => setAktifFiyat(aktifFiyat === f ? '' : f)}
                    className={`flex-1 rounded-lg border py-2 text-xs font-black transition-all ${
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
              <p className="text-xs font-extrabold text-muted">Geçerlilik</p>
              {([['tumu', 'Tümü'], ['bugun', 'Bugün'], ['bu-hafta', 'Bu Hafta'], ['bu-ay', 'Bu Ay']] as const).map(([val, etiket]) => (
                <label key={val} className="flex cursor-pointer items-center gap-2.5">
                  <input
                    type="radio"
                    name="gecerlilik"
                    checked={gecerlilik === val}
                    onChange={() => setGecerlilik(val)}
                    className="h-4 w-4 cursor-pointer accent-primary"
                  />
                  <span className="text-sm font-bold text-textStrong">{etiket}</span>
                </label>
              ))}
            </div>

            {/* Temizle */}
            {hasFilter && (
              <button
                type="button"
                onClick={filtreleriTemizle}
                className="flex w-full items-center justify-center gap-1.5 rounded-xl border border-border bg-surface py-2.5 text-xs font-extrabold text-muted transition-colors hover:border-danger/40 hover:text-danger"
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
                <p className="text-base font-black text-textStrong">
                  {tumKampanyalar.length === 0 ? 'Şu an aktif kampanya yok' : 'Sonuç bulunamadı'}
                </p>
                <p className="mt-2 text-sm font-bold text-muted">
                  {tumKampanyalar.length === 0 ? 'Yakında yeni fırsatlar burada olacak, takipte kal!' : 'Farklı filtreler deneyin'}
                </p>
                {hasFilter && tumKampanyalar.length > 0 && (
                  <button
                    type="button"
                    onClick={filtreleriTemizle}
                    className="mt-4 text-sm font-black text-primary hover:underline"
                  >
                    Filtreleri temizle →
                  </button>
                )}
              </div>
            ) : (
              <>
                <p className="mb-4 text-xs font-extrabold text-muted">{sorted.length} kampanya listelendi</p>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
                  {sorted.map((k) => <KampanyaKarti key={k.campaignId} k={k} />)}
                </div>
              </>
            )}

            {/* CTA banner — giriş yap */}
            <div className="mt-10 flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-primary/20 bg-primary/5 px-5 py-5">
              <div className="flex items-center gap-3">
                <span className="text-2xl" aria-hidden="true">🎁</span>
                <div>
                  <p className="text-sm font-black text-textStrong">Sana özel kampanyalar için giriş yap!</p>
                  <p className="mt-0.5 text-xs font-bold text-muted">
                    Beğendiklerine göre sana özel fırsatları kaçırma.
                  </p>
                </div>
              </div>
              <Link
                href="/giris"
                className="flex h-10 items-center rounded-xl bg-primary px-5 text-sm font-black text-white shadow-xs transition-all hover:brightness-110 whitespace-nowrap"
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
