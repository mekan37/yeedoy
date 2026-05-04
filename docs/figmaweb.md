# Yeedoy — Food Discovery Marketplace Web Tasarımı

> **Kaynak:** Food Discovery Marketplace UI (Figma Make)  
> **Tarih:** 2026-05-04  
> **Hedef:** Figma tasarımındaki zengin UI kalıplarını Yeedoy'un kendi renk, logo ve token sistemiyle Next.js'e taşımak.  
> **Strateji:** Figma layout'unu al, Yeedoy brandını uygula, mevcut bileşenleri yeniden kullan.

---

## Renk & Token Eşlemesi

| Figma Rolü | Yeedoy Token | Değer |
|------------|-------------|-------|
| Primary / Accent | `--yd-color-primary` | `#7F1D1D` bordo |
| Primary hover | `--yd-color-primary-strong` | `#DC2626` kırmızı |
| Primary CTA gradient | `--yd-gradient-primary` | `135deg #7F1D1D → #DC2626` |
| Background | `--yd-color-bg` | `#F9FAFB` |
| Card surface | `--yd-color-card` | `#FFFFFF` |
| Card warm alt | `--yd-color-card-alt` | `#FDF8F7` |
| Border | `--yd-color-border` | `#E5E7EB` |
| Body text | `--yd-color-text` | `#434D57` |
| Strong text | `--yd-color-text-strong` | `#111827` |
| Muted text | `--yd-color-muted` | `#5E6574` |
| Success (verified) | `--yd-color-success` | `#15803D` |
| Star rating | `--yd-color-star` | `#FBBF24` |
| Shadow card | `--yd-shadow-2` | `0 4px 12px rgba(15,23,42,0.08)` |
| Shadow card hover | `--yd-shadow-3` | `0 12px 32px rgba(15,23,42,0.12)` |

**Logo:** `<YeedoyLogo size={N} />` — SVG, markayı doğru gösterir, beyaz/koyu versiyonu destekler.

---

## Ekran 1 — Ana Sayfa / Hero Discovery

### Tasarım Hedefi
Büyük, dikkat çekici hero + arama çubuğu + kategori hızlı filtreleri + öne çıkan işletmeler.

### Layout Yapısı

```
┌─────────────────────────────────────────┐
│  NAVBAR: Logo + Nav Links + ThemeToggle │
├─────────────────────────────────────────┤
│                                         │
│  HERO SECTION (radial gradient bg)      │
│  ┌─────────────────────────────────┐    │
│  │  Kicker: "Türkiye'nin menüleri" │    │
│  │  H1: Büyük başlık (font-display)│    │
│  │  Subtitle: muted text           │    │
│  │  ┌────────────────────────────┐ │    │
│  │  │  🔍 Arama kutusu + Şehir   │ │    │
│  │  │  [Ara]  gradient button    │ │    │
│  │  └────────────────────────────┘ │    │
│  │  Kategori chips (yatay scroll)  │    │
│  └─────────────────────────────────┘    │
│                                         │
├─────────────────────────────────────────┤
│  FEATURED STRIP: "Haftanın En İyileri"  │
│  [kart] [kart] [kart] [kart] →scroll   │
├─────────────────────────────────────────┤
│  ┌──────────────────┐  ┌─────────────┐ │
│  │  Ana Liste        │  │  Sidebar    │ │
│  │  (BusinessTile)   │  │  Top 5      │ │
│  │                   │  │  Panel CTA  │ │
│  └──────────────────┘  └─────────────┘ │
└─────────────────────────────────────────┘
```

### Bileşenler

**Navbar:**
```tsx
// Sticky, backdrop-blur, border-b
<header className="sticky top-0 z-20 border-b border-border bg-card/95 backdrop-blur-md">
  <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
    <YeedoyLogo size={34} />
    <nav className="flex gap-1">
      <NavLink href="/discover">Keşfet</NavLink>
      <NavLink href="/top">En İyiler</NavLink>
      <NavLink href="/budget">Bütçe</NavLink>
      <ThemeToggle />
      <Link href="/login" className="btn-cta">Giriş Yap</Link>
    </nav>
  </div>
</header>
```

