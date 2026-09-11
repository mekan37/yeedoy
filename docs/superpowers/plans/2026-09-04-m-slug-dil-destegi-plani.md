# /m/[slug] Dil Desteği Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/m/[slug]` public menü sayfasında (ve `c/[categoryId]`, `i/[itemId]` alt rotalarında) zaten var olan ürün/kategori çevirilerini gerçekten göstermek, arayüz metinlerini `ceviri.ts`'e bağlamak, ve görünür bir TR/EN dil seçici eklemek.

**Architecture:** `renderPublicMenuRoute` (üç rotanın da paylaştığı ortak fonksiyon, `app/(genel)/m/[slug]/page.tsx`) zaten hesapladığı `normalized.lang`'i ve `copy[normalized.lang]`'i (`ceviri.ts`) yeni prop'lar olarak `MenuDuzen`'e (`src/ui/bolumler/menu-sayfasi/menu-duzen.tsx`) geçirir. `MenuDuzen` içindeki tüm sabit Türkçe metinler `labels.X` ile değiştirilir, ürün/kategori adları `getTranslationValue()` ile gerçek dile göre çözülür (yoksa Türkçe'ye düşer), ve işletme başlığının yanına iki küçük TR/EN linki eklenir.

**Tech Stack:** Next.js 15 (App Router, server components), TypeScript.

**Spec:** `docs/superpowers/specs/2026-09-04-m-slug-dil-destegi-design.md`

---

### Task 1: `ceviri.ts`'e eksik anahtarları ve alerjen sözlüğünü ekle

**Files:**
- Modify: `uygulamalar/web/src/lib/ceviri.ts`

- [ ] **Step 1: `copy.tr` objesine yeni anahtarları ekle**

`uygulamalar/web/src/lib/ceviri.ts` içinde `copy.tr` objesinin son satırı şu an:

```typescript
    openNow: 'Su an acik',
    closedNow: 'Simdi kapali',
  },
```

Bunu şununla değiştir:

```typescript
    openNow: 'Su an acik',
    closedNow: 'Simdi kapali',
    breadcrumbDiscover: 'Kesfet',
    breadcrumbRestaurants: 'Restoranlar',
    breadcrumbMenu: 'Menu',
    favoriteButton: 'Favori',
    favoriteButtonAria: 'Favorilere ekle',
    shareButton: 'Paylas',
    shareButtonAria: 'Paylas',
    reserveTableButton: 'Masa Ayirt',
    menuCategoriesTitle: 'Menu Kategorileri',
    featuredCategoryLabel: 'One Cikanlar',
    promoBannerTitle: 'Lezzetli firsatlar seni bekliyor!',
    promoBannerBody: 'En iyi kampanyalari kacirma.',
    showMoreButton: 'Daha fazla goster',
    noSearchResultsPrefix: '',
    noSearchResultsSuffix: 'icin sonuc bulunamadi',
    noSearchResultsHint: 'Farkli bir arama terimi deneyin',
    verifiedBusinessLabel: 'Dogrulanmis Isletme',
    priceOnRequest: 'Fiyata sorunuz',
    allergenPrefix: 'Alerjen',
    featuredItemsSubtitle: 'En cok tercih edilen lezzetler',
  },
```

- [ ] **Step 2: `copy.en` objesine aynı anahtarların İngilizce karşılığını ekle**

`copy.en` objesinin son satırı şu an:

```typescript
    openNow: 'Open now',
    closedNow: 'Closed now',
  },
} as const;
```

Bunu şununla değiştir:

```typescript
    openNow: 'Open now',
    closedNow: 'Closed now',
    breadcrumbDiscover: 'Discover',
    breadcrumbRestaurants: 'Restaurants',
    breadcrumbMenu: 'Menu',
    favoriteButton: 'Favorite',
    favoriteButtonAria: 'Add to favorites',
    shareButton: 'Share',
    shareButtonAria: 'Share',
    reserveTableButton: 'Reserve a Table',
    menuCategoriesTitle: 'Menu Categories',
    featuredCategoryLabel: 'Featured',
    promoBannerTitle: 'Tasty deals are waiting for you!',
    promoBannerBody: "Don't miss the best offers.",
    showMoreButton: 'Show more',
    noSearchResultsPrefix: 'No results for',
    noSearchResultsSuffix: '',
    noSearchResultsHint: 'Try a different search term',
    verifiedBusinessLabel: 'Verified Business',
    priceOnRequest: 'Price on request',
    allergenPrefix: 'Allergen',
    featuredItemsSubtitle: 'Most popular picks',
  },
} as const;
```

Not: `noSearchResultsPrefix`/`Suffix` TR ve EN'de farklı sırada kullanılacak çünkü Türkçe'de sorgu önce gelir ("X için sonuç bulunamadı"), İngilizce'de sonra gelir ("No results for X") — Task 3'te bu iki parçayı sorgu metninin etrafına saracak şekilde birleştireceğiz.

- [ ] **Step 3: Alerjen sözlüğünü ekle**

Aynı dosyanın sonuna (`homeCopy` objesinden sonra, dosyanın en altına) ekle:

```typescript
export const allergenLabels = {
  tr: {
    gluten: 'Gluten',
    milk: 'Süt',
    eggs: 'Yumurta',
    fish: 'Balık',
    shellfish: 'Kabuklu',
    peanuts: 'Yer Fıstığı',
    treenuts: 'Kuruyemiş',
    soy: 'Soya',
    celery: 'Kereviz',
    mustard: 'Hardal',
    sesame: 'Susam',
    sulphites: 'Sülfitler',
    lupin: 'Acı Bakla',
    molluscs: 'Yumuşakça',
  },
  en: {
    gluten: 'Gluten',
    milk: 'Milk',
    eggs: 'Eggs',
    fish: 'Fish',
    shellfish: 'Shellfish',
    peanuts: 'Peanuts',
    treenuts: 'Tree Nuts',
    soy: 'Soy',
    celery: 'Celery',
    mustard: 'Mustard',
    sesame: 'Sesame',
    sulphites: 'Sulphites',
    lupin: 'Lupin',
    molluscs: 'Molluscs',
  },
} as const;
```

- [ ] **Step 4: Verify TypeScript compiles**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/ceviri.ts
git commit -m "feat(web): ceviri.ts'e /m/[slug] arayüzü için eksik anahtarlar ve alerjen sözlüğü eklendi"
```

---

### Task 2: `renderPublicMenuRoute`'u `lang`/`labels`/seçici linkleriyle `MenuDuzen`'e bağla

**Files:**
- Modify: `uygulamalar/web/app/(genel)/m/[slug]/page.tsx`

- [ ] **Step 1: `copy` importunu ekle**

Dosyanın başındaki import bloğuna (satır 7 civarı, `getPublicMenuPageData` importunun yanına) ekle:

```typescript
import { copy } from '@/src/lib/ceviri';
```

- [ ] **Step 2: `renderPublicMenuRoute` içinde `labels` ve seçici linklerini hesapla**

`renderPublicMenuRoute` fonksiyonunda `businessName` hesaplandıktan hemen sonra (satır ~213, `getTranslationValue(...) ?? data.business.name;` satırından sonra), şunu ekle:

```typescript
  const labels = copy[normalized.lang];
  const langSwitchHrefTr = buildBusinessMenuHref({
    business: data.business,
    categoryId: input.selectedCategoryId,
    itemId: input.selectedItemId,
    lang: 'tr',
    theme: normalized.theme,
    src: normalized.src,
    preview: normalized.preview,
  });
  const langSwitchHrefEn = buildBusinessMenuHref({
    business: data.business,
    categoryId: input.selectedCategoryId,
    itemId: input.selectedItemId,
    lang: 'en',
    theme: normalized.theme,
    src: normalized.src,
    preview: normalized.preview,
  });
```

- [ ] **Step 3: `<MenuDuzen>` çağrısına yeni prop'ları geç**

Şu an (satır ~305-310):

```tsx
      <MenuDuzen
        data={data}
        isOpenNow={isOpenNow}
        todayHours={todayHours}
        businessName={businessName}
      />
```

Bunu şununla değiştir:

```tsx
      <MenuDuzen
        data={data}
        isOpenNow={isOpenNow}
        todayHours={todayHours}
        businessName={businessName}
        lang={normalized.lang}
        labels={labels}
        langSwitchHrefTr={langSwitchHrefTr}
        langSwitchHrefEn={langSwitchHrefEn}
      />
```

- [ ] **Step 4: Verify TypeScript compiles**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: hata verecek çünkü `MenuDuzenProps` henüz yeni prop'ları kabul etmiyor — bu beklenen, Task 3'te düzelecek. Şimdilik sadece bu dosyada (`page.tsx`) başka bir hata olmadığını doğrula (hata sadece `menu-duzen.tsx`'in prop tipiyle ilgili olmalı).

- [ ] **Step 5: Commit**

```bash
git add "uygulamalar/web/app/(genel)/m/[slug]/page.tsx"
git commit -m "feat(web): renderPublicMenuRoute artık lang/labels/dil seçici linklerini hesaplıyor"
```

(Bu commit `menu-duzen.tsx` güncellenene kadar typecheck'i kırık bırakır — bu projede kabul edilebilir çünkü Task 3 hemen ardından geliyor ve aynı PR/oturumda tamamlanacak. Eğer CI bu ara commit'i ayrı test ediyorsa endişelenme, plan tek oturumda uçtan uca uygulanacak.)

---

### Task 3: `MenuDuzen`'i yeni prop'ları kullanacak şekilde güncelle

**Files:**
- Modify: `uygulamalar/web/src/ui/bolumler/menu-sayfasi/menu-duzen.tsx`

- [ ] **Step 1: Importları ve sabitleri güncelle**

Dosyanın başındaki (satır 1-56) import ve sabit tanımlarını şununla değiştir:

```typescript
'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  Flame, Hamburger, UtensilsCrossed, Cookie, HandPlatter, CupSoda, Cake,
  Droplet, Pizza, Sandwich, Drumstick, Fish, Salad, Wheat, Soup,
  Beef, Utensils,
  type LucideIcon,
} from 'lucide-react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { bulVarsayilanYemekGorseli, type StockDishImage } from '@/src/lib/menu/varsayilan-yemek-gorseli';
import { getStokYemekKutuphanesi } from '@/src/lib/menu/stok-yemek-kutuphanesi';
import { getTranslationValue } from '@/src/lib/acik-menu-sayfasi';
import type { PublicMenuPageData } from '@/src/lib/acik-menu-sayfasi';
import type { MenuItemRecord } from '@/src/lib/veri/menu-okuma';
import { allergenLabels, type AppLang, type MenuCopy } from '@/src/lib/ceviri';

