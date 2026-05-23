# Yeedoy — Food Discovery Marketplace Web Tasarımı

> **Kaynak:** Food Discovery Marketplace UI (Figma Make) — ekran görüntüsü analizi  
> **Tarih:** 2026-05-04  
> **Hedef:** Figma tasarımındaki her UI detayını Yeedoy'un renklerine ve logosuna uyarlayarak Next.js'e taşımak.

---

## Figma Tasarım Analizi

### Ekran Yapısı (Yukarıdan Aşağı)

```
1. HERO           — Dramatik gradient bg, H1, arama, sosyal kanıt
2. KATEGORİ ROW   — İkon + metin pill'ler (yatay scroll)
3. ANA LİSTE      — Başlık + dropdown + 3 sütun kart grid
4. LOAD MORE      — Outlined centered button
5. FOOTER         — Koyu 4 sütun
```

---

## Renk Uyarlaması — Figma → Yeedoy

| Figma Rengi | Figma Kullanımı | Yeedoy Karşılığı |
|-------------|----------------|-----------------|
| Turuncu→Pembe gradient | Hero bg | `linear-gradient(135deg, #5C1515 0%, #7F1D1D 35%, #DC2626 75%, #B91C1C 100%)` |
| Turuncu | Search button, aktif pill, rating badge, CTA | `var(--yd-gradient-primary)` + `var(--yd-shadow-primary)` |
| Turuncu metin | "View Menu →" | `text-primary` |
| Koyu glass badge (photo üstü) | "Popular", "Fast Delivery" | `bg-black/60 backdrop-blur-sm text-white` |
| Yeşil badge | "Top Rated", "Healthy" | `bg-success/90 text-white` |
| Beyaz hero text | H1, subtitle | `text-white` |
| Card bg | Beyaz kart | `bg-card` |
| Koyu footer | Dark 4-col | `bg-[#0f1117]` |

---

## Bölüm 1 — HERO Section

### Figma Detayları
- Tam genişlik, yüksek hero (~300px)
- Gradient: turuncu sol üst → pembe/kırmızı sağ alt
- H1: "Discover Amazing Food Near You" — büyük, beyaz, bold
- Subtitle: gri/beyaz/80, 2 satır
- Arama: beyaz kart `[🔍 Restoran, mutfak, yemek] | [📍 Konum] | [Search🟠]`
- Sosyal kanıt: "• 50,000+ Restaurants • 1M+ Reviews • Fast Delivery" (küçük, beyaz)

### Yeedoy Adaptasyonu

```tsx
// uygulama/page.tsx — Hero section
<section className="relative overflow-hidden">
  {/* Yeedoy gradient: derin bordo → parlak kırmızı */}
  <div
    className="absolute inset-0"
    style={{
      background: 'linear-gradient(135deg, #3D0C0C 0%, #7F1D1D 30%, #DC2626 65%, #9E1515 100%)',
    }}
  />
  {/* Dekoratif doku */}
  <div
    className="absolute inset-0 opacity-10"
    style={{
      backgroundImage:
        'radial-gradient(circle at 20% 50%, rgba(255,255,255,0.15) 0%, transparent 50%), ' +
        'radial-gradient(circle at 80% 20%, rgba(255,255,255,0.10) 0%, transparent 40%)',
    }}
  />

  <div className="relative mx-auto max-w-5xl px-4 py-20 text-center sm:py-28">
    {/* Logo — beyaz versiyonu */}
    <div className="mb-6 flex justify-center">
      <YeedoyLogo size={44} textColor="#ffffff" />
    </div>

    {/* H1 */}
    <h1 className="font-display text-4xl font-[900] leading-[1.05] text-white sm:text-5xl lg:text-6xl">
      Yakınındaki En İyi
      <br />
      <span className="text-white/90">Yemekleri Keşfet</span>
    </h1>

    {/* Subtitle */}
    <p className="mx-auto mt-5 max-w-xl text-base leading-relaxed text-white/70 sm:text-lg">
      Binlerce restoran, kafe ve yemek mekanı. Yorumları oku, fiyatları karşılaştır, menüleri keşfet.
    </p>

    {/* Arama kutusu */}
    <form
      method="GET"
      action="/kesif"
      className="mx-auto mt-8 flex max-w-2xl overflow-hidden rounded-2xl bg-white shadow-[0_8px_32px_rgba(0,0,0,0.25)]"
    >
      <div className="flex flex-1 items-center gap-2 px-4">
        <SearchIcon className="shrink-0 text-muted" />
        <input
          name="q"
          placeholder="Restoran, mutfak veya yemek ara…"
          className="flex-1 py-4 text-sm text-textStrong placeholder:text-muted focus:outline-none bg-transparent"
        />
      </div>
      <div className="flex items-center gap-2 border-l border-border px-4">
        <LocationIcon className="shrink-0 text-muted" />
        <input
          name="city"
          placeholder="Şehir"
          className="w-28 py-4 text-sm text-textStrong placeholder:text-muted focus:outline-none bg-transparent"
        />
      </div>
      <button
        type="submit"
        className="m-1.5 rounded-xl px-6 text-sm font-[900] text-white transition-all hover:brightness-105 active:scale-[0.97]"
        style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}
      >
        Ara
      </button>
    </form>

    {/* Sosyal kanıt */}
    <div className="mt-6 flex flex-wrap items-center justify-center gap-4 text-sm text-white/60">
      <span className="flex items-center gap-1.5">
        <span className="h-1.5 w-1.5 rounded-full bg-white/60" />
        500+ İşletme
      </span>
      <span className="flex items-center gap-1.5">
        <span className="h-1.5 w-1.5 rounded-full bg-white/60" />
        10K+ Yorum
      </span>
      <span className="flex items-center gap-1.5">
        <span className="h-1.5 w-1.5 rounded-full bg-white/60" />
        Güncel Fiyatlar
      </span>
    </div>
  </div>
</section>
```