**Hero Section:**
```tsx
<section className="relative overflow-hidden border-b border-border">
  {/* Yeedoy radial gradient bg */}
  <div className="absolute inset-0 -z-10" style={{
    background: 'radial-gradient(ellipse at 15% 0%, rgba(127,29,29,0.10), transparent 50%), var(--yd-color-card-alt)'
  }} />
  
  <div className="mx-auto max-w-6xl px-4 py-16 sm:py-24">
    {/* Kicker */}
    <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-[var(--yd-color-primary-soft)] px-3 py-1">
      <span className="h-1.5 w-1.5 rounded-full bg-primary" />
      <span className="yd-eyebrow text-primary">Türkiye'nin menü platformu</span>
    </div>
    
    {/* H1 */}
    <h1 className="font-display yd-heading-xl max-w-3xl">
      Şehrinin En İyi <span style={{ background: 'var(--yd-gradient-primary)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
        Restoranları
      </span> Burada
    </h1>
    
    {/* Search bar */}
    <form className="mt-8 flex gap-2 max-w-2xl">
      <SearchInput name="q" placeholder="Restoran, menü öğesi ara..." />
      <CityInput name="city" />
      <GradientButton type="submit">Ara</GradientButton>
    </form>
    
    {/* Category chips */}
    <CategoryChips className="mt-5" />
  </div>
</section>
```

**Featured Strip (Haftanın En İyileri):**
```tsx
// Yatay kaydırmalı kart serisi — get_top_businesses_period_v1
<section className="border-b border-border bg-cardAlt py-8">
  <div className="mx-auto max-w-6xl px-4">
    <div className="mb-4 flex items-center justify-between">
      <AppSectionHeader title="Bu Haftanın Favorileri" />
      <Link href="/top" className="text-sm font-[700] text-primary">Tümü →</Link>
    </div>
    <div className="flex gap-4 overflow-x-auto pb-2 [-ms-overflow-style:none] [scrollbar-width:none]">
      {topBiz.map((biz, i) => (
        <FeaturedCard key={biz.id} biz={biz} rank={i+1} />
      ))}
    </div>
  </div>
</section>
```

---

## Ekran 2 — Keşif / Arama Sonuçları

### Layout

```
┌─────────────────────────────────────────┐
│  Sticky filter bar                      │
│  [Tümü] [Kafe] [Restoran] [Döner] ...   │
│  Sırala: [Puan] [Mesafe] [Yeni]         │
├──────────────────┬──────────────────────┤
│  SONUÇLAR        │  HARİTA (opsiyonel)  │
│  BusinessTile x N│  Leaflet/Mapbox      │
│                  │                      │
│  [Önceki] [Sonraki]                     │
└──────────────────┴──────────────────────┘
```

### Bileşenler

**Sticky Filter Bar:**
```tsx
<section className="sticky top-16 z-20 border-b border-border bg-card/95 backdrop-blur-md py-3">
  <div className="mx-auto max-w-6xl px-4">
    <div className="flex items-center gap-3">
      {/* Category pills */}
      <div className="flex gap-2 overflow-x-auto flex-1">
        <CategoryChip label="Tümü" selected={!category} />
        {CATEGORIES.map(cat => (
          <CategoryChip key={cat.id} label={cat.label} selected={category === cat.id} />
        ))}
      </div>
      {/* Sort */}
      <SortSelect options={['Puan', 'Yorum', 'Yeni']} />
    </div>
  </div>
</section>

{/* Sonuç sayısı */}
<div className="mx-auto max-w-6xl px-4 py-3">
  <p className="text-sm text-muted">{total} işletme bulundu</p>
</div>
```

**BusinessTile (mevcut, genişletilecek):**
```tsx
// Mevcut BusinessTile'a şunlar eklenecek:
// - averageRating + reviewCount
// - distanceKm (konum izni varsa)
// - openNow badge (yeşil/kırmızı)
// - Favori butonu (kalp ikonu)

<BusinessTile
  slug={biz.slug}
  name={biz.name}
  category={biz.category}
  subtitle={`${biz.city} · ${biz.avg_rating?.toFixed(1)} ★ (${biz.review_count})`}
  isVerified={biz.is_verified}
  badgeText={biz.is_open_now ? 'Açık' : undefined}
  socialProof={biz.trending ? ['Trend'] : undefined}
/>
```

