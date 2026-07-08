import type { Metadata } from 'next';
import Link from 'next/link';
import { Suspense } from 'react';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { KesifCanli } from '@/src/ui/acik/kesif-canli';
import { appConfig } from '@/src/lib/ayarlar';

export const metadata: Metadata = (() => {
  const siteUrl = appConfig.siteUrl().replace(/\/$/, '');
  const canonical = `${siteUrl}/kesif`;
  return {
    title: 'Keşfet | Yeedoy',
    description: 'Restoran, kafe ve menüleri kategori, şehir ve yorumla anlık olarak keşfet.',
    alternates: { canonical },
    openGraph: {
      title: 'Keşfet | Yeedoy',
      description: 'Şehrindeki işletmeleri ve menüleri keşfet.',
      url: canonical,
      images: [{ url: `${siteUrl}/sunucu/acik-grafik?title=Ke%C5%9Ffet`, width: 1200, height: 630, alt: 'Keşfet | Yeedoy' }],
    },
  };
})();

const KATEGORI_CIPS = [
  { id: 'döner',    label: 'Döner',    img: '/category-images/doner.webp' },
  { id: 'pide',     label: 'Pide',     img: '/category-images/pide.webp' },
  { id: 'burger',   label: 'Burger',   img: '/category-images/burger.webp' },
  { id: 'pizza',    label: 'Pizza',    img: '/category-images/pizza.webp' },
  { id: 'kebap',    label: 'Kebap',    img: '/category-images/kebap.webp' },
  { id: 'lahmacun', label: 'Lahmacun', img: '/category-images/lahmacun.webp' },
  { id: 'kahvaltı', label: 'Kahvaltı', img: '/category-images/kahvalti.webp' },
  { id: 'tatlı',   label: 'Tatlı',    img: '/category-images/tatli.webp' },
  { id: 'çorba',   label: 'Çorba',    img: '/category-images/corba.webp' },
  { id: 'mantı',   label: 'Mantı',    img: '/category-images/manti.webp' },
  { id: 'kafe',    label: 'Kafe',     img: '/category-images/cafe.webp' },
];

const OZELLIKLER = [
  {
    icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>,
    title: 'Hızlı Keşfet',
    desc: 'Yakınındaki mekanları keşfet',
  },
  {
    icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>,
    title: 'Güvenilir Yorumlar',
    desc: 'Gerçek kullanıcı yorumları',
  },
  {
    icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="20 12 20 22 4 22 4 12" /><rect x="2" y="7" width="20" height="5" /><line x1="12" y1="22" x2="12" y2="7" /><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z" /><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z" /></svg>,
    title: 'Özel Kampanyalar',
    desc: 'Sana özel fırsatlar',
  },
  {
    icon: <svg viewBox="0 0 24 24" className="h-5 w-5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" /></svg>,
    title: 'Favorilerini Kaydet',
    desc: 'Beğendiğin mekanları kolayca bul',
  },
];