---

## Bölüm 2 — Kategori Satırı

### Figma Detayları
- Beyaz arka plan, border-bottom
- İkon + metin pill'ler: "All" (turuncu dolu), "Pizza", "Coffee", "Healthy", "Dessert", "Soup"
- İkonlar: yemek kategorisi SVG/emoji ikonlar
- Aktif: turuncu bg, beyaz metin
- Pasif: gri bg, koyu metin

### Yeedoy Adaptasyonu

```tsx
const CATEGORIES = [
  { id: 'all',     label: 'Tümü',     icon: <GridIcon /> },
  { id: 'Pizza',   label: 'Pizza',    icon: <PizzaIcon /> },
  { id: 'Kafe',    label: 'Kafe',     icon: <CoffeeIcon /> },
  { id: 'Sağlıklı',label: 'Sağlıklı', icon: <LeafIcon /> },
  { id: 'Tatlıcı', label: 'Tatlı',   icon: <CakeIcon /> },
  { id: 'Çorba',   label: 'Çorba',   icon: <BowlIcon /> },
  { id: 'Burger',  label: 'Burger',   icon: <BurgerIcon /> },
  { id: 'Dönerci', label: 'Döner',   icon: <WrapIcon /> },
  { id: 'Restoran',label: 'Restoran', icon: <ForkIcon /> },
  { id: 'Balık',   label: 'Balık',   icon: <FishIcon /> },
];

// Kategori pill bileşeni
<Link
  href={catHref(cat.id)}
  className={`inline-flex shrink-0 flex-col items-center gap-1.5 rounded-2xl px-4 py-3
              text-xs font-[800] transition-all duration-[150ms]
              focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30
              ${isActive
                ? 'text-white shadow-[0_2px_12px_rgba(127,29,29,0.35)]'
                : 'bg-bg text-textStrong hover:bg-cardAlt'}`}
  style={isActive ? { background: 'var(--yd-gradient-primary)' } : undefined}
>
  <span className="h-6 w-6">{cat.icon}</span>
  {cat.label}
</Link>
```

---

## Bölüm 3 — Restaurant Card

### Figma Detayları (en kritik bileşen)
```
┌─────────────────────────────────┐
│  [FOOD PHOTO - 16:9]            │
│  ┌──────────┐     ┌──────────┐  │
│  │ Popular  │     │ ★ 4.8   │  │  ← glass badge + rating badge
│  │Fast Deliv│     │(turuncu) │  │
│  └──────────┘     └──────────┘  │
├─────────────────────────────────┤
│  Bella Italia                   │  ← font-bold, dark
│  Italian • Pizza • Pasta        │  ← text-muted, small
│  $$ · ⏱ 25-35 min · 📍 1.2 km │  ← inline meta row
│  2,340 reviews    View Menu →   │  ← footer row
└─────────────────────────────────┘
```

### Yeedoy Adaptasyonu — `RestaurantCard`

