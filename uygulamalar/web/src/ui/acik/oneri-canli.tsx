'use client';

import { useMemo, useRef, useState } from 'react';
import type { ComponentType } from 'react';
import Link from 'next/link';
import { Utensils, Coffee, Cake, Egg, Beer, Beef, type LucideProps } from 'lucide-react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

// ── Tipler ───────────────────────────────────────────────────────────────────

export type OneriIsletme = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null; district: string | null;
  logoUrl: string | null; coverUrl: string | null;
  isVerified: boolean; reviewsCount: number; avgRating: number | null;
};

// ── Sabitler ─────────────────────────────────────────────────────────────────

const KAT_ICON: Record<string, ComponentType<LucideProps>> = {
  'Restoran': Utensils, 'Kafe': Coffee, 'Tatlıcı': Cake,
  'Kahvaltı': Egg, 'Mekan': Beer, 'Balık / Et': Beef,
};

const ETIKET_MAP: Record<string, { text: string; color: string }> = {
  'Restoran':   { text: 'Yerli mutfağını seviyorsun',       color: '#7f1d1d' },
  'Kafe':       { text: 'Kahve seviyorsun',                 color: '#c2410c' },
  'Tatlıcı':   { text: 'Tatlı krizine iyi gelecek',        color: '#be185d' },
  'Kahvaltı':  { text: 'Kahvaltı tutkunusun',              color: '#15803d' },
  'Mekan':      { text: 'Sosyal mekanları seviyorsun',      color: '#0e7490' },
  'Balık / Et': { text: 'Et ürünlerini tercih ediyorsun',  color: '#b45309' },
};

const AKTIVITE_TURLERI = [
  { icon: 'heart', label: 'Favorilere eklendi' },
  { icon: 'star',  label: '5 yıldız verdin' },
  { icon: 'eye',   label: 'Ziyaret ettin' },
] as const;

const ZAMAN = ['2 gün önce', '4 gün önce', '1 hafta önce'] as const;

const RUH_HALI = [
  { emoji: '⚡', title: 'Hızlı Bir Şeyler', desc: '15 dk içinde hazır',    bg: 'bg-amber-50',  border: 'border-amber-200',  tc: 'text-amber-700'  },
  { emoji: '🌙', title: 'Gece Atıştırmalık', desc: 'Geç saat açık olanlar', bg: 'bg-indigo-50', border: 'border-indigo-200', tc: 'text-indigo-700' },
  { emoji: '👥', title: 'Arkadaşınla',       desc: 'Grup için uygun',        bg: 'bg-sky-50',    border: 'border-sky-200',    tc: 'text-sky-700'    },
  { emoji: '🎁', title: 'Özel Bir Gün',      desc: 'Hafızalara değer',       bg: 'bg-rose-50',   border: 'border-rose-200',   tc: 'text-rose-700'   },
] as const;

// ── Yardımcılar ──────────────────────────────────────────────────────────────

function hash(s: string): number {
  return (s.split('').reduce((a, c) => (a * 31 + c.charCodeAt(0)) | 0, 0) >>> 0);
}

function uyumYuzde(id: string): number {
  return 82 + (hash(id) % 18); // 82–99
}

// ── Aktivite ikonu ────────────────────────────────────────────────────────────

function AktiviteIkon({ tip }: { tip: 'heart' | 'star' | 'eye' }) {
  if (tip === 'heart') return (
    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-rose-50">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="#e11d48" aria-hidden="true">
        <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
      </svg>
    </div>
  );
  if (tip === 'star') return (
    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-amber-50">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true">
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
      </svg>
    </div>
  );
  return (
    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-slate-100">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
      </svg>
    </div>
  );
}

// ── İşletme kartı ─────────────────────────────────────────────────────────────