---

## Ekran 3 — İşletme Detay (Mevcut, Genişletme)

`/b/[slug]` sayfası büyük ölçüde yapıldı. Figma'nın eklediği yeni elementler:

### Yeni Eklentiler

```
┌─────────────────────────────────────────┐
│  HERO (cover_url + gradient overlay)    │
│  ┌─────────────────────────────────┐    │
│  │  [Logo] Ad + Verified + Open    │    │
│  │  ★ 4.8  (234 yorum) · 2.1km    │    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│  ACTION ROW                             │
│  [Menüyü Gör▶] [♥ Favori] [↗ Paylaş]  │
├────────────────────┬────────────────────┤
│  ANA İÇERİK        │  SIDEBAR           │
│                    │                    │
│  Fotoğraflar (3x3) │  Saatler           │
│  Menü preview      │  İletişim          │
│  Yorumlar          │  QR Kodu           │
│  [Tümünü gör →]    │  Benzer İşletmeler │
└────────────────────┴────────────────────┘
```

**Benzer İşletmeler sidebar widget'ı (YENİ):**
```tsx
// Aynı şehir + kategori filtreli, 3 BusinessTile
async function SimilarBusinesses({ businessId, category, city }: Props) {
  const supabase = await createSupabaseServerClient();
  const { data } = await (supabase as any)
    .from('businesses')
    .select('id, name, slug, category, city, is_verified')
    .eq('category', category)
    .eq('city', city)
    .eq('is_active', true)
    .neq('id', businessId)
    .limit(3);
  
  return (
    <div className="rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1">
      <p className="mb-3 text-sm font-[900] text-textStrong">Benzer İşletmeler</p>
      <div className="flex flex-col gap-2">
        {data?.map(b => <MiniBusinessCard key={b.id} biz={b} />)}
      </div>
    </div>
  );
}
```

**Fotoğraf galeri modal (YENİ):**
```tsx
// Galeri grid'e tıklayınca full lightbox
// Mevcut menu-item-detail-sheet.tsx pattern'i kullan
'use client';
export function PhotoGalleryModal({ photos, initialIndex }: Props) {
  // animate-sheet-in + backdrop + PageController-benzeri prev/next
}
```

---

## Ekran 4 — Menü Görüntüleyici (Mevcut, Görsel Yenileme)

`/m/[slug]` zaten var. Figma'daki ek elementler:

### Kategori Tab Navigation (Linear.app stili)

```
[Tümü] [Başlangıçlar] [Ana Yemekler] [Tatlılar] [İçecekler]
       ↑ aktif — gradient pill (zaten implemente)
```

**Item card — görsel odaklı layout:**
```
┌──────────────────────────────────────────┐
│ [Görsel 160px]  │  Ad (font-black)        │
│                 │  Açıklama (muted, 2 line)│
│                 │  ────────────────────── │
│                 │  ₺48,00  [+ Detay]      │
│                 │  #tag1  #tag2  vegan     │
└──────────────────────────────────────────┘
```
Sol accent bar hover efekti zaten uygulandı (`group-hover:opacity-100`).

### Hero Banner Güncellemesi
```tsx
// cover_url + gradient overlay + badge strip
<div className="relative h-64 sm:h-80 overflow-hidden">
  <Image src={cover} fill className="object-cover" />
  {/* Gradient overlay */}
  <div className="absolute inset-0" style={{
    background: 'linear-gradient(to bottom, rgba(0,0,0,0.05) 0%, rgba(0,0,0,0.65) 100%)'
  }} />
  {/* Business info overlay */}
  <div className="absolute bottom-0 left-0 right-0 p-6 text-white">
    <div className="flex items-end gap-4">
      <img src={logo} className="h-16 w-16 rounded-2xl border-2 border-white/30" />
      <div>
        <h1 className="text-2xl font-[900]">{name}</h1>
        <div className="flex gap-2 mt-1">
          {isVerified && <VerifiedBadge />}
          {isOpenNow && <OpenBadge />}
          <StarBadge rating={avg} count={count} />
        </div>
      </div>
    </div>
  </div>
</div>
```

---

## Ekran 5 — Gurme Profil (`/gourmet/[username]`)

