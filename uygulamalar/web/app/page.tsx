import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { Search, Shield, BarChart2, CheckCircle, ChevronRight, Star, ArrowRight } from 'lucide-react';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { Container } from '@/src/ui/acik/ortak';
import { AnlikArama } from '@/src/ui/acik/anlik-arama';
import { getTopMarketplaceBusinesses } from '@/src/lib/veri/pazar-okuma';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import type { AcikIsletmeKarti } from '@/src/ui/acik/tipler';
import { KonumIzniIstemcisi } from '@/src/ui/acik/konum-izni';
import { YakindakiIsletmeler } from '@/src/ui/acik/yakin-isletmeler';

export const revalidate = 60;

export const metadata: Metadata = {
  title: 'Yeedoy — Lezzetleri Keşfet, Fiyatları Karşılaştır',
  description:
    'Yakınındaki restoranları, kafeleri ve menüleri keşfet. Gerçek kullanıcı yorumları, güncel fiyatlar ve toplulukça doğrulanmış bilgilerle en iyi lezzet deneyimini yaşa.',
  alternates: { canonical: '/' },
};

const HOMEPAGE_CATEGORIES = [
  { id: 'döner',           label: 'Döner',      img: '/category-images/doner.webp' },
  { id: 'pide',            label: 'Pide',        img: '/category-images/pide.webp' },
  { id: 'burger',          label: 'Burger',      img: '/category-images/burger.webp' },
  { id: 'pizza',           label: 'Pizza',       img: '/category-images/pizza.webp' },
  { id: 'kebap',           label: 'Kebap',       img: '/category-images/kebap.webp' },
  { id: 'lahmacun',        label: 'Lahmacun',    img: '/category-images/lahmacun.webp' },
  { id: 'kahvaltı',        label: 'Kahvaltı',    img: '/category-images/kahvalti.webp' },
  { id: 'tatlı',           label: 'Tatlı',       img: '/category-images/tatli.webp' },
  { id: 'çorba',           label: 'Çorba',       img: '/category-images/corba.webp' },
  { id: 'mantı',           label: 'Mantı',       img: '/category-images/manti.webp' },
  { id: 'kafe',            label: 'Kafe',        img: '/category-images/cafe.webp' },
];

const POPULAR_SEARCHES = [
  'Adana Kebap',
  'Pide',
  'Kahvaltı',
  'Tatlı',
  'Dürüm',
  'Kahve',
];

const TESTIMONIALS = [
  {
    name: 'Mehmet A.',
    time: '2 gün önce',
    text: 'Fiyat geçmişi özelliği sayesinde gitmeden önce fiyatları görebiliyorum. Harika bir uygulama!',
  },
  {
    name: 'Ece Y.',
    time: '1 hafta önce',
    text: 'Topluluğun katkıları sayesinde bilgiler hep güncel. Güvenle tercih ediyorum.',
  },
  {
    name: 'Ahmet K.',
    time: '3 gün önce',
    text: 'Kampanyalar kısmı gerçekten çok faydalı, indirimleri kaçırmıyorum.',
  },
];

const CATEGORY_IMAGES: Record<string, string> = {
  kafe: '/category-images/cafe.webp',
  cafe: '/category-images/cafe.webp',
  restoran: '/category-images/restoran.webp',
  restaurant: '/category-images/restoran.webp',
  dönerci: '/category-images/doner.webp',
  döner: '/category-images/doner.webp',
  doner: '/category-images/doner.webp',
  burger: '/category-images/burger.webp',
  pizza: '/category-images/pizza.webp',
  kebap: '/category-images/kebap.webp',
  kebab: '/category-images/kebap.webp',
  pide: '/category-images/pide.webp',
  lahmacun: '/category-images/lahmacun.webp',
  'pide / lahmacun': '/category-images/pide.webp',
  kahvaltı: '/category-images/kahvalti.webp',
  breakfast: '/category-images/kahvalti.webp',
  tatlı: '/category-images/tatli.webp',
  pastane: '/category-images/tatlici.webp',
  'tatlı / pastane': '/category-images/tatli.webp',
  çorba: '/category-images/corba.webp',
  mantı: '/category-images/manti.webp',
};