```tsx
// src/ui/components/restaurant-card.tsx
import Link from 'next/link';
import { buildMenuImageUrl } from '@/src/lib/media-url';

interface RestaurantCardProps {
  name: string;
  slug: string;
  category?: string | null;
  city?: string | null;
  logoUrl?: string | null;
  coverUrl?: string | null;
  avgRating?: number | null;
  reviewsCount?: number | null;
  isVerified?: boolean;
  isOpenNow?: boolean | null;
  badge?: string;   // "Popular" | "Top Rated" | "Yeni" vb.
}

export function RestaurantCard({
  name, slug, category, city, logoUrl, coverUrl,
  avgRating, reviewsCount, isVerified, isOpenNow, badge,
}: RestaurantCardProps) {
  const imgSrc = coverUrl ?? logoUrl;
  return (
    <Link href={`/isletme/${slug}`}
      className="group flex flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1
                 transition-all duration-[200ms] hover:-translate-y-1 hover:shadow-yd3 hover:border-primary/20
                 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">

      {/* Photo */}
      <div className="relative aspect-[4/3] overflow-hidden bg-cardAlt">
        {imgSrc ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={buildMenuImageUrl(imgSrc, { width: 480 }) ?? imgSrc}
            alt={name}
            className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.04]"
            loading="lazy"
          />
        ) : (
          <div
            className="flex h-full w-full items-center justify-center text-white/80"
            style={{ background: 'var(--yd-gradient-primary)' }}
          >
            <span className="text-3xl font-[900]">{name[0]}</span>
          </div>
        )}

        {/* Sol üst — type badge */}
        {badge && (
          <div className="absolute left-3 top-3 flex flex-col gap-1.5">
            <span className="rounded-lg bg-black/60 px-2.5 py-1 text-[11px] font-[800] text-white backdrop-blur-sm">
              {badge}
            </span>
          </div>
        )}
        {isVerified && (
          <div className={`absolute ${badge ? 'top-9 mt-1.5' : 'top-3'} left-3`}>
            <span className="rounded-lg bg-success/90 px-2.5 py-1 text-[11px] font-[800] text-white backdrop-blur-sm">
              Onaylı
            </span>
          </div>
        )}

        {/* Sağ üst — rating badge */}
        {avgRating != null && (
          <div className="absolute right-3 top-3">
            <span
              className="flex h-10 w-10 flex-col items-center justify-center rounded-full text-white shadow-[0_2px_8px_rgba(0,0,0,0.3)]"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
              </svg>
              <span className="text-[11px] font-[900] leading-none">{avgRating.toFixed(1)}</span>
            </span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="flex flex-1 flex-col gap-2 p-4">
        {/* Name */}
        <div>
          <h3 className="font-[900] leading-tight text-textStrong group-hover:text-primary transition-colors line-clamp-1">
            {name}
          </h3>
          <p className="mt-0.5 text-xs text-muted line-clamp-1">
            {[category, city].filter(Boolean).join(' · ')}
          </p>
        </div>

        {/* Meta row: open/closed + distance */}
        <div className="flex flex-wrap items-center gap-2 text-xs text-muted">
          {isOpenNow != null && (
            <span className={`flex items-center gap-1 font-[700] ${isOpenNow ? 'text-success' : 'text-danger'}`}>
              <span className={`h-1.5 w-1.5 rounded-full ${isOpenNow ? 'bg-success' : 'bg-danger'}`} />
              {isOpenNow ? 'Açık' : 'Kapalı'}
            </span>
          )}
        </div>

        {/* Footer row */}
        <div className="mt-auto flex items-center justify-between pt-2 border-t border-border">
          <span className="text-[11px] text-muted">
            {reviewsCount != null ? `${reviewsCount.toLocaleString('tr-TR')} yorum` : ''}
          </span>
          <span className="text-xs font-[800] text-primary transition-colors group-hover:text-primaryStrong">
            Menüyü Gör →
          </span>
        </div>
      </div>
    </Link>
  );
}
```

---

## Bölüm 4 — Ana Liste + Grid

### Figma Detayları
- Başlık: "Popular Restaurants" (font-bold) + "9 restaurants available" (muted)
- Sağda: "Recommended ▾" dropdown
- **3 sütunlu grid** (sm:1, md:2, lg:3)
- "Load More Restaurants" outlined button

### Yeedoy Adaptasyonu — Discover / Ana Sayfa

```tsx
{/* Section header */}
<div className="mb-5 flex items-center justify-between">
  <div>
    <h2 className="text-xl font-[900] text-textStrong">
      {category ? `${category} İşletmeleri` : 'Popüler İşletmeler'}
    </h2>
    <p className="text-sm text-muted">{total} işletme mevcut</p>
  </div>
  <SortSelect /> {/* Recommended / Puan / Yeni */}
</div>

{/* 3-column grid */}
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
  {businesses.map(biz => (
    <RestaurantCard key={biz.id} {...biz} />
  ))}
</div>

{/* Load More / Pagination */}
{hasMore && (
  <div className="mt-8 flex justify-center">
    <Link
      href={buildHref({ page: page + 1 })}
      className="rounded-full border-2 border-primary px-8 py-3 text-sm font-[900] text-primary
                 transition-all hover:bg-primary hover:text-white active:scale-[0.97]"
    >
      Daha Fazla Göster
    </Link>
  </div>
)}
```