### Layout (Figma stili)

```
┌─────────────────────────────────────────┐
│  PROFILE HEADER                         │
│  ┌───────────────────────────────────┐  │
│  │  [Avatar 80px]  │  Ad + Rozet     │  │
│  │                 │  Şehir, Üyelik  │  │
│  │  254 Yorum  │  128 Takipçi  │ 89 Fav│
│  └───────────────────────────────────┘  │
├─────────────────────────────────────────┤
│  TABS: Son Yorumlar | Favoriler | Hakkında
├─────────────────────────────────────────┤
│  İçerik (tab'a göre)                    │
└─────────────────────────────────────────┘
```

**Profil header component:**
```tsx
// Zaten /gourmet/[username]/page.tsx var, genişletme yapılacak

async function GourmetHeader({ username }: { username: string }) {
  // user_profiles + follower/following counts
  return (
    <div className="rounded-[20px] border border-border bg-cardAlt p-6 shadow-yd2">
      <div className="flex items-start gap-5">
        <Avatar url={profile.avatar_url} name={profile.display_name} size={80} />
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-[900] text-textStrong">{profile.display_name}</h1>
            {profile.reputation_score > 50 && <ReputationBadge score={profile.reputation_score} />}
          </div>
          <p className="text-sm text-muted">{profile.city}</p>
          {/* Stats bar */}
          <div className="mt-3 flex gap-5">
            <StatItem value={reviewCount} label="Yorum" />
            <StatItem value={followersCount} label="Takipçi" />
            <StatItem value={favoritesCount} label="Favori" />
          </div>
        </div>
        <FollowButton targetUserId={profile.user_id} />
      </div>
    </div>
  );
}
```

---

## Ekran 6 — Kategori Hub (YENİ SAYFA)

`/(public)/c/[category]/page.tsx` — Belirli bir kategoriye adanmış tam sayfa.

### Layout

```
┌─────────────────────────────────────────┐
│  CATEGORY HERO                          │
│  [Gradient bg matching category]        │
│  "Kafeler" — 234 işletme               │
│  "İstanbul'un en iyi kahve mekanları"  │
├─────────────────────────────────────────┤
│  SUB-FILTER CHIPS                       │
│  [Tümü] [Sabah Kahvaltısı] [Çalışma]   │
├─────────────────────────────────────────┤
│  REGIONAL SECTIONS                      │
│  "Kadıköy'dekiler"  BusinessTile x 3   │
│  "Beyoğlu'ndakiler" BusinessTile x 3   │
├─────────────────────────────────────────┤
│  TÜM LİSTE (paginated)                 │
└─────────────────────────────────────────┘
```

```tsx
// app/(public)/c/[category]/page.tsx
export default async function CategoryPage({ params }: { params: Promise<{ category: string }> }) {
  const { category } = await params;
  // decode: 'kafe' → 'Kafe', 'restoran' → 'Restoran'
  const decoded = decodeURIComponent(category);
  
  const supabase = await createSupabaseServerClient();
  
  // Parallel: total count + featured businesses + city breakdown
  const [totalRes, businessesRes] = await Promise.all([
    (supabase as any).from('businesses').select('id', { count: 'exact', head: true })
      .eq('category', decoded).eq('is_active', true),
    (supabase as any).from('businesses')
      .select('id, name, slug, city, is_verified, logo_url')
      .eq('category', decoded).eq('is_active', true)
      .order('created_at', { ascending: false }).limit(20),
  ]);
  
  return (
    <main className="min-h-screen bg-bg">
      {/* Category hero with gradient */}
      <CategoryHero category={decoded} count={totalRes.count ?? 0} />
      {/* Business grid */}
      <div className="mx-auto max-w-3xl px-4 py-8">
        <BusinessList businesses={businessesRes.data ?? []} />
      </div>
    </main>
  );
}
```

---

## Ekran 7 — Arama Sonuçları Sayfası (Genişletme)

`/discover` sayfasının Figma'da görülen ek elementleri:

### Price Range Filtresi (YENİ)
```tsx
// URL param: ?maxPrice=5000 (cents)
<PriceRangeChips
  options={[
    { label: '₺0–25', value: '2500' },
    { label: '₺25–50', value: '5000' },
    { label: '₺50–100', value: '10000' },
    { label: '₺100+', value: '99999' },
  ]}
  active={maxPrice}
/>
```

