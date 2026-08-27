'use client';

import { useRef } from 'react';
import type { ComponentType } from 'react';
import Link from 'next/link';
import { Utensils, Coffee, Cake, Egg, Beer, Beef, Zap, Users, Gift, type LucideProps } from 'lucide-react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

// ── Tipler ───────────────────────────────────────────────────────────────────

export type OneriIsletme = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null; district: string | null;
  logoUrl: string | null; coverUrl: string | null;
  isVerified: boolean; reviewsCount: number; avgRating: number | null;
  eslesmeYuzde: number | null;
};

export type OneriTercih = { category: string; interaction_count: number; pct: number };

export type OneriAktivite = {
  businessId: string;
  businessName: string;
  slug: string;
  activityType: 'favorite' | 'review' | 'visit';
  createdAt: string;
};

type Props = {
  loggedIn: boolean;
  secilmisler: OneriIsletme[];
  denemeler: OneriIsletme[];
  tercihler: OneriTercih[];
  aktiviteler: OneriAktivite[];
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

// Her ruh hali gerçek bir /kesif filtresine bağlanır. "Açık şu an" veya "grup
// kapasitesi" gibi neredeyse hiç dolu olmayan alanlar (42K işletmenin sadece 1'inde
// is_open_now dolu, rezervasyon kapasitesi hiç yok) kullanılmadı — hatta is_verified
// ve avg_rating>=4.5 kombinasyonu bile production'da TAMAMEN BOŞ (sıfır işletme
// doğrulanmış). Bu yüzden dört karo da, gerçekten dolu tek güçlü sinyal olan
// business.category üzerine kuruldu (Restoran 544, Kafe 232, Balık/Et 162,
// Tatlıcı 46 — hiçbiri boş sonuç riski taşımıyor).
const RUH_HALI = [
  { icon: Zap,   title: 'Hızlı Bir Şeyler', desc: 'Kafe tadında hızlı seçenekler',   bg: 'bg-amber-50',  border: 'border-amber-200',  tc: 'text-amber-700',  href: `/kesif?category=${encodeURIComponent('Kafe')}` },
  { icon: Cake,  title: 'Tatlı Krizi',      desc: 'Tatlıcılar ve atıştırmalıklar',    bg: 'bg-indigo-50', border: 'border-indigo-200', tc: 'text-indigo-700', href: `/kesif?category=${encodeURIComponent('Tatlıcı')}` },
  { icon: Users, title: 'Arkadaşınla',      desc: 'Paylaşarak yenen et ve balık mekanları', bg: 'bg-sky-50', border: 'border-sky-200', tc: 'text-sky-700',   href: `/kesif?category=${encodeURIComponent('Balık / Et')}` },
  { icon: Gift,  title: 'Özel Bir Gün',     desc: 'En yüksek puanlı mekanlar',        bg: 'bg-rose-50',   border: 'border-rose-200',   tc: 'text-rose-700',   href: '/kesif?sort=rating' },
] as const;

// ── Yardımcılar ──────────────────────────────────────────────────────────────

function zamanFarki(iso: string): string {
  const gun = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
  if (gun < 1) return 'Bugün';
  if (gun < 7) return `${gun} gün önce`;
  const hafta = Math.floor(gun / 7);
  if (hafta < 5) return `${hafta} hafta önce`;
  return `${Math.floor(gun / 30)} ay önce`;
}

const AKTIVITE_ETIKET: Record<OneriAktivite['activityType'], string> = {
  favorite: 'Favorilere eklendi',
  review:   'Yorum yaptın',
  visit:    'Ziyaret ettin',
};

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
  const etiket = ETIKET_MAP[biz.category ?? ''] ?? { text: 'Sık tercih ettiğin mekan', color: '#7f1d1d' };

  return (
    <Link href={`/isletme/${biz.slug}`} className="group flex w-[220px] shrink-0 flex-col overflow-hidden rounded-2xl border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
      <div className="relative h-[140px] w-full overflow-hidden">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={img} alt={biz.name} className="h-full w-full object-cover transition-transform group-hover:scale-105" loading="lazy" />

        {biz.eslesmeYuzde != null ? (
          <div className="absolute left-2 top-2 rounded-full bg-success px-2.5 py-1 text-[11px] font-black text-white shadow-xs">
            %{biz.eslesmeYuzde} Uyum
          </div>
        ) : (
          <div className="absolute left-2 top-2 rounded-full bg-primary px-2.5 py-1 text-[11px] font-black text-white shadow-xs">
            Popüler
          </div>
        )}
        {tip === 'deneme' && (
          <div className="absolute left-2 top-9 rounded-full px-2.5 py-1 text-[11px] font-black text-white shadow-xs" style={{ background: '#7c3aed' }}>
            Yeni
          </div>
        )}

        {/* Favori butonu — değişmedi */}
        <button
          type="button"
          aria-label="Favorilere ekle"
          onClick={(e) => e.preventDefault()}
          className="absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-white/90 text-muted shadow-sm backdrop-blur-sm transition-colors hover:text-primary"
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
          </svg>
        </button>
      </div>

      <div className="flex flex-1 flex-col gap-1.5 p-3">
        <p className="line-clamp-1 text-sm font-black text-textStrong group-hover:text-primary">{biz.name}</p>
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
            {biz.reviewsCount > 0 && <span className="text-muted">({biz.reviewsCount.toLocaleString('tr-TR')})</span>}
          </div>
        ) : null}
        <div className="mt-auto pt-1.5">
          <span className="inline-block rounded-full px-2.5 py-1 text-[10px] font-extrabold" style={{ background: `${etiket.color}18`, color: etiket.color }}>
            {etiket.text}
          </span>
        </div>
      </div>
    </Link>
  );
}