function OneriKarti({ biz, tip }: { biz: OneriIsletme; tip: 'secilmis' | 'deneme' }) {
  const img = buildMenuImageUrl(biz.coverUrl ?? biz.logoUrl ?? null, { width: 480, quality: 78 })
    ?? '/category-images/restoran.webp';
  const uyum   = uyumYuzde(biz.id);
  const etiket = ETIKET_MAP[biz.category ?? ''] ?? { text: 'Sık tercih ettiğin mekan', color: '#7f1d1d' };

  return (
    <article className="group flex w-[220px] shrink-0 flex-col overflow-hidden rounded-2xl border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
      {/* Görsel */}
      <div className="relative h-[140px] w-full overflow-hidden">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={img} alt={biz.name} className="h-full w-full object-cover transition-transform group-hover:scale-105" loading="lazy" />

        {/* Rozet sol üst */}
        {tip === 'secilmis' ? (
          <div className="absolute left-2 top-2 rounded-full bg-success px-2.5 py-1 text-[11px] font-black text-white shadow-xs">
            %{uyum} Uyum
          </div>
        ) : (
          <div className="absolute left-2 top-2 rounded-full px-2.5 py-1 text-[11px] font-black text-white shadow-xs" style={{ background: '#7c3aed' }}>
            Yeni
          </div>
        )}

        {/* Favori sağ üst */}
        <button
          type="button"
          aria-label="Favorilere ekle"
          className="absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-white/90 text-muted shadow-sm backdrop-blur-sm transition-colors hover:text-primary"
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
          </svg>
        </button>
      </div>

      {/* İçerik */}
      <div className="flex flex-1 flex-col gap-1.5 p-3">
        <Link href={`/b/${biz.slug}`} className="line-clamp-1 text-sm font-black text-textStrong hover:text-primary">
          {biz.name}
        </Link>
        <p className="line-clamp-1 text-[11px] font-bold text-muted">
          {biz.category ?? '—'}
          {biz.district ? ` · ${biz.district}` : biz.city ? ` · ${biz.city}` : ''}
        </p>

        {biz.avgRating && biz.avgRating > 0 ? (
          <div className="flex items-center gap-1.5 text-[11px] font-extrabold">
            <span className="flex items-center gap-0.5 text-amber-500">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
              </svg>
              {biz.avgRating.toFixed(1)}
            </span>
            {biz.reviewsCount > 0 && (
              <span className="text-muted">({biz.reviewsCount.toLocaleString('tr-TR')})</span>
            )}
          </div>
        ) : null}

        {/* Insight etiketi */}
        <div className="mt-auto pt-1.5">
          <span
            className="inline-block rounded-full px-2.5 py-1 text-[10px] font-extrabold"
            style={{ background: `${etiket.color}18`, color: etiket.color }}
          >
            {etiket.text}
          </span>
        </div>
      </div>
    </article>
  );
}

// ── Yatay karusel bölümü ─────────────────────────────────────────────────────

function KarouselBolum({
  baslik, alt, tip, businesses,
}: {
  baslik: string; alt?: string; tip: 'secilmis' | 'deneme'; businesses: OneriIsletme[];
}) {
  const scrollRef = useRef<HTMLDivElement>(null);

  function kaydir(yon: 'sol' | 'sag') {
    if (!scrollRef.current) return;
    scrollRef.current.scrollBy({ left: yon === 'sag' ? 480 : -480, behavior: 'smooth' });
  }

  return (
    <section>
      <div className="mb-4 flex items-start justify-between gap-2">
        <div>
          <h2 className="flex items-center gap-2 text-lg font-black text-textStrong">
            {baslik}
            {tip === 'secilmis' && (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" className="text-muted" aria-label="Nasıl hesaplanıyor?">
                <circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>
              </svg>
            )}
          </h2>
          {alt && <p className="mt-0.5 text-sm text-muted">{alt}</p>}
        </div>
        {/* Tümünü gör + ok butonları */}
        <div className="flex shrink-0 items-center gap-2">
          <Link href="/kesif" className="text-sm font-black text-primary hover:underline whitespace-nowrap">
            Tümünü Gör →
          </Link>
          <div className="flex gap-1">
            <button
              type="button"
              onClick={() => kaydir('sol')}
              aria-label="Geri kaydır"
              className="flex h-8 w-8 items-center justify-center rounded-full border border-border bg-card text-muted shadow-yd1 transition-all hover:border-primary/40 hover:text-primary hover:shadow-yd2"
            >
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                <path d="m15 18-6-6 6-6"/>
              </svg>
            </button>
            <button
              type="button"
              onClick={() => kaydir('sag')}
              aria-label="İleri kaydır"
              className="flex h-8 w-8 items-center justify-center rounded-full border border-border bg-card text-muted shadow-yd1 transition-all hover:border-primary/40 hover:text-primary hover:shadow-yd2"
            >
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                <path d="m9 18 6-6-6-6"/>
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Scroll kapsayıcı */}
      <div className="relative">
        <div
          ref={scrollRef}
          className="flex gap-3 overflow-x-auto pb-2 [-ms-overflow-style:none] scrollbar-none [&::-webkit-scrollbar]:hidden"
        >
          {businesses.map((biz) => (
            <OneriKarti key={biz.id} biz={biz} tip={tip} />
          ))}
        </div>
      </div>
    </section>
  );
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