// ── Sabitler ─────────────────────────────────────────────────────────────────

const FEATURED_ID = '__featured__';
const INITIAL_SHOW = 5;
```

(`ALLERGEN_LABEL` ve `ALLERGEN_EMOJI` objelerinden `ALLERGEN_LABEL` kaldırıldı — artık `allergenLabels[lang]` kullanılacak. `ALLERGEN_EMOJI` aynı kalıyor, emoji dilden bağımsız.)

Hemen altındaki `ALLERGEN_LABEL` tanımını (eski satır 24-39) tamamen sil, sadece `ALLERGEN_EMOJI` (eski satır 41-56) kalsın.

- [ ] **Step 2: `kategoriIkonu` fonksiyonunu olduğu gibi bırak**

Bu fonksiyon değişmiyor (İngilizce kategori adları genel ikona düşer, spec'te bilinçli kapsam dışı).

- [ ] **Step 3: `fiyat` fonksiyonuna `priceOnRequest` parametresi ekle**

Şu an:

```typescript
function fiyat(cents: number | null): string {
  if (cents == null) return 'Fiyata sorunuz';
  return `₺${(cents / 100).toFixed(0)}`;
}
```

Bunu şununla değiştir:

```typescript
function fiyat(cents: number | null, priceOnRequest: string): string {
  if (cents == null) return priceOnRequest;
  return `₺${(cents / 100).toFixed(0)}`;
}
```

`kalori` fonksiyonu değişmiyor (kcal birimi dilden bağımsız).

- [ ] **Step 4: `MenuDuzenProps` tipini genişlet**

Şu an:

```typescript
export type MenuDuzenProps = {
  data: PublicMenuPageData;
  isOpenNow: boolean | null;
  todayHours: string | null;
  businessName: string;
};
```

Bunu şununla değiştir:

```typescript
export type MenuDuzenProps = {
  data: PublicMenuPageData;
  isOpenNow: boolean | null;
  todayHours: string | null;
  businessName: string;
  lang: AppLang;
  labels: MenuCopy;
  langSwitchHrefTr: string;
  langSwitchHrefEn: string;
};
```

- [ ] **Step 5: Bileşen imzasını ve kategori adı çözümlemesini güncelle**

Şu an (satır ~104-129):

```typescript
export function MenuDuzen({ data, isOpenNow, todayHours, businessName }: MenuDuzenProps) {
  const { business, categories, items, media } = data;

  const [activeCatId, setActiveCatId] = useState<string>(FEATURED_ID);
  const [query, setQuery] = useState('');
  const [showMoreMap, setShowMoreMap] = useState<Record<string, boolean>>({});
  const [collapsedMap, setCollapsedMap] = useState<Record<string, boolean>>({});
  const [stokKutuphanesi, setStokKutuphanesi] = useState<StockDishImage[]>([]);

  useEffect(() => {
    getStokYemekKutuphanesi().then(setStokKutuphanesi);
  }, []);

  const catNameMap = new Map<string, string>(
    categories.map((cat, index) => [
      cat.id,
      getTranslationValue({
        translations: data.translations,
        entityType: 'category',
        entityId: cat.id,
        locale: 'tr',
        field: 'name',
        fallback: `Kategori ${index + 1}`,
      }) ?? `Kategori ${index + 1}`,
    ]),
  );
```

Bunu şununla değiştir:

```typescript
export function MenuDuzen({
  data, isOpenNow, todayHours, businessName, lang, labels, langSwitchHrefTr, langSwitchHrefEn,
}: MenuDuzenProps) {
  const { business, categories, items, media } = data;

  const [activeCatId, setActiveCatId] = useState<string>(FEATURED_ID);
  const [query, setQuery] = useState('');
  const [showMoreMap, setShowMoreMap] = useState<Record<string, boolean>>({});
  const [collapsedMap, setCollapsedMap] = useState<Record<string, boolean>>({});
  const [stokKutuphanesi, setStokKutuphanesi] = useState<StockDishImage[]>([]);

  useEffect(() => {
    getStokYemekKutuphanesi().then(setStokKutuphanesi);
  }, []);

  const catNameMap = new Map<string, string>(
    categories.map((cat, index) => [
      cat.id,
      getTranslationValue({
        translations: data.translations,
        entityType: 'category',
        entityId: cat.id,
        locale: lang,
        field: 'name',
        fallback: `Kategori ${index + 1}`,
      }) ?? `Kategori ${index + 1}`,
    ]),
  );
```

- [ ] **Step 6: `sidebarCats`'teki "Öne Çıkanlar" sabitini `labels`'a bağla**

Şu an (satır ~163-169):

```typescript
  const sidebarCats = [
    { id: FEATURED_ID, name: 'Öne Çıkanlar', icon: Flame },
    ...categories.map((c) => {
      const name = catNameMap.get(c.id) ?? 'Kategori';
      return { id: c.id, name, icon: kategoriIkonu(name) };
    }),
  ];
```

Bunu şununla değiştir:

```typescript
  const sidebarCats = [
    { id: FEATURED_ID, name: labels.featuredCategoryLabel, icon: Flame },
    ...categories.map((c) => {
      const name = catNameMap.get(c.id) ?? 'Kategori';
      return { id: c.id, name, icon: kategoriIkonu(name) };
    }),
  ];
```

- [ ] **Step 7: Breadcrumb'ı `labels`'a bağla**

Şu an (satır ~182-192):

```tsx
          <nav className="mb-4 flex items-center gap-1 text-xs font-bold text-muted" aria-label="Breadcrumb">
            <Link href="/" className="hover:text-primary transition-colors">Keşfet</Link>
            <ChevronRight />
            <Link href="/kesif" className="hover:text-primary transition-colors">Restoranlar</Link>
            <ChevronRight />
            <Link href={`/isletme/${business.public_slug ?? business.slug ?? business.id}`} className="hover:text-primary transition-colors">
              {businessName}
            </Link>
            <ChevronRight />
            <span className="text-textStrong" aria-current="page">Menü</span>
          </nav>
```

Bunu şununla değiştir:

```tsx
          <nav className="mb-4 flex items-center gap-1 text-xs font-bold text-muted" aria-label="Breadcrumb">
            <Link href="/" className="hover:text-primary transition-colors">{labels.breadcrumbDiscover}</Link>
            <ChevronRight />
            <Link href="/kesif" className="hover:text-primary transition-colors">{labels.breadcrumbRestaurants}</Link>
            <ChevronRight />
            <Link href={`/isletme/${business.public_slug ?? business.slug ?? business.id}`} className="hover:text-primary transition-colors">
              {businessName}
            </Link>
            <ChevronRight />
            <span className="text-textStrong" aria-current="page">{labels.breadcrumbMenu}</span>
          </nav>
```

- [ ] **Step 8: İşletme başlığının yanına dil seçiciyi ekle**

Şu an (satır ~213-227), `<h1>` ve doğrulama rozetini içeren blok:

```tsx
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-xl font-black leading-tight text-textStrong sm:text-2xl">{businessName}</h1>
                {business.is_verified && (
                  <span
                    className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary text-white"
                    title="Doğrulanmış İşletme"
                    aria-label="Doğrulanmış işletme"
                  >
                    <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
                      <path d="M2 6l2.5 2.5L10 3.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </span>
                )}
              </div>
```

Bunu şununla değiştir:

```tsx
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-xl font-black leading-tight text-textStrong sm:text-2xl">{businessName}</h1>
                {business.is_verified && (
                  <span
                    className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary text-white"
                    title={labels.verifiedBusinessLabel}
                    aria-label={labels.verifiedBusinessLabel}
                  >
                    <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
                      <path d="M2 6l2.5 2.5L10 3.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </span>
                )}
                <div className="flex items-center gap-1 text-xs font-black">
                  <a
                    href={langSwitchHrefTr}
                    className={lang === 'tr' ? 'text-primary underline' : 'text-muted hover:text-primary'}
                  >
                    TR
                  </a>
                  <span className="text-muted" aria-hidden="true">|</span>
                  <a
                    href={langSwitchHrefEn}
                    className={lang === 'en' ? 'text-primary underline' : 'text-muted hover:text-primary'}
                  >
                    EN
                  </a>
                </div>
              </div>
```

- [ ] **Step 9: Aksiyon butonlarını `labels`'a bağla**

Şu an (satır ~276-323), Favori/Paylaş/Masa Ayırt butonları:

```tsx
              <div className="mt-3 flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  className="inline-flex min-h-9 items-center gap-1.5 rounded-full border border-border bg-card px-4 text-xs font-black text-textStrong hover:border-danger hover:text-danger transition-colors"
                  aria-label="Favorilere ekle"
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                  </svg>
                  Favori
                </button>

                <button
                  type="button"
                  className="inline-flex min-h-9 items-center gap-1.5 rounded-full border border-border bg-card px-4 text-xs font-black text-textStrong hover:border-primary hover:text-primary transition-colors"
                  onClick={() => { if (navigator.share) navigator.share({ title: businessName, url: window.location.href }); }}
                  aria-label="Paylaş"
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                    <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                  </svg>
                  Paylaş
                </button>

                {business.reservation_url && (
                  <Link
                    href={business.reservation_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex min-h-9 items-center gap-1.5 rounded-2xl bg-primary px-4 text-xs font-black text-white hover:bg-primary/90 transition-colors"
                  >
                    🪑 Masa Ayırt
                  </Link>
                )}
```

Bunu şununla değiştir:

```tsx
              <div className="mt-3 flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  className="inline-flex min-h-9 items-center gap-1.5 rounded-full border border-border bg-card px-4 text-xs font-black text-textStrong hover:border-danger hover:text-danger transition-colors"
                  aria-label={labels.favoriteButtonAria}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                  </svg>
                  {labels.favoriteButton}
                </button>

                <button
                  type="button"
                  className="inline-flex min-h-9 items-center gap-1.5 rounded-full border border-border bg-card px-4 text-xs font-black text-textStrong hover:border-primary hover:text-primary transition-colors"
                  onClick={() => { if (navigator.share) navigator.share({ title: businessName, url: window.location.href }); }}
                  aria-label={labels.shareButtonAria}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                    <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" /><line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                  </svg>
                  {labels.shareButton}
                </button>

                {business.reservation_url && (
                  <Link
                    href={business.reservation_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex min-h-9 items-center gap-1.5 rounded-2xl bg-primary px-4 text-xs font-black text-white hover:bg-primary/90 transition-colors"
                  >
                    🪑 {labels.reserveTableButton}
                  </Link>
                )}
```

- [ ] **Step 10: Sidebar başlığını ve promo banner'ı `labels`'a bağla**

Şu an (satır ~335-361):

```tsx
            <p className="px-4 pb-2 pt-1 text-[11px] font-black uppercase tracking-widest text-muted">
              Menü Kategorileri
            </p>
```

...değiştir:

```tsx
            <p className="px-4 pb-2 pt-1 text-[11px] font-black uppercase tracking-widest text-muted">
              {labels.menuCategoriesTitle}
            </p>
```

Ve aynı bölümdeki promo banner (satır ~358-361):

```tsx
            <div className="mx-3 mt-4 rounded-2xl bg-primary/5 p-3">
              <p className="text-xs font-black text-primary">Lezzetli fırsatlar seni bekliyor! 🎉</p>
              <p className="mt-0.5 text-[11px] font-bold text-muted">En iyi kampanyaları kaçırma.</p>
            </div>
```

...değiştir:

```tsx
            <div className="mx-3 mt-4 rounded-2xl bg-primary/5 p-3">
              <p className="text-xs font-black text-primary">{labels.promoBannerTitle} 🎉</p>
              <p className="mt-0.5 text-[11px] font-bold text-muted">{labels.promoBannerBody}</p>
            </div>
```

- [ ] **Step 11: Arama kutusunu `labels`'a bağla**

Şu an (satır ~375-381):

```tsx
            <input
              type="search"
              placeholder="Menüde ara..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="h-11 w-full rounded-2xl border border-border bg-card pl-11 pr-4 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden transition-colors"
            />
```

...değiştir:

```tsx
            <input
              type="search"
              placeholder={labels.searchPlaceholder}
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="h-11 w-full rounded-2xl border border-border bg-card pl-11 pr-4 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden transition-colors"
            />
```

- [ ] **Step 12: "Öne Çıkanlar" bölüm başlığını `labels`'a bağla**

Şu an (satır ~388-393):

```tsx
                  <h2 className="text-lg font-black text-textStrong">
                    <span aria-hidden="true">🔥 </span>Öne Çıkanlar
                  </h2>
                  <p className="mt-0.5 text-xs font-bold text-muted">En çok tercih edilen lezzetler</p>
```

...değiştir:

```tsx
                  <h2 className="text-lg font-black text-textStrong">
                    <span aria-hidden="true">🔥 </span>{labels.featuredItems}
                  </h2>
                  <p className="mt-0.5 text-xs font-bold text-muted">{labels.featuredItemsSubtitle}</p>
```

(`featuredItems` zaten `ceviri.ts`'te var, aynen kullanılıyor. `featuredItemsSubtitle` Task 1'de eklenen yeni bir anahtar — mevcut `curatedSelection` anahtarının değeri "Seçili imza tabaklar" anlamca farklı olduğu için o kullanılmadı, orijinal metnin ("En çok tercih edilen lezzetler") birebir korunması için ayrı bir anahtar açıldı.)

- [ ] **Step 13: `featuredItems`/`UrunKarti` çağrısına `labels` geçir, `UrunKarti`'ı çeviri-farkında yap**

Şu an (satır ~395-399):

```tsx
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                {featuredItems.filter(matches).map((item) => (
                  <UrunKarti key={item.id} item={item} />
                ))}
              </div>
```

...değiştir:

```tsx
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                {featuredItems.filter(matches).map((item) => (
                  <UrunKarti key={item.id} item={item} translations={data.translations} lang={lang} labels={labels} />
                ))}
              </div>
```

- [ ] **Step 14: Kategori bölümündeki `UrunSatiri` çağrısına `labels`/`lang`/`translations` geçir**

Şu an (satır ~404-458), kategori render bloğunda `catName`:

```typescript
            const catName = catNameMap.get(cat.id) ?? 'Kategori';
```

Bu satır aynı kalıyor (zaten `catNameMap` Step 5'te düzeltildi, doğru dili kullanıyor).

Şu an (satır ~436-440):

```tsx
                    <div className="divide-y divide-border overflow-hidden rounded-2xl border border-border bg-card">
                      {visibleItems.map((item) => (
                        <UrunSatiri key={item.id} item={item} stokKutuphanesi={stokKutuphanesi} />
                      ))}
                    </div>
```

...değiştir:

```tsx
                    <div className="divide-y divide-border overflow-hidden rounded-2xl border border-border bg-card">
                      {visibleItems.map((item) => (
                        <UrunSatiri
                          key={item.id}
                          item={item}
                          stokKutuphanesi={stokKutuphanesi}
                          translations={data.translations}
                          lang={lang}
                          labels={labels}
                        />
                      ))}
                    </div>
```

Ve "Daha fazla göster" butonu (satır ~442-453):

```tsx
                    {!showMore && catItems.length > INITIAL_SHOW && (
                      <button
                        type="button"
                        onClick={() => setShowMoreMap((p) => ({ ...p, [cat.id]: true }))}
                        className="mt-3 flex w-full items-center justify-center gap-1.5 rounded-2xl border border-border bg-card py-2.5 text-sm font-black text-textStrong hover:bg-surface transition-colors"
                      >
                        Daha fazla göster
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                          <path d="m6 9 6 6 6-6" />
                        </svg>
                      </button>
                    )}
```

...değiştir:

```tsx
                    {!showMore && catItems.length > INITIAL_SHOW && (
                      <button
                        type="button"
                        onClick={() => setShowMoreMap((p) => ({ ...p, [cat.id]: true }))}
                        className="mt-3 flex w-full items-center justify-center gap-1.5 rounded-2xl border border-border bg-card py-2.5 text-sm font-black text-textStrong hover:bg-surface transition-colors"
                      >
                        {labels.showMoreButton}
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                          <path d="m6 9 6 6 6-6" />
                        </svg>
                      </button>
                    )}
```

- [ ] **Step 15: "Arama sonucu yok" bloğunu `labels`'a bağla**

Şu an (satır ~460-471):

```tsx
          {query.trim() &&
            featuredItems.filter(matches).length === 0 &&
            categories.every((c) => (itemsByCat.get(c.id) ?? []).filter(matches).length === 0) && (
              <div className="rounded-2xl border border-border bg-card px-6 py-12 text-center">
                <p className="text-3xl" aria-hidden="true">🔍</p>
                <p className="mt-3 text-sm font-black text-textStrong">
                  &ldquo;{query}&rdquo; için sonuç bulunamadı
                </p>
                <p className="mt-1 text-xs font-bold text-muted">Farklı bir arama terimi deneyin</p>
              </div>
            )}
```

...değiştir:

```tsx
          {query.trim() &&
            featuredItems.filter(matches).length === 0 &&
            categories.every((c) => (itemsByCat.get(c.id) ?? []).filter(matches).length === 0) && (
              <div className="rounded-2xl border border-border bg-card px-6 py-12 text-center">
                <p className="text-3xl" aria-hidden="true">🔍</p>
                <p className="mt-3 text-sm font-black text-textStrong">
                  {labels.noSearchResultsPrefix} &ldquo;{query}&rdquo; {labels.noSearchResultsSuffix}
                </p>
                <p className="mt-1 text-xs font-bold text-muted">{labels.noSearchResultsHint}</p>
              </div>
            )}
```

- [ ] **Step 16: `UrunKarti` bileşenini çeviri-farkında yap**

Şu an (satır ~480-535):

```typescript
function UrunKarti({ item }: { item: MenuItemRecord }) {
  const imgUrl = buildMenuImageUrl(item.image_url ?? null, { width: 300, quality: 80 });
  const isAvailable = item.is_available !== false;
  const kcal = kalori(item);

  return (
    <div
      className={`group flex flex-col overflow-hidden rounded-2xl border border-border bg-card transition-shadow hover:shadow-ydMd ${
        !isAvailable ? 'opacity-60' : ''
      }`}
    >
      {/* Görsel */}
      <div className="relative aspect-square w-full overflow-hidden">
        {imgUrl ? (
          <Image
            src={imgUrl}
            alt={item.name}
            fill
            sizes="(max-width:640px) 50vw, 25vw"
            className="object-cover transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center bg-surface text-3xl" aria-hidden="true">
            🍽️
          </div>
        )}
        {!isAvailable && (
          <div className="absolute inset-0 flex items-center justify-center bg-card/60">
            <span className="rounded-xl bg-card px-2 py-1 text-[11px] font-black text-muted">Tükendi</span>
          </div>
        )}
      </div>

      {/* Bilgi */}
      <div className="flex flex-1 flex-col p-3">
        <p className="text-sm font-black text-textStrong line-clamp-1">{item.name}</p>
        {item.description && (
          <p className="mt-0.5 text-[11px] font-bold text-muted line-clamp-2">{item.description}</p>
        )}

        {/* Kalori etiketi */}
        {kcal && (
          <p className="mt-1 text-[10px] font-bold text-muted">{kcal}</p>
        )}

        <div className="mt-auto pt-2">
          {isAvailable ? (
            <span className="text-sm font-black text-textStrong">{fiyat(item.price_cents)}</span>
          ) : (
            <span className="text-xs font-extrabold text-muted">—</span>
          )}
        </div>
      </div>
    </div>
  );
}
```

Bunu şununla değiştir:

```typescript
function UrunKarti({
  item, translations, lang, labels,
}: {
  item: MenuItemRecord;
  translations: PublicMenuPageData['translations'];
  lang: AppLang;
  labels: MenuCopy;
}) {
  const imgUrl = buildMenuImageUrl(item.image_url ?? null, { width: 300, quality: 80 });
  const isAvailable = item.is_available !== false;
  const kcal = kalori(item);
  const name = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'name', fallback: item.name,
  }) ?? item.name;
  const description = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'description', fallback: item.description,
  }) ?? item.description;

  return (
    <div
      className={`group flex flex-col overflow-hidden rounded-2xl border border-border bg-card transition-shadow hover:shadow-ydMd ${
        !isAvailable ? 'opacity-60' : ''
      }`}
    >
      {/* Görsel */}
      <div className="relative aspect-square w-full overflow-hidden">
        {imgUrl ? (
          <Image
            src={imgUrl}
            alt={name}
            fill
            sizes="(max-width:640px) 50vw, 25vw"
            className="object-cover transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center bg-surface text-3xl" aria-hidden="true">
            🍽️
          </div>
        )}
        {!isAvailable && (
          <div className="absolute inset-0 flex items-center justify-center bg-card/60">
            <span className="rounded-xl bg-card px-2 py-1 text-[11px] font-black text-muted">{labels.soldOut}</span>
          </div>
        )}
      </div>

      {/* Bilgi */}
      <div className="flex flex-1 flex-col p-3">
        <p className="text-sm font-black text-textStrong line-clamp-1">{name}</p>
        {description && (
          <p className="mt-0.5 text-[11px] font-bold text-muted line-clamp-2">{description}</p>
        )}

        {/* Kalori etiketi */}
        {kcal && (
          <p className="mt-1 text-[10px] font-bold text-muted">{kcal}</p>
        )}

        <div className="mt-auto pt-2">
          {isAvailable ? (
            <span className="text-sm font-black text-textStrong">{fiyat(item.price_cents, labels.priceOnRequest)}</span>
          ) : (
            <span className="text-xs font-extrabold text-muted">—</span>
          )}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 17: `UrunSatiri` bileşenini çeviri-farkında yap**

Şu an (satır ~539-609):

```typescript
function UrunSatiri({ item, stokKutuphanesi }: { item: MenuItemRecord; stokKutuphanesi: StockDishImage[] }) {
  const varsayilanUrl = item.image_url ? null : bulVarsayilanYemekGorseli(item.name, stokKutuphanesi);
  const imgUrl = buildMenuImageUrl(item.image_url ?? varsayilanUrl, { width: 200, quality: 80 });
  const isAvailable = item.is_available !== false;
  const kcal = kalori(item);
  const allergens = item.allergens ?? [];

  return (
    <div className={`flex items-start gap-3 p-4 ${!isAvailable ? 'opacity-60' : ''}`}>
      {/* Görsel */}
      {imgUrl ? (
        <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-xl">
          <Image src={imgUrl} alt={item.name} fill sizes="80px" className="object-cover" />
        </div>
      ) : (
        <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-xl bg-surface text-2xl" aria-hidden="true">
          🍽️
        </div>
      )}

      {/* Metin */}
      <div className="flex flex-1 min-w-0 flex-col gap-0.5">
        <p className="text-sm font-black text-textStrong line-clamp-1">{item.name}</p>
        {item.description && (
          <p className="text-xs font-bold text-muted line-clamp-2">{item.description}</p>
        )}

        {/* Kalori + etiketler */}
        <div className="mt-1 flex flex-wrap items-center gap-1">
          {kcal && (
            <span className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-extrabold text-muted">
              🔥 {kcal}
            </span>
          )}
          {item.tagList?.slice(0, 2).map((tag) => (
            <span key={tag} className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-extrabold text-muted capitalize">
              {tag}
            </span>
          ))}
        </div>

        {/* Alerjenler */}
        {allergens.length > 0 && (
          <div className="mt-1 flex flex-wrap items-center gap-1">
            {allergens.map((a) => (
              <span
                key={a}
                className="inline-flex items-center gap-0.5 rounded-full bg-amber-50 px-1.5 py-0.5 text-[10px] font-extrabold text-amber-700 ring-1 ring-amber-200"
                title={`Alerjen: ${ALLERGEN_LABEL[a] ?? a}`}
              >
                <span aria-hidden="true">{ALLERGEN_EMOJI[a] ?? '⚠️'}</span>
                {ALLERGEN_LABEL[a] ?? a}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Sağ: fiyat */}
      <div className="ml-2 shrink-0 text-right">
        {isAvailable ? (
          <span className="text-sm font-black text-textStrong">{fiyat(item.price_cents)}</span>
        ) : (
          <span className="rounded-xl border border-border px-2 py-1 text-[11px] font-extrabold text-muted">
            Tükendi
          </span>
        )}
      </div>
    </div>
  );
}
```

Bunu şununla değiştir:

```typescript
function UrunSatiri({
  item, stokKutuphanesi, translations, lang, labels,
}: {
  item: MenuItemRecord;
  stokKutuphanesi: StockDishImage[];
  translations: PublicMenuPageData['translations'];
  lang: AppLang;
  labels: MenuCopy;
}) {
  const varsayilanUrl = item.image_url ? null : bulVarsayilanYemekGorseli(item.name, stokKutuphanesi);
  const imgUrl = buildMenuImageUrl(item.image_url ?? varsayilanUrl, { width: 200, quality: 80 });
  const isAvailable = item.is_available !== false;
  const kcal = kalori(item);
  const allergens = item.allergens ?? [];
  const allergenLabelsForLang = allergenLabels[lang];
  const name = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'name', fallback: item.name,
  }) ?? item.name;
  const description = getTranslationValue({
    translations, entityType: 'item', entityId: item.id, locale: lang, field: 'description', fallback: item.description,
  }) ?? item.description;

  return (
    <div className={`flex items-start gap-3 p-4 ${!isAvailable ? 'opacity-60' : ''}`}>
      {/* Görsel */}
      {imgUrl ? (
        <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-xl">
          <Image src={imgUrl} alt={name} fill sizes="80px" className="object-cover" />
        </div>
      ) : (
        <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-xl bg-surface text-2xl" aria-hidden="true">
          🍽️
        </div>
      )}

      {/* Metin */}
      <div className="flex flex-1 min-w-0 flex-col gap-0.5">
        <p className="text-sm font-black text-textStrong line-clamp-1">{name}</p>
        {description && (
          <p className="text-xs font-bold text-muted line-clamp-2">{description}</p>
        )}

        {/* Kalori + etiketler */}
        <div className="mt-1 flex flex-wrap items-center gap-1">
          {kcal && (
            <span className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-extrabold text-muted">
              🔥 {kcal}
            </span>
          )}
          {item.tagList?.slice(0, 2).map((tag) => (
            <span key={tag} className="rounded-full bg-surface px-2 py-0.5 text-[10px] font-extrabold text-muted capitalize">
              {tag}
            </span>
          ))}
        </div>

        {/* Alerjenler */}
        {allergens.length > 0 && (
          <div className="mt-1 flex flex-wrap items-center gap-1">
            {allergens.map((a) => (
              <span
                key={a}
                className="inline-flex items-center gap-0.5 rounded-full bg-amber-50 px-1.5 py-0.5 text-[10px] font-extrabold text-amber-700 ring-1 ring-amber-200"
                title={`${labels.allergenPrefix}: ${allergenLabelsForLang[a as keyof typeof allergenLabelsForLang] ?? a}`}
              >
                <span aria-hidden="true">{ALLERGEN_EMOJI[a] ?? '⚠️'}</span>
                {allergenLabelsForLang[a as keyof typeof allergenLabelsForLang] ?? a}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Sağ: fiyat */}
      <div className="ml-2 shrink-0 text-right">
        {isAvailable ? (
          <span className="text-sm font-black text-textStrong">{fiyat(item.price_cents, labels.priceOnRequest)}</span>
        ) : (
          <span className="rounded-xl border border-border px-2 py-1 text-[11px] font-extrabold text-muted">
            {labels.soldOut}
          </span>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 18: Verify TypeScript compiles**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: no errors. Bu, Task 2'de bırakılan hatayı da kapatmalı.

- [ ] **Step 19: Verify lint passes**

Run: `cd uygulamalar/web && pnpm run lint`
Expected: `menu-duzen.tsx` veya `page.tsx`'te yeni hata/uyarı yok.

- [ ] **Step 20: Commit**

```bash
git add uygulamalar/web/src/ui/bolumler/menu-sayfasi/menu-duzen.tsx
git commit -m "feat(web): menu-duzen.tsx artık ürün/kategori çevirilerini gösteriyor, arayüz metinleri lokalize, TR/EN seçici eklendi"
```

---

### Task 4: Uçtan uca doğrulama

**Files:** yok (sadece doğrulama)

- [ ] **Step 1: Menü çevirisi olan gerçek bir işletme bul**

`mcp__supabase__execute_sql` ile:

```sql
SELECT DISTINCT b.public_slug, b.slug, b.id, mt.entity_type, mt.locale
FROM public.menu_translations mt
JOIN public.businesses b ON b.id = mt.entity_id AND mt.entity_type = 'business'
WHERE mt.locale = 'en'
LIMIT 5;
```

Eğer `entity_type = 'business'` için sonuç boşsa, `item`/`category` için de dene:

```sql
SELECT b.public_slug, b.slug, b.id, i.id AS item_id, mt.locale, mt.name
FROM public.menu_translations mt
JOIN public.menu_items i ON i.id = mt.entity_id AND mt.entity_type = 'item'
JOIN public.businesses b ON b.id = i.business_id
WHERE mt.locale = 'en'
LIMIT 5;
```

Bulunan bir `public_slug`/`slug` değerini not al (yoksa: bu doğrulama adımı, İngilizce çevirisi olan gerçek veri bulunamazsa Adım 3'ün "çeviri yok" senaryosuyla değiştirilir).

- [ ] **Step 2: Dev server'ı başlat**

Run: `cd uygulamalar/web && pnpm dev` (background, zaten çalışıyorsa atla)

- [ ] **Step 3: Tarayıcıda `?lang=en` ile test et**

claude-in-chrome araçlarıyla: `http://localhost:3000/m/{slug}?lang=en` adresine git. Doğrula:
- İşletme adının yanında "TR | EN" seçicisi görünüyor, "EN" vurgulu.
- Breadcrumb, arama kutusu placeholder'ı, "Menu Categories" başlığı, buton etiketleri (Favorite/Share/Reserve a Table) İngilizce.
- Adım 1'de çevirisi bulunan ürün/kategori varsa, o ürünün adı İngilizce görünüyor; çevirisi olmayan diğer ürünler Türkçe kalıyor (karma durum, beklenen).
- "EN" linkine değil "TR" linkine tıklanınca `?lang=tr`'ye dönülüyor ve arayüz tekrar Türkçe oluyor.

- [ ] **Step 4: `flutter analyze` benzeri bir adım yok (bu web/TypeScript), son kez typecheck+lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: temiz.

- [ ] **Step 5: Final commit (sadece Adım 1-4'te kod değişikliği gerektiyse)**

Doğrulama sırasında bir bug bulunup düzeltildiyse, o düzeltmeyi kendi açıklayıcı mesajıyla commit et. Değişiklik gerekmediyse bu adımda commit yapılmaz.