### Regional Insight Sections (P1)
```tsx
// get_district_price_changes_v1 RPC
<section className="border-t border-border py-8">
  <AppSectionHeader title="Fiyat Değişimleri" subtitle="Son 7 günde en çok değişen menüler" />
  <PriceChangeStrip businesses={priceChanges} />
</section>
```

---

## Bileşen Kütüphanesi — Yeni Eklentiler

### Yeni Bileşenler (Figma'dan esinlenen)

| Bileşen | Dosya | Öncelik |
|---------|-------|---------|
| `FeaturedCard` | `src/ui/components/featured-card.tsx` | P0 |
| `CategoryHero` | `src/ui/sections/category-hero.tsx` | P1 |
| `SimilarBusinesses` | `src/ui/sections/similar-businesses.tsx` | P1 |
| `GourmetHeader` | `src/ui/sections/gourmet-header.tsx` | P1 |
| `PhotoGalleryModal` | `src/ui/components/photo-gallery-modal.tsx` | P1 |
| `StatItem` | `src/ui/components/stat-item.tsx` | P2 |
| `FollowButton` | `src/ui/components/follow-button.tsx` | P2 |
| `PriceRangeChips` | `src/ui/components/price-range-chips.tsx` | P2 |
| `Avatar` | `src/ui/components/avatar.tsx` | P2 |
| `OpenNowBadge` | `src/ui/components/open-now-badge.tsx` | P2 |

---

## FeaturedCard — En Yüksek Öncelikli Bileşen

Figma'daki öne çıkan işletme kartı — yatay scroll strip için.

```tsx
// src/ui/components/featured-card.tsx
import Link from 'next/link';

interface FeaturedCardProps {
  id: string;
  name: string;
  slug: string;
  category: string | null;
  city: string | null;
  avgRating?: number | null;
  reviewsCount?: number;
  rank?: number;
  logoUrl?: string | null;
}

export function FeaturedCard({ name, slug, category, city, avgRating, reviewsCount, rank, logoUrl }: FeaturedCardProps) {
  return (
    <Link href={`/b/${slug}`}
      className="group flex w-52 shrink-0 flex-col gap-3 rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1
                 transition-all duration-[180ms] hover:-translate-y-1 hover:border-primary/20 hover:shadow-yd3
                 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
      
      {/* Rank badge + logo */}
      <div className="flex items-start justify-between">
        {rank && (
          <span className="rounded-full text-[11px] font-[900] text-primary">
            #{rank}
          </span>
        )}
        <div className="h-12 w-12 overflow-hidden rounded-xl border border-border bg-bg ml-auto">
          {logoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={logoUrl} alt={name} className="h-full w-full object-cover" loading="lazy" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-base font-[900] text-primary/60">
              {name[0]}
            </div>
          )}
        </div>
      </div>

      {/* Info */}
      <div className="flex-1">
        <p className="line-clamp-2 font-[900] leading-tight text-textStrong group-hover:text-primary transition-colors">
          {name}
        </p>
        <p className="mt-0.5 text-xs text-muted">{[category, city].filter(Boolean).join(' · ')}</p>
      </div>

      {/* Rating */}
      {avgRating != null && (
        <div className="flex items-center justify-between">
          <span className="flex items-center gap-1 text-xs font-[800] text-amber-500">
            <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true">
              <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
            {avgRating.toFixed(1)}
          </span>
          {reviewsCount != null && (
            <span className="text-[10px] text-muted">{reviewsCount} yorum</span>
          )}
        </div>
      )}
    </Link>
  );
}
```

---

## Ana Sayfa Tam Yeniden Tasarımı

`app/page.tsx`'in Figma bazlı son hali:

```tsx
// Mevcut 2-kolon layout korunur, şunlar eklenir:
// 1. FeaturedCard horizontal strip (has filters, before the main list)
// 2. Social proof stats (işletme sayısı, yorum sayısı)  
// 3. H1'de gradient text span
// 4. CategoryChips (zaten var)
// 5. ThemeToggle (zaten eklendi)

// Veri: 
const [
  { data: businesses, count, totalPages },
  topBusinesses,
  businessCount,
  reviewCount,
] = await Promise.all([
  discoverBusinesses({ q, city, category, page, pageSize: 12 }),
  getTopBusinesses(6),
  getTotalBusinessCount(),   // YENİ
  getTotalReviewCount(),      // YENİ
]);
```

---

## Uygulama Sırası

### Faz 1 — Yüksek Etki (Bu Sprint)

```
[1] FeaturedCard bileşeni → src/ui/components/featured-card.tsx
[2] Ana sayfa FeaturedCard strip → app/page.tsx (top businesses)
[3] /b/[slug] → SimilarBusinesses sidebar widget
[4] /b/[slug] → Fotoğraf galeri lightbox
[5] H1 gradient text span (ana sayfa hero)
```

### Faz 2 — Orta Etki

```
[6] /(public)/c/[category]/page.tsx → Kategori hub sayfası
[7] /gourmet/[username] → GourmetHeader genişletme
[8] /discover → PriceRange filtresi
[9] OpenNowBadge → BusinessTile'a entegre
[10] Avatar bileşeni → gourmet profil + review kartları
```

### Faz 3 — Tamamlayıcı

```
[11] FollowButton → gourmet profil
[12] /discover → Regional insight sections
[13] Fotoğraf galeri overlay tüm sayfalara
[14] Business menu hero → cover overlay iyileştirmesi
```

---

## Tasarım Prensipleri (Figma Ruhunu Korumak)

### 1. Kartlar — Derinlik Hiyerarşisi

| Kart Tipi | Border Radius | Shadow | Hover |
|-----------|-------------|--------|-------|
| Featured | `rounded-[20px]` | `shadow-yd1` | `-translate-y-1 shadow-yd3` |
| Normal tile | `rounded-[20px]` | `shadow-yd1` | `-translate-y-0.5 shadow-yd2` |
| Info sidebar | `rounded-[20px]` | `shadow-yd1` | static |
| Modal/Sheet | `rounded-[32px]` | `shadow-yd4` | — |

### 2. Renk Kullanımı — Figma Uyumu

- **Hero başlıklar:** Font-display (Playfair) + gradient text overlay
- **Aksiyon öğeleri:** `var(--yd-gradient-primary)` + `var(--yd-shadow-primary)`
- **Kategoriler:** `bg-primary-soft border-primary/25 text-primary` (aktif)
- **Verified badges:** `bg-success/12 border-success/25 text-success`
- **Rating:** `text-amber-500` (star ikonu)
- **Muted info:** `text-muted` (#5E6574)

### 3. Tipografi Ölçeği

| Kullanım | Sınıf |
|----------|-------|
| Hero H1 | `.yd-heading-xl font-display` |
| Section H2 | `.yd-heading-lg` veya `text-2xl font-[900]` |
| Card başlık | `font-[900] text-textStrong` |
| Kicker | `.yd-eyebrow` |
| Body | `text-sm text-textStrong` |
| Muted | `text-xs text-muted` |

### 4. Boşluk Standardı

```
Page horizontal padding: px-4 sm:px-6 (max-w-6xl container)
Section spacing: py-12 sm:py-16
Card internal: p-4 sm:p-5
Card gap: gap-3 sm:gap-4
Chip gap: gap-2
```

---

## Başarı Kriterleri

- [ ] `FeaturedCard` bileşeni yazıldı
- [ ] Ana sayfa featured strip çalışıyor (top businesses ile)
- [ ] `/b/[slug]` sayfasına "Benzer İşletmeler" widget'ı eklendi
- [ ] `/c/[category]` kategori hub sayfası oluşturuldu
- [ ] Hero H1'de gradient text span uygulandı
- [ ] `npm run typecheck` temiz
- [ ] Mobile responsive: 375px, 768px, 1280px kırılım noktalarında görsel kontrol

---

*Bu belge Figma "Food Discovery Marketplace UI" tasarımının Yeedoy brandına adaptasyonudur. Tüm renkler, gölgeler ve spacing değerleri `tokens.css` kaynaklıdır. Panel Flutter web silinmiştir; tüm implementasyon `apps/web_next`'tedir.*