function categoryFallbackImage(category?: string | null): string {
  if (!category) return '/category-images/restoran.webp';
  const key = category.toLowerCase().trim();
  return CATEGORY_IMAGES[key] ?? '/category-images/restoran.webp';
}

function PriceLevelBadge({ priceLevel }: { priceLevel?: string | null }) {
  const map: Record<string, string> = { budget: '₺', mid: '₺₺', premium: '₺₺₺' };
  const label = priceLevel ? (map[priceLevel] ?? null) : null;
  if (!label) return null;
  return (
    <span className="rounded-full border border-border bg-bg px-2 py-0.5 text-[10px] font-extrabold text-muted">
      {label}
    </span>
  );
}

function BusinessCard({ biz, priority = false }: { biz: AcikIsletmeKarti; priority?: boolean }) {
  const slug = biz.publicSlug ?? biz.slug;
  const rating = biz.avgRating;
  const coverSrc = buildMenuImageUrl(biz.coverUrl ?? biz.logoUrl, { width: 600, quality: 80 })
    ?? categoryFallbackImage(biz.category);
  return (
    <Link
      href={`/isletme/${slug}`}
      className="group flex flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2"
    >
      {/* Cover — 16:10 like mobile */}
      <div className="relative w-full overflow-hidden" style={{ aspectRatio: '16/10' }}>
        <Image
          src={coverSrc}
          alt=""
          fill
          sizes="(max-width: 640px) 50vw, 300px"
          priority={priority}
          className="object-cover transition-transform group-hover:scale-105"
        />
        {/* Rating badge — top-left white pill */}
        {rating != null && (
          <div className="absolute left-2 top-2 flex items-center gap-1 rounded-xl bg-white/92 px-2 py-1 text-xs font-extrabold shadow-xs backdrop-blur-sm">
            <Star size={11} className="fill-amber-400 text-amber-400" aria-hidden="true" />
            <span className="text-textStrong">{rating.toFixed(1)}</span>
          </div>
        )}
        {/* Open/Closed — top-right */}
        {biz.isOpenNow != null && (
          <div className={`absolute right-2 top-2 rounded-xl px-2 py-1 text-[10px] font-black backdrop-blur-sm ${biz.isOpenNow ? 'bg-success/15 text-success' : 'bg-danger/15 text-danger'}`}>
            {biz.isOpenNow ? 'Açık' : 'Kapalı'}
          </div>
        )}
      </div>
      {/* Info */}
      <div className="flex flex-1 flex-col gap-1 p-3">
        <p className="line-clamp-1 text-sm font-black text-textStrong">{biz.name}</p>
        <p className="line-clamp-1 text-xs text-muted">
          {[biz.category, biz.city].filter(Boolean).join(' · ')}
        </p>
        <div className="mt-auto flex items-center gap-2 pt-1">
          <PriceLevelBadge priceLevel={biz.priceLevel} />
          {biz.isVerified && (
            <span className="flex items-center gap-1 text-[10px] font-extrabold text-primary">
              <CheckCircle size={11} aria-hidden="true" /> Doğrulandı
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}

export default async function HomePage() {
  const topBusinesses = await getTopMarketplaceBusinesses(6).catch(() => [] as AcikIsletmeKarti[]);

  const supabase = createSupabasePublicClient();
  const campaigns = await (supabase as any)
    .from('business_campaigns')
    .select('id,title,discount_pct,businesses(name,slug)')
    .eq('is_active', true)
    .gte('valid_until', new Date().toISOString())
    .order('discount_pct', { ascending: false })
    .limit(3)
    .then((r: any) => (r?.data as any[]) ?? [])
    .catch(() => []);

  const featuredBusinesses = topBusinesses.slice(0, 4);

  return (
    <PublicShell>
      <main>
        {/* ── Hero ───────────────────────────────────────────────────────── */}
        <section
          className="relative overflow-hidden border-b border-border"
          style={{
            background:
              'radial-gradient(ellipse at 18% 0%, rgba(127,29,29,0.10) 0%, transparent 55%), radial-gradient(ellipse at 82% 100%, rgba(127,29,29,0.06) 0%, transparent 55%), var(--yd-color-card-alt)',
          }}
        >
          <Container className="grid gap-8 py-8 lg:grid-cols-[1fr_420px] lg:gap-16 lg:py-12">
            {/* Left */}
            <div className="flex flex-col justify-center">
              {/* Badge */}
              <div className="mb-5 inline-flex w-fit items-center gap-2 rounded-full border border-primary/25 bg-primary/10 px-3 py-1.5">
                <span className="h-1.5 w-1.5 rounded-full bg-primary" />
                <span className="text-xs font-black uppercase tracking-wide text-primary">
                  Türkiye&apos;nin lezzet haritası
                </span>
              </div>

              <h1 className="text-3xl font-black leading-[1.07] text-textStrong sm:text-4xl lg:text-[44px]">
                Lezzetleri keşfet,{' '}
                <span
                  style={{
                    background: 'var(--yd-gradient-primary)',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                    backgroundClip: 'text',
                  }}
                >
                  menü fiyatlarını
                </span>{' '}
                karşılaştır, fırsatları kaçırma!
              </h1>

              <p className="mt-4 max-w-lg text-base leading-7 text-muted">
                Yakınındaki restoranların güncel menülerini, fiyat geçmişlerini gör ve topluluğumuzla en doğru bilgilere ulaş.
              </p>

              {/* Search */}
              <div className="relative z-20 mt-7">
                <AnlikArama />
              </div>

              {/* Popular */}
              <div className="mt-4 flex flex-wrap items-center gap-2">
                <span className="text-xs font-extrabold text-muted">Popüler:</span>
                {POPULAR_SEARCHES.map((term) => (
                  <Link
                    key={term}
                    href={`/kesif?q=${encodeURIComponent(term)}`}
                    className="rounded-full border border-border bg-card px-3 py-1 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/35 hover:text-primary"
                  >
                    {term}
                  </Link>
                ))}
              </div>
            </div>

            {/* Right — hero görsel (telefon + yemek, transparan PNG) */}
            <div className="hidden lg:flex lg:items-end lg:justify-center">
              <Image
                src="/hero-gorsel.webp"
                alt="Yeedoy mobil uygulama ve yemek görseli"
                width={720}
                height={640}
                priority
                className="max-h-[480px] w-auto object-contain drop-shadow-2xl"
              />
            </div>
          </Container>

          {/* ── Kategori satırı — hero içinde ──────────────────────────────── */}
          <div className="border-t border-border/50">
            <Container className="py-4">
              <div className="flex gap-4 overflow-x-auto pb-1 [-ms-overflow-style:none] scrollbar-none [&::-webkit-scrollbar]:hidden">
                {HOMEPAGE_CATEGORIES.map((cat, i) => (
                  <Link
                    key={cat.id}
                    href={`/kesif?category=${encodeURIComponent(cat.id)}`}
                    className="group flex shrink-0 flex-col items-center gap-1.5"
                  >
                    <div className="flex h-[68px] w-[68px] items-center justify-center overflow-hidden rounded-[22px] bg-white shadow-yd1 transition-all group-hover:-translate-y-0.5 group-hover:shadow-yd2">
                      <Image
                        src={cat.img}
                        alt=""
                        width={68}
                        height={68}
                        priority={i < 4}
                        className="h-full w-full object-cover"
                      />
                    </div>
                    <span className="whitespace-nowrap text-[11px] font-black text-textStrong group-hover:text-primary">
                      {cat.label}
                    </span>
                  </Link>
                ))}
                {/* Tüm kategoriler */}
                <Link
                  href="/kesif"
                  aria-label="Tüm kategorileri keşfet"
                  className="group flex shrink-0 flex-col items-center gap-1.5"
                >
                  <div className="flex h-[68px] w-[68px] items-center justify-center rounded-[22px] shadow-yd1 transition-all group-hover:-translate-y-0.5 group-hover:shadow-yd2" style={{ background: 'var(--yd-gradient-primary)' }}>
                    <svg viewBox="0 0 24 24" className="h-7 w-7 fill-current text-white" aria-hidden="true">
                      <path d="M4 6h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4zM4 12h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4zM4 18h4v4H4zm6 0h4v4h-4zm6 0h4v4h-4z"/>
                    </svg>
                  </div>
                  <span className="whitespace-nowrap text-[11px] font-black text-primary">Tüm Kategoriler</span>
                </Link>
              </div>
            </Container>
          </div>
        </section>

        {/* ── Main body ───────────────────────────────────────────────────── */}
        <Container className="py-8">
          <div className="grid gap-8 lg:grid-cols-[1fr_360px]">

            {/* ── Left column ─────────────────────────────────────────────── */}
            <div className="space-y-8">

              {/* Featured businesses — yatay scroll strip */}
              <section>
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="text-xl font-black text-textStrong">Senin için öne çıkanlar</h2>
                  <Link href="/kesif" aria-label="Öne çıkan işletmelerin tümünü gör" className="flex items-center gap-1 text-sm font-extrabold text-primary hover:underline">
                    Tümünü gör <ChevronRight size={14} aria-hidden="true" />
                  </Link>
                </div>
                {featuredBusinesses.length > 0 ? (
                  <div className="flex gap-4 overflow-x-auto pb-2 [-ms-overflow-style:none] scrollbar-none [&::-webkit-scrollbar]:hidden">
                    {featuredBusinesses.map((biz, i) => (
                      <div key={biz.id} className="w-64 shrink-0">
                        <BusinessCard biz={biz} priority={i === 0} />
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="flex gap-4 overflow-x-auto pb-2">
                    {[1, 2, 3, 4].map((i) => (
                      <div key={i} className="h-52 w-64 shrink-0 rounded-[28px] bg-cardAlt" />
                    ))}
                  </div>
                )}
              </section>

              {/* Campaign banner — mobil _DiscoveryCampaignPromoCard stili */}
              <Link
                href="/kampanyalar"
                className="group flex items-center gap-4 rounded-[20px] p-4 transition-all hover:brightness-[0.96]"
                style={{ background: '#F9E7E7' }}
              >
                <div className="flex-1 min-w-0">
                  <p className="font-black text-textStrong">Lezzetli fırsatları kaçırma! 🎉</p>
                  <p className="mt-1 text-sm text-textStrong">Sana özel indirimleri keşfet.</p>
                </div>
                <div className="relative shrink-0">
                  <Image
                    src="/category-images/tatli.webp"
                    alt=""
                    width={72}
                    height={72}
                    className="h-[72px] w-[72px] rounded-2xl object-cover"
                  />
                  <div className="absolute -bottom-2 -right-2 flex h-9 w-9 items-center justify-center rounded-full bg-primary text-white shadow-md transition-transform group-hover:scale-110">
                    <ArrowRight size={14} aria-hidden="true" />
                  </div>
                </div>
              </Link>

              {/* Testimonials */}
              <section>
                <h2 className="mb-4 text-xl font-black text-textStrong">Kullanıcılarımız ne diyor?</h2>
                <div className="grid gap-4 sm:grid-cols-3">
                  {TESTIMONIALS.map((t) => (
                    <div
                      key={t.name}
                      className="rounded-[20px] border border-border bg-card p-4 shadow-yd1"
                    >
                      <div className="mb-3 flex items-center gap-3">
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-black text-primary">
                          {t.name.slice(0, 1)}
                        </div>
                        <div>
                          <p className="text-sm font-black text-textStrong">{t.name}</p>
                          <p className="text-xs text-muted">{t.time}</p>
                        </div>
                      </div>
                      <div className="mb-2 flex gap-0.5" aria-label="5 üzerinden 5 yıldız">
                        {[1, 2, 3, 4, 5].map((s) => (
                          <Star key={s} size={12} className="fill-amber-400 text-amber-400" aria-hidden="true" />
                        ))}
                      </div>
                      <p className="text-sm leading-6 text-muted">{t.text}</p>
                    </div>
                  ))}
                </div>
                <div className="mt-4 text-right">
                  <Link href="/en-iyiler" className="text-sm font-extrabold text-primary hover:underline">
                    Tüm yorumları gör →
                  </Link>
                </div>
              </section>
            </div>

            {/* ── Right sidebar ───────────────────────────────────────────── */}
            <aside className="space-y-5 lg:sticky lg:top-20 lg:self-start">

              {/* Trust section */}
              <section>
                <h2 className="mb-4 text-lg font-black text-textStrong">Fiyatlar ve bilgiler güvenilir mi?</h2>
                <div className="space-y-3">

                  {/* Veri güveni — kırmızı/primary */}
                  <div className="rounded-[20px] border border-border bg-card p-4 shadow-yd1">
                    <div className="flex items-start gap-3">
                      <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[14px] bg-primary/10">
                        <Shield size={18} className="text-primary" aria-hidden="true" />
                      </div>
                      <div>
                        <p className="font-black text-textStrong">Veri güveni</p>
                        <p className="mt-1 text-xs leading-5 text-muted">
                          Menü ve fiyat bilgileri topluluğumuzun katkılarıyla şeffaf ve güncel kalır.
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Toplulukça Doğrulandı — yeşil/success */}
                  <div className="rounded-[20px] border border-border bg-card p-4 shadow-yd1">
                    <div className="flex items-start gap-3">
                      <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[14px] bg-success/10">
                        <CheckCircle size={18} className="text-success" aria-hidden="true" />
                      </div>
                      <div>
                        <p className="font-black text-textStrong">Toplulukça Doğrulandı</p>
                        <p className="mt-1 text-xs leading-5 text-muted">
                          Binlerce kullanıcı tarafından her gün doğrulanmaktadır.
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Price history */}
                  <div className="rounded-[20px] border border-border bg-card p-4 shadow-yd1">
                    <div className="flex items-start gap-3">
                      <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-[14px] bg-primary/10">
                        <BarChart2 size={18} className="text-primary" aria-hidden="true" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center justify-between">
                          <p className="font-black text-textStrong">Fiyat Geçmişi</p>
                          <span className="text-xs font-extrabold text-success">+0% (3 Ay)</span>
                        </div>
                        <p className="mt-1 text-xs text-muted">Son 3 ay ortalama değişim</p>
                        <svg viewBox="0 0 120 28" className="mt-3 w-full text-primary" aria-hidden="true">
                          <polyline
                            points="0,22 20,18 40,20 60,14 80,16 100,10 120,12"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                      </div>
                    </div>
                  </div>
                </div>
              </section>

              {/* How it works */}
              <section className="rounded-[20px] border border-border bg-card p-5 shadow-yd1">
                <h2 className="mb-4 font-black text-textStrong">Nasıl çalışır?</h2>
                <div className="space-y-4">
                  {[
                    { icon: <Search size={18} aria-hidden="true" />, step: '1', title: 'Keşfet', desc: 'Yakınındaki mekanları ara ve keşfet.' },
                    { icon: <BarChart2 size={18} aria-hidden="true" />, step: '2', title: 'Karşılaştır', desc: 'Menüleri ve fiyatları karşılaştır.' },
                    { icon: <CheckCircle size={18} aria-hidden="true" />, step: '3', title: 'Katkı Yap', desc: 'Doğrula, yorum yap, fiyatları güncel tut.' },
                  ].map(({ icon, step, title, desc }) => (
                    <div key={step} className="flex items-start gap-3">
                      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[14px] bg-primary/10 text-primary">
                        {icon}
                      </div>
                      <div>
                        <p className="font-black text-textStrong">{step} {title}</p>
                        <p className="mt-0.5 text-xs text-muted">{desc}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </section>

            </aside>
          </div>
        </Container>

        {/* ── Yakındaki işletmeler — konum bazlı, client component ──────── */}
        <YakindakiIsletmeler />
      </main>
      <KonumIzniIstemcisi />
    </PublicShell>
  );
}