export function OneriCanli({ businesses }: { businesses: OneriIsletme[] }) {
  const [spinning, setSpinning] = useState(false);

  // Sidebar: kategori dağılımı
  const kategoriDagilim = useMemo(() => {
    const sayac: Record<string, number> = {};
    for (const b of businesses) {
      if (b.category) sayac[b.category] = (sayac[b.category] ?? 0) + 1;
    }
    return Object.entries(sayac)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([kat], i) => ({
        kat,
        pct:      [38, 27, 18][i] ?? 10,
        subtitle: ['En çok tercih ettiğin', 'Sık tercih ettiğin', 'Sevdiğin mutfak'][i] ?? '',
        color:    ['#ef4444', '#f97316', '#22c55e'][i] ?? '#94a3b8',
      }));
  }, [businesses]);

  // Sidebar: son aktiviteler
  const aktiviteler = useMemo(() =>
    businesses.slice(0, 3).map((b, i) => ({
      biz:  b,
      tip:  AKTIVITE_TURLERI[i % AKTIVITE_TURLERI.length]!,
      zaman: ZAMAN[i] ?? '1 hafta önce',
    })),
  [businesses]);

  const secilmisler = businesses.slice(0, 8);
  const denemeler   = businesses.slice(8, 16);

  function handleYenile() {
    setSpinning(true);
    setTimeout(() => setSpinning(false), 700);
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">

        {/* Başlık */}
        <div className="mb-8 flex items-start justify-between gap-4">
          <div>
            <h1 className="flex items-center gap-2 text-2xl font-black text-textStrong sm:text-3xl">
              Akıllı Öneri
              <span className="text-amber-400" aria-hidden="true">✦</span>
            </h1>
            <p className="mt-1 text-sm font-bold text-muted">
              Zevklerine ve alışkanlıklarına göre senin için seçtik!
            </p>
          </div>
          <button
            type="button"
            onClick={handleYenile}
            className="flex shrink-0 items-center gap-2 rounded-xl border border-border bg-card px-4 py-2.5 text-sm font-extrabold text-textStrong shadow-yd1 transition-all hover:border-primary/40 hover:text-primary"
          >
            <svg
              width="14" height="14" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"
              className={spinning ? 'animate-spin' : ''} aria-hidden="true"
            >
              <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/>
              <path d="M21 3v5h-5M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/>
            </svg>
            Önerileri Yenile
          </button>
        </div>

        {/* İki sütun */}
        <div className="flex flex-col gap-8 lg:flex-row lg:items-start">

          {/* ── Sol sidebar ──────────────────────────────────────────────── */}
          <aside className="w-full space-y-5 lg:w-64 lg:shrink-0 lg:sticky lg:top-20 lg:self-start">

            {/* Zevkler */}
            <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
              <h3 className="mb-3 text-sm font-black text-textStrong">Senin Zevklerine Göre</h3>
              <div className="space-y-3">
                {kategoriDagilim.map(({ kat, pct, subtitle, color }) => {
                  const KatIcon = KAT_ICON[kat] ?? Utensils;
                  return (
                  <div key={kat} className="flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/5 text-primary">
                      <KatIcon size={18} aria-hidden="true" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-black text-textStrong leading-tight">{kat}</p>
                      <p className="text-[11px] font-bold text-muted">{subtitle}</p>
                    </div>
                    <span
                      className="shrink-0 rounded-full px-2 py-0.5 text-[11px] font-black"
                      style={{ background: `${color}20`, color }}
                    >
                      %{pct}
                    </span>
                  </div>
                  );
                })}
              </div>
              <Link href="/kesif" className="mt-4 flex items-center gap-1 text-xs font-black text-primary hover:underline">
                Tüm tercihlerini gör
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                  <path d="m9 18 6-6-6-6"/>
                </svg>
              </Link>
            </div>

            {/* Son aktiviteler */}
            <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
              <h3 className="mb-3 text-sm font-black text-textStrong">Son Aktivitelerin</h3>
              <div className="space-y-3">
                {aktiviteler.map(({ biz, tip, zaman }) => (
                  <div key={biz.id} className="flex items-center gap-2.5">
                    <AktiviteIkon tip={tip.icon} />
                    <div className="min-w-0 flex-1">
                      <p className="line-clamp-1 text-sm font-black text-textStrong">{biz.name}</p>
                      <p className="text-[11px] font-bold text-muted">{tip.label}</p>
                    </div>
                    <span className="shrink-0 text-[11px] font-bold text-muted">{zaman}</span>
                  </div>
                ))}
              </div>
              <Link href="/kesif" className="mt-4 flex items-center gap-1 text-xs font-black text-primary hover:underline">
                Tüm aktiviteleri gör
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                  <path d="m9 18 6-6-6-6"/>
                </svg>
              </Link>
            </div>

            {/* Bugünkü puan */}
            <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
              <h3 className="mb-3 text-sm font-black text-textStrong">Bugünkü Öneri Puanın</h3>
              <div className="flex items-center gap-3">
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full border-2 border-success/30 bg-success/10 text-xl font-black text-success">
                  88
                </div>
                <p className="text-sm font-extrabold text-textStrong">⭐⭐ Harika seçimler yapıyorsun! 🎉</p>
              </div>
              <div className="mt-3 h-2.5 w-full overflow-hidden rounded-full bg-slate-100">
                <div
                  className="h-full rounded-full bg-success"
                  style={{ width: '88%' }}
                  role="progressbar"
                  aria-valuenow={88}
                  aria-valuemin={0}
                  aria-valuemax={100}
                />
              </div>
              <p className="mt-2 text-[11px] font-bold text-muted">Dün: 88 · Geçen Hafta: 91</p>
            </div>
          </aside>

          {/* ── Sağ: asıl içerik ─────────────────────────────────────────── */}
          <div className="min-w-0 flex-1 space-y-10">

            {secilmisler.length > 0 && (
              <KarouselBolum baslik="Senin İçin Seçtiklerimiz" tip="secilmis" businesses={secilmisler} />
            )}

            {denemeler.length > 0 && (
              <KarouselBolum
                baslik="Denemeni Öneririz"
                alt="Daha önce gitmediğin ama sevebileceğin mekanlar"
                tip="deneme"
                businesses={denemeler}
              />
            )}

            {/* Durumuna göre */}
            <section>
              <div className="mb-4 flex items-start justify-between gap-2">
                <h2 className="text-lg font-black text-textStrong">Durumuna Göre Öneriler</h2>
                <Link href="/kesif" className="shrink-0 text-sm font-black text-primary hover:underline">
                  Tümünü Gör →
                </Link>
              </div>
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                {RUH_HALI.map((rh) => (
                  <Link
                    key={rh.title}
                    href="/kesif"
                    className={`flex flex-col items-center gap-2 rounded-2xl border p-4 text-center transition-all hover:-translate-y-0.5 hover:shadow-yd1 ${rh.bg} ${rh.border}`}
                  >
                    <span className="text-2xl" aria-hidden="true">{rh.emoji}</span>
                    <p className={`text-sm font-black ${rh.tc}`}>{rh.title}</p>
                    <p className="text-[11px] font-bold text-muted">{rh.desc}</p>
                  </Link>
                ))}
              </div>
            </section>

            {/* CTA banner */}
            <div className="flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-primary px-6 py-5">
              <div className="flex items-center gap-4">
                <span className="text-2xl" aria-hidden="true">🎁</span>
                <div>
                  <p className="text-base font-black text-white">
                    Ne kadar çok keşfedersen, o kadar iyi öneririz!
                  </p>
                  <p className="mt-0.5 text-sm font-bold text-white/70">
                    Yorum yap, favorilerine ekle, mekanları değerlendir.
                  </p>
                </div>
              </div>
              <Link
                href="/kesif"
                className="flex h-11 shrink-0 items-center gap-2 rounded-xl bg-white px-5 text-sm font-black text-primary shadow-xs transition-all hover:brightness-105 whitespace-nowrap"
              >
                Keşfetmeye Devam Et
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                  <path d="m9 18 6-6-6-6"/>
                </svg>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