// ── Yatay karusel bölümü ─────────────────────────────────────────────────────

function KarouselBolum({
  baslik, alt, tip, businesses, tumunuGorHref,
}: {
  baslik: string; alt?: string; tip: 'secilmis' | 'deneme'; businesses: OneriIsletme[]; tumunuGorHref: string;
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
          <Link href={tumunuGorHref} className="text-sm font-black text-primary hover:underline whitespace-nowrap">
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

export function OneriCanli({ loggedIn, secilmisler, denemeler, tercihler, aktiviteler }: Props) {
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
        </div>

        {/* İki sütun */}
        <div className="flex flex-col gap-8 lg:flex-row lg:items-start">

          {/* Sol sidebar */}
          <aside className="w-full space-y-5 lg:w-64 lg:shrink-0 lg:sticky lg:top-20 lg:self-start">
            {loggedIn ? (
              <>
                {tercihler.length > 0 && (
                  <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
                    <h2 className="mb-3 text-sm font-black text-textStrong">Senin Zevklerine Göre</h2>
                    <div className="space-y-3">
                      {tercihler.map(({ category, pct }) => {
                        const KatIcon = KAT_ICON[category] ?? Utensils;
                        return (
                          <div key={category} className="flex items-center gap-3">
                            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/5 text-primary">
                              <KatIcon size={18} aria-hidden="true" />
                            </div>
                            <div className="min-w-0 flex-1">
                              <p className="text-sm font-black text-textStrong leading-tight">{category}</p>
                            </div>
                            <span className="shrink-0 rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-black text-primary">
                              %{pct}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}

                {aktiviteler.length > 0 && (
                  <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
                    <h2 className="mb-3 text-sm font-black text-textStrong">Son Aktivitelerin</h2>
                    <div className="space-y-3">
                      {aktiviteler.map((a) => (
                        <Link key={`${a.businessId}-${a.createdAt}`} href={`/isletme/${a.slug}`} className="flex items-center gap-2.5 hover:opacity-80">
                          <AktiviteIkon tip={a.activityType === 'favorite' ? 'heart' : a.activityType === 'review' ? 'star' : 'eye'} />
                          <div className="min-w-0 flex-1">
                            <p className="line-clamp-1 text-sm font-black text-textStrong">{a.businessName}</p>
                            <p className="text-[11px] font-bold text-muted">{AKTIVITE_ETIKET[a.activityType]}</p>
                          </div>
                          <span className="shrink-0 text-[11px] font-bold text-muted">{zamanFarki(a.createdAt)}</span>
                        </Link>
                      ))}
                    </div>
                  </div>
                )}

                {tercihler.length === 0 && aktiviteler.length === 0 && (
                  <div className="rounded-2xl border border-border bg-card p-4 shadow-yd1">
                    <h2 className="mb-1.5 text-sm font-black text-textStrong">Henüz veri yok</h2>
                    <p className="text-[12px] font-bold text-muted">
                      Favorilerine ekle, yorum yap veya ziyaretlerini işaretle — sana özel önerileri burada göreceksin.
                    </p>
                  </div>
                )}
              </>
            ) : (
              <div className="rounded-2xl border border-primary/20 bg-primary/5 p-4 shadow-yd1">
                <h2 className="mb-1.5 text-sm font-black text-textStrong">Sana özel öneriler için giriş yap</h2>
                <p className="mb-3 text-[12px] font-bold text-muted">
                  Zevklerine göre eşleşme skorları ve son aktivitelerin burada görünsün.
                </p>
                <Link href="/giris" className="flex h-10 items-center justify-center rounded-xl bg-primary text-sm font-black text-white transition-all hover:brightness-110">
                  Giriş Yap / Üye Ol
                </Link>
              </div>
            )}
          </aside>

          {/* ── Sağ: asıl içerik ─────────────────────────────────────────── */}
          <div className="min-w-0 flex-1 space-y-10">

            {secilmisler.length > 0 && (
              <KarouselBolum
                baslik="Senin İçin Seçtiklerimiz"
                tip="secilmis"
                businesses={secilmisler}
                tumunuGorHref="/kesif?sort=rating"
              />
            )}

            {loggedIn && denemeler.length > 0 && (
              <KarouselBolum
                baslik="Denemeni Öneririz"
                alt="Daha önce gitmediğin ama sevebileceğin mekanlar"
                tip="deneme"
                businesses={denemeler}
                tumunuGorHref="/kesif?sort=reviews"
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
                    href={rh.href}
                    className={`flex flex-col items-center gap-2 rounded-2xl border p-4 text-center transition-all hover:-translate-y-0.5 hover:shadow-yd1 ${rh.bg} ${rh.border}`}
                  >
                    <rh.icon className={`h-6 w-6 ${rh.tc}`} aria-hidden="true" />
                    <p className={`text-sm font-black ${rh.tc}`}>{rh.title}</p>
                    <p className="text-[11px] font-bold text-muted">{rh.desc}</p>
                  </Link>
                ))}
              </div>
            </section>

            {/* CTA banner */}
            <div className="flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-primary px-6 py-5">
              <div className="flex items-center gap-4">
                <Gift className="h-7 w-7 text-white" aria-hidden="true" />
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