export default function DiscoverPage() {
  return (
    <PublicShell>
      <main className="min-h-screen bg-bg">

        {/* ── Hero ─────────────────────────────────────────────────────────── */}
        <div className="border-b border-border bg-bg px-4 py-7 sm:py-9">
          <div className="mx-auto max-w-6xl px-0 sm:px-2">
            <h1 className="text-2xl font-[900] leading-tight text-textStrong sm:text-3xl">
              Keşfetmeye hazır mısın?
            </h1>
            <p className="mt-1.5 text-sm text-muted">
              Yakınındaki en iyi lezzetleri anlık filtrelerle keşfet.
            </p>
          </div>
        </div>

        {/* ── Kategori cipsleri (hızlı navigasyon) ─────────────────────────── */}
        <div className="border-b border-border bg-bg">
          <div className="mx-auto max-w-6xl px-4 sm:px-6">
            <div className="flex items-end gap-4 overflow-x-auto py-4 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {KATEGORI_CIPS.map((cat) => (
                <Link
                  key={cat.id}
                  href={`/kesif?category=${encodeURIComponent(cat.id)}`}
                  className="group flex shrink-0 flex-col items-center gap-1.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
                >
                  <div className="flex h-[68px] w-[68px] items-center justify-center overflow-hidden rounded-[22px] bg-white shadow-yd1 transition-all group-hover:-translate-y-0.5 group-hover:shadow-yd2">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={cat.img} alt={cat.label} width={68} height={68} className="h-full w-full object-cover" />
                  </div>
                  <span className="whitespace-nowrap text-[11px] font-[900] text-textStrong transition-colors group-hover:text-primary">
                    {cat.label}
                  </span>
                </Link>
              ))}

              <Link
                href="/kesif"
                className="group flex shrink-0 flex-col items-center gap-1.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              >
                <div
                  className="flex h-[68px] w-[68px] items-center justify-center rounded-[22px] shadow-yd1 transition-all group-hover:-translate-y-0.5 group-hover:shadow-yd2"
                  style={{ background: 'var(--yd-gradient-primary)' }}
                >
                  <svg viewBox="0 0 24 24" className="h-7 w-7 fill-current text-white" aria-hidden="true">
                    <path d="M4 6h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4zM4 12h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4zM4 18h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4z" />
                  </svg>
                </div>
                <span className="whitespace-nowrap text-[11px] font-[900] text-primary">Tümü</span>
              </Link>

              <Link
                href="/kesif/harita"
                className="group flex shrink-0 flex-col items-center gap-1.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              >
                <div className="flex h-[68px] w-[68px] items-center justify-center rounded-2xl bg-cardAlt shadow-yd1 transition-all group-hover:-translate-y-0.5 group-hover:shadow-yd2">
                  <svg viewBox="0 0 24 24" className="h-6 w-6 fill-none stroke-current stroke-2 text-muted group-hover:text-primary" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21" /><line x1="9" y1="3" x2="9" y2="18" /><line x1="15" y1="6" x2="15" y2="21" />
                  </svg>
                </div>
                <span className="whitespace-nowrap text-[11px] font-[900] text-muted group-hover:text-primary">Harita</span>
              </Link>
            </div>
          </div>
        </div>

        {/* ── Promo banner'lar ─────────────────────────────────────────────── */}
        <div className="mx-auto max-w-6xl px-4 py-6 sm:px-6">
          <div className="mb-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
            <div
              className="relative flex min-h-[148px] items-center overflow-hidden rounded-2xl p-5"
              style={{ background: 'linear-gradient(135deg, #14532d 0%, #166534 100%)' }}
            >
              <div className="relative z-10 flex-1">
                <p className="text-[15px] font-[900] leading-snug text-white">Lezzetli fırsatlar seni bekliyor!</p>
                <p className="mt-1.5 text-xs leading-relaxed text-white/70">En iyi kampanyaları kaçırma.</p>
                <Link href="/kampanyalar" className="mt-4 inline-flex h-9 items-center rounded-xl bg-primary px-4 text-sm font-[900] text-white shadow-sm transition-all hover:brightness-110">
                  Kampanyalara Git
                </Link>
              </div>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/promo-burgerkola.webp" alt="" aria-hidden="true" className="absolute -bottom-2 right-0 h-[140px] w-auto object-contain drop-shadow-lg select-none" />
            </div>
            <div
              className="relative flex min-h-[148px] items-center overflow-hidden rounded-2xl p-5"
              style={{ background: 'linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%)' }}
            >
              <div className="relative z-10 flex-1">
                <p className="text-[15px] font-[900] leading-snug text-textStrong">Bugün ne yesem?</p>
                <p className="mt-1.5 text-xs leading-relaxed text-muted">Senin için önerilerimiz var.</p>
                <Link href="/oneri" className="mt-4 inline-flex h-9 items-center rounded-xl bg-success px-4 text-sm font-[900] text-white shadow-sm transition-all hover:brightness-110">
                  Önerilere Bak
                </Link>
              </div>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/promo-salata.webp" alt="" aria-hidden="true" className="absolute -bottom-2 -right-4 h-[140px] w-auto object-contain drop-shadow-lg select-none" />
            </div>
          </div>

          {/* ── Canlı filtreleme ─────────────────────────────────────────────── */}
          <Suspense fallback={
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="overflow-hidden rounded-[20px] border border-border bg-card">
                  <div className="w-full animate-pulse bg-border" style={{ aspectRatio: '4/3' }} />
                  <div className="space-y-2 p-3">
                    <div className="h-4 w-3/4 animate-pulse rounded bg-border" />
                    <div className="h-3 w-1/2 animate-pulse rounded bg-border" />
                    <div className="mt-3 h-8 animate-pulse rounded-lg bg-border" />
                  </div>
                </div>
              ))}
            </div>
          }>
            <KesifCanli />
          </Suspense>
        </div>

        {/* ── Alt özellikler ────────────────────────────────────────────────── */}
        <div className="border-t border-border bg-bg px-4 py-8">
          <div className="mx-auto grid max-w-6xl grid-cols-2 gap-6 sm:px-6 md:grid-cols-4">
            {OZELLIKLER.map((o) => (
              <div key={o.title} className="flex items-start gap-3">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
                  {o.icon}
                </span>
                <div>
                  <p className="text-sm font-[800] text-textStrong">{o.title}</p>
                  <p className="mt-0.5 text-xs leading-relaxed text-muted">{o.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

      </main>
    </PublicShell>
  );
}