---

## Bölüm 5 — Footer

### Figma Detayları
- Koyu arka plan (~slate-900)
- Logo + slogan solda
- 3 sütun: "For Foodies", "For Restaurants", "Company"
- Alt çizgi: copyright

### Yeedoy Adaptasyonu

```tsx
// src/ui/layout/site-footer.tsx
export function SiteFooter() {
  return (
    <footer className="border-t border-border bg-[#0f1117] text-white/70">
      <div className="mx-auto grid max-w-5xl gap-8 px-4 py-12 sm:grid-cols-2 lg:grid-cols-4">
        {/* Brand */}
        <div>
          <YeedoyLogo size={32} textColor="#ffffff" />
          <p className="mt-3 text-sm text-white/50">
            Şehrindeki en iyi yemek deneyimlerini keşfet.
          </p>
        </div>
        {/* Gurme */}
        <div>
          <p className="mb-3 text-sm font-[900] text-white">Gurmeler İçin</p>
          <ul className="space-y-2 text-sm text-white/60">
            <li><Link href="/kesif" className="hover:text-white">Keşfet</Link></li>
            <li><Link href="/en-iyiler" className="hover:text-white">En İyiler</Link></li>
            <li><Link href="/akis" className="hover:text-white">Gurme Akışı</Link></li>
          </ul>
        </div>
        {/* İşletmeler */}
        <div>
          <p className="mb-3 text-sm font-[900] text-white">İşletmeler İçin</p>
          <ul className="space-y-2 text-sm text-white/60">
            <li><Link href="/oneri" className="hover:text-white">İşletme Öner</Link></li>
            <li><Link href="/giris" className="hover:text-white">Panel Girişi</Link></li>
            <li><Link href="/owner/baslangic" className="hover:text-white">Kayıt Ol</Link></li>
          </ul>
        </div>
        {/* Şirket */}
        <div>
          <p className="mb-3 text-sm font-[900] text-white">Şirket</p>
          <ul className="space-y-2 text-sm text-white/60">
            <li><Link href="/yasal" className="hover:text-white">Yasal</Link></li>
            <li><Link href="/oneri" className="hover:text-white">İletişim</Link></li>
          </ul>
        </div>
      </div>
      <div className="border-t border-white/10 px-4 py-4 text-center text-xs text-white/30">
        © 2026 Yeedoy. Tüm hakları saklıdır.
      </div>
    </footer>
  );
}
```

---

## Uygulama Sırası (Önceliklendirilmiş)

### Faz 1 — Yüksek Etki (Hemen)

| # | Bileşen | Dosya | Açıklama |
|---|---------|-------|---------|
| 1 | `RestaurantCard` | `src/ui/components/restaurant-card.tsx` | Figma'nın kalbi — dikey kart |
| 2 | Hero section güncelle | `uygulama/page.tsx` | Dramatik gradient, beyaz arama kutusu |
| 3 | Icon kategori chips | `uygulama/(public)/kesif/page.tsx` | İkon + metin pill'ler |
| 4 | 3-col grid | `uygulama/page.tsx` + `discover/page.tsx` | RestaurantCard grid layout |
| 5 | SiteFooter | `src/ui/layout/site-footer.tsx` | Koyu footer |

### Faz 2 — Orta Etki

| # | Bileşen | Dosya |
|---|---------|-------|
| 6 | SortSelect | dropdown — "Önerilen / Puan / Yeni" |
| 7 | Load More pattern | Pagination yerine sayfa sonu butonu |
| 8 | OpenNow badge | BusinessTile + RestaurantCard |
| 9 | Gourmet profile hero | `/gurmeler/[username]` yenileme |
| 10 | Category hub | `/(public)/c/[category]/page.tsx` |

---

## Checklist

- [ ] `RestaurantCard` bileşeni tamamlandı
- [ ] Ana sayfa hero dramatik gradient + beyaz arama kutusu
- [ ] `discover/page.tsx` → 3 sütun grid + icon chips
- [ ] `SiteFooter` oluşturuldu
- [ ] `npm run typecheck` temiz
- [ ] Mobile 375px: 1 sütun, tablet 768px: 2 sütun, desktop 1280px: 3 sütun



