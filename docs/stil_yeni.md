# Yeedoy — Tasarım Sistemi Durum ve Yol Haritası

> **Son Güncelleme:** 2026-05-04  
> **Önceki Audit:** 2026-04-25 (`panel_flutter_web` dahildi — artık silinmiş)  
> **Kapsam:** `apps/mobile_flutter` · `apps/web_next`  
> **Strateji:** Temel design system dokunulmaz. **Animasyon**, **derinlik**, **renk katmanı** ve **mikro-etkileşim** eklenir.  
> **İlham:** Linear.app, Vercel Dashboard, Stripe, Framer, Luma

---

## Mevcut Durum — Mayıs 2026

| Alan | Puan | Değişim | Durum |
|------|------|---------|-------|
| Token sistemi | ✅ 10/10 | ↑ | Easing, shadow, gradient tam set — web+mobile synchronized |
| Renk paleti | ✅ 9/10 | ↑ | Katmanlı: soft/strong/deep/primary-08/04 hiyerarşisi uygulandı |
| Web animasyonlar | ✅ 8/10 | ↑↑ | spring/elasticPop/smoothOut CSS vars, card-interactive, btn-primary globals.css'de |
| Mobile animasyonlar | ✅ 8/10 | ↑↑ | PressableCard, GradientButton, AppShimmer shimmer — tüm feed itemlarına RepaintBoundary |
| Web bileşen sistemi | ✅ 8/10 | ↑↑ | AppCard, AppButton, AppChip, AppSectionHeader, BusinessTile, CategoryChip — tümü yeni |
| Gölge ve derinlik | ✅ 9/10 | ↑↑ | S0–S4 + shadowPrimary/PrimaryLg — web ve mobilde unified |
| Micro-interactions | ✅ 7/10 | ↑↑ | hover lift, press scale 0.97, focus-visible ring — tüm interaktif elemanlarda |
| Form feedback | ✅ 8/10 | ↑ | Gradient CTA, success states SVG icon, danger token, karakter sayacı |
| Gradient kullanımı | ✅ 9/10 | ↑↑ | Hero page, CTA butonlar, overlay başlıklar, sparkline renkler |
| Boşluk kullanımı | ✅ 8/10 | ↑ | min-h-[44px] tüm hedefler, pagePadding/sectionPadding standart |
| Dark mode (mobile) | ✅ 7/10 | = | AppDarkColors + themeModeProvider var — eksik: fiyat geçmişi sparkline dark |
| Dark mode (web) | ❌ 2/10 | = | Henüz yok — tokens.css dark variant yok |
| Tipografi | ✅ 8/10 | ↑ | font-display başlıklar, letter-spacing -0.4/-0.8, sectionTitleStyle standart |

### Artık Geçerli Değil
- ~~Panel Flutter Web~~ — `apps/panel_flutter_web/` **silindi** (2026-05-04, Faz 5). Tüm panel Next.js'e geçti.

---

## Tasarım Felsefesi

### 3 Temel İlke (Korunuyor)

**1. Depth over Flat**  
Kart → hover → aktif: z-ekseni hissedilir. Gölge + border rengi + scale birlikte.

**2. Every Interaction Has a Response**  
Press → `scale-[0.97]`. Hover → `-translate-y-0.5` + `shadow-yd2/3`. Success → pop animation.

**3. Brand Moments**  
Bordo `#7F1D1D` sadece accent değil kimlik rengi. Hero, boş state, badge — markayı gösterir.

---

## Bölüm 1 — Token Sistemi (Tamamlandı ✅)

> **Dosyalar:**
> - `apps/web_next/src/styles/tokens.css` ← **Tam**
> - `packages/shared_ui_components/lib/src/app_tokens.dart` ← **Tam**

### Uygulanan Tokenlar

```css
/* tokens.css — tümü mevcut */
--yd-ease-spring: cubic-bezier(0.22, 1, 0.36, 1);
--yd-ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1);
--yd-ease-in-expo: cubic-bezier(0.95, 0.05, 0.795, 0.035);
--yd-ease-smooth: cubic-bezier(0.4, 0, 0.2, 1);

--yd-shadow-1 → --yd-shadow-4  (S1–S4 hierarchy)
--yd-shadow-primary             (bordo glow)
--yd-shadow-primary-lg          (hover state)
--yd-shadow-inset               (input focus)

--yd-gradient-primary           (135deg bordo→kırmızı)
--yd-gradient-primary-soft      (rgba overlay)
--yd-gradient-hero              (radial topleft + bottomright)
--yd-gradient-card-hover        (çok hafif overlay)
--yd-gradient-surface           (beyaz→cardAlt fade)
```

```dart
// app_tokens.dart — tümü mevcut
static const Curve spring = Cubic(0.22, 1.0, 0.36, 1.0);
static const Curve elasticPop = Cubic(0.34, 1.56, 0.64, 1.0);
static const Curve smoothOut = Cubic(0.4, 0.0, 0.2, 1.0);
static List<BoxShadow> get shadowPrimary => [...]
static List<BoxShadow> get shadowPrimaryLg => [...]
```

---

## Bölüm 2 — Mobil Flutter App

### Tamamlanan Bileşenler

| Bileşen | Dosya | Durum |
|---------|-------|-------|
| `AppCard` | `shared_ui_components/app_card.dart` | ✅ — static card, 20px radius, shadow |
| `PressableCard` | `shared_ui_components/app_card.dart` | ✅ — scale 0.97, shadow depth animation |
| `AppButton` | `shared_ui_components/app_button.dart` | ✅ — primary/secondary/ghost/danger |
| `GradientButton` | `shared_ui_components/app_button.dart` | ✅ — bordo→kırmızı gradient, shadowPrimary, scale 0.97 |
| `AppChip` | `shared_ui_components/app_chip.dart` | ✅ — 6 renk varyantı + filled/outline |
| `AppFilterChip` | `shared_ui_components/app_filter_chip.dart` | ✅ |
| `AppShimmer` | `shared_ui_components/app_skeleton.dart` | ✅ — sweeping gradient shimmer |
| `AppSkeletonLine/Box/Card` | `shared_ui_components/app_skeleton.dart` | ✅ |
| `AppSectionHeader` | `features/shared/ui/components/app_section_header.dart` | ✅ — kırmızı sol bar accent |
| `BusinessTile` | `features/shared/ui/business_tile.dart` | ✅ — AppCard tabanlı, badge/distance/quality chips |

### Kalan Eksikler

#### 2.1 SuccessOverlay Widget
**Henüz yok.** Her başarılı form işlemi sonrası kullanılacak.

```dart
// features/shared/ui/components/success_overlay.dart
class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;
  // ...
}

// AnimationController: elasticPop curve ile 0.7 → 1.0 scale
// FadeTransition + ScaleTransition combo
// Auto-dismiss: 2.5 saniye sonra
// Kullanım: favoriye ekle, fiyat önerisi gönder, yorum gönder
```

#### 2.2 Login Page Arka Plan Dekorasyonu
**Henüz yok.** Şu an düz arka plan.

```dart
// lib/features/auth/ui/login_page.dart — Stack ile üst üste:
// [1] Positioned(top: -40, right: -40): 200x200 radial bordo dot
// [2] Positioned(bottom: -60, left: -40): 240x240 radial kırmızı dot
// [3] Gradient overlay: F9FAFB → FDF8F7 (yukarıdan aşağıya)
// [4] Mevcut login form içeriği
```

#### 2.3 AppEmptyState Gradient Circle
**Mevcut web empty state'lerde SVG icon yapıldı**, mobil orijinal widget henüz güncellenmedi.

```dart
// packages/shared_ui_components/lib/src/app_empty_state.dart
// İkon container: 80x80, BoxShape.circle
// Gradient: RadialGradient → primary.withValues(alpha: 0.10) → transparent
// Şu anki: düz renk veya icon
```

#### 2.4 Tab Indicator Animasyonu
Discovery, profile gibi tablar — pill indicator animasyonu eksik.

```dart
// app_theme.dart:
tabBarTheme: TabBarThemeData(
  indicatorSize: TabBarIndicatorSize.label,
  indicator: UnderlineTabIndicator(  // → BoxDecoration ile gradient pill'e çevir
    borderSide: BorderSide(color: AppColors.primary, width: 2),
  ),
),
```

---

## Bölüm 3 — Next.js Web

### Tamamlanan Bileşenler

| Bileşen | Dosya | Durum |
|---------|-------|-------|
| `AppCard`, `PressableCard` | `src/ui/components/app-card.tsx` | ✅ |
| `AppButton`, `GradientButton` | `src/ui/components/app-button.tsx` | ✅ |
| `AppChip`, `CategoryChip`, `StatusChip` | `src/ui/components/app-chip.tsx` | ✅ |
| `AppSectionHeader` | `src/ui/components/app-section-header.tsx` | ✅ |
| `BusinessTile` | `src/ui/components/business-tile.tsx` | ✅ |
| `card-interactive` CSS | `globals.css` | ✅ |
| `btn-primary` CSS | `globals.css` | ✅ |
| Shimmer skeleton | `globals.css` | ✅ |
| `animate-sheet-in/overlay-in/success-pop` | `globals.css` | ✅ |
| `animate-slide-up/fade-scale-in/float` | `globals.css` | ✅ |
| Landing scan/row/device/rise animations | `globals.css` | ✅ |
| `PanelActionButton` hover + gradient | `src/ui/components/panel-action-button.tsx` | ✅ |
| `MetricCard` hover lift | `src/ui/components/metric-card.tsx` | ✅ |

### Kalan Eksikler

#### 3.1 Dark Mode (Web) — BÜYÜK EKSİK

**Etkilenen:** Tüm `apps/web_next` sayfaları.

```css
/* tokens.css — dark tema değişkenleri */
@media (prefers-color-scheme: dark) {
  :root {
    --yd-color-bg: #0f0f0f;
    --yd-color-card: #1a1a1a;
    --yd-color-card-alt: #141414;
    --yd-color-border: #2a2a2a;
    --yd-color-border-strong: #3a3a3a;
    --yd-color-text: #e2e8f0;
    --yd-color-text-strong: #f8fafc;
    --yd-color-muted: #94a3b8;
    --yd-color-bg-rgb: 15 15 15;
    --yd-color-card-rgb: 26 26 26;
    /* primary/success/warning/danger değişmez */
  }
}
```

Tailwind config'de `darkMode: 'media'` eklenmeli. Mobil AppDarkColors ile senkronize edilmeli.

#### 3.2 Public Menu Page — Menü Item Görsel Yenileme

**Dosya:** `src/ui/sections/public-menu-client.tsx`

Şu an düz kart. Eksikler:
- Sol kenar hover highlight (opacity-0 → opacity-100)
- Item görseli `group-hover:scale-105` zoom
- Sticky header `backdrop-blur-md bg-card/90`
- Hero banner gradient overlay (siyah/60 → transparent)

```tsx
// Menü item kartına class ekle:
<div className="card-interactive group relative flex gap-3 p-3 rounded-xl border border-border bg-card cursor-pointer">
  {/* Sol accent bar */}
  <div className="absolute left-0 inset-y-0 w-0.5 rounded-l-xl bg-gradient-to-b from-primary to-primaryStrong
                  opacity-0 group-hover:opacity-100 transition-opacity duration-150" />
  {/* Görsel */}
  <div className="relative w-[72px] h-[72px] shrink-0 rounded-xl overflow-hidden">
    <Image className="object-cover group-hover:scale-105 transition-transform duration-300" />
  </div>
```

#### 3.3 Category Pill Aktif State Animasyonu

Discover, Heroes, Reviews sort sectionlarında kategoriler var. Aktif pill geçişi anlık — smooth animasyon eksik.

```tsx
// Aktif pill arka plan — link yerine button kullanılan yerlerde:
{isActive && (
  <span className="absolute inset-0 rounded-full"
    style={{
      background: 'var(--yd-gradient-primary)',
      animation: 'fade-scale-in 200ms var(--yd-ease-spring) forwards',
    }}
  />
)}
<span className="relative z-10">{label}</span>
```

#### 3.4 Sayfa Geçiş Animasyonu

**Dosya:** `apps/web_next/app/template.tsx` (yeni oluşturulacak)

```tsx
// app/template.tsx (zaten var — content boş)
// Mevcut template.tsx'e CSS animasyon ekle:
export default function Template({ children }) {
  return (
    <div style={{ animation: 'slide-up 280ms var(--yd-ease-spring) both' }}>
      {children}
    </div>
  );
}
```

#### 3.5 Fiyat Geçmişi Sparkline — Dark Mode Renkleri

`menu-item-detail-sheet.tsx`'teki sparkline `#b91c1c`/`#15803d` hardcoded renkleri kullanıyor.  
Dark mode geldiğinde `var(--yd-color-danger)` ve `var(--yd-color-success)` kullanılmalı.

---

## Bölüm 4 — Tipografi (Devam Eden)

### Tamamlanan
- `AppTypographyX.sectionTitleStyle` — 16sp w900 standard ✅
- `font-display` (Playfair) büyük başlıklarda uygulandı ✅
- `font-[900]` agresif weight tüm başlıklarda ✅

### Kalan

```css
/* tokens.css'e eklenecek utility sınıflar */
.yd-heading-xl { font-size: 2.5rem; font-weight: 900; letter-spacing: -0.05em; line-height: 1.05; }
.yd-heading-lg { font-size: 1.75rem; font-weight: 900; letter-spacing: -0.03em; line-height: 1.1; }
.yd-label     { font-size: 0.6875rem; font-weight: 700; letter-spacing: 0.05em; text-transform: uppercase; }
```

```dart
// app_typography.dart — mevcut extension'a ekle:
TextStyle get headingXl => const TextStyle(
  fontSize: 32, fontWeight: FontWeight.w900,
  letterSpacing: -0.8, height: 1.05,
);
TextStyle get eyebrow => const TextStyle(
  fontSize: 11, fontWeight: FontWeight.w700,
  letterSpacing: 0.6, color: AppColors.muted,
);
```

---

## Bölüm 5 — Renk Katman Rehberi (Güncellendi)

| Katman | Değer | Uygulama |
|--------|-------|---------|
| `primary` | `#7F1D1D` | Solid buton, aktif state, accent bar |
| `primaryStrong` | `#DC2626` | Gradient son, hover, badge |
| `primarySoft` | `#F9E7E7` | Chip bg, tag bg, soft badge |
| `primary/[0.12]` | rgba 12% | İkon container bg |
| `primary/[0.08]` | rgba 8% | Card hover overlay |
| `primary/[0.04]` | rgba 4% | Çok hafif vurgu |
| `primary/[0.24]` | rgba 24% | shadowPrimary |
| `primary/[0.32]` | rgba 32% | shadowPrimaryLg (hover) |

### Gölge Hiyerarşisi

| Token | Tailwind | Kullanım |
|-------|---------|---------|
| `--yd-shadow-1` | `shadow-yd1` | Satır elemanları, subtle |
| `--yd-shadow-2` | `shadow-yd2` | Normal kartlar |
| `--yd-shadow-3` | `shadow-yd3` | Hover kartlar |
| `--yd-shadow-4` | — | Modal, drawer |
| `--yd-shadow-primary` | — | Primary buton normal |
| `--yd-shadow-primary-lg` | — | Primary buton hover |

---

## Bölüm 6 — Güncel Uygulama Sırası

### Sprint 1 — TAMAMLANDI ✅
- Token sistemi (easing, shadow, gradient)
- Mobile: PressableCard, GradientButton, AppShimmer
- Web: card-interactive, btn-primary, animasyonlar
- Web bileşen sistemi (AppCard, AppButton, AppChip, AppSectionHeader, BusinessTile)
- Panel taşıma: PanelActionButton gradient, MetricCard hover

### Sprint 2 — TAMAMLANDI ✅
- Renkli shadow (shadowPrimary)
- Business detail page hero + hours + contact + photos
- Profile 3-sekme + XP bar + achievements + daily task
- Discover kategori chips + top businesses strip
- Smart feed behavior segment + diet profil
- Ana sayfa gradient hero + sosyal kanıt

### Sprint 3 — Şu An Hedef

```
[1] Web dark mode — tokens.css @media dark + Tailwind darkMode: 'media'
    → Önce bg/card/border/text token'ları
    → Sonra test: business detail, discover, profile

[2] Public menu item hover — card-interactive + sol accent bar + görsel zoom
    → src/ui/sections/public-menu-client.tsx

[3] Mobile: SuccessOverlay widget
    → features/shared/ui/components/success_overlay.dart

[4] Mobile: Login page dekoratif arka plan
    → features/auth/ui/login_page.dart

[5] Web: template.tsx sayfa geçiş animasyonu
    → app/template.tsx (mevcut boş dosya)

[6] Mobile: AppEmptyState gradient icon circle
    → packages/shared_ui_components/lib/src/app_empty_state.dart (henüz yok)

[7] Mobile: Tab pill indicator → gradient BoxDecoration
    → app_theme.dart tabBarTheme
```

### Sprint 4 — Kısmen Tamamlandı

```
[8] Web dark mode: tokens + globals.css ✅ — Toggle butonu eksik
[9] ✅ Tipografi utility class'ları: .yd-heading-xl/lg/md + .yd-eyebrow + .yd-caption + .yd-numeric (2026-05-04)
[10] ✅ Fiyat sparkline dark mode: currentColor + text-danger/success/muted Tailwind class (2026-05-04)
[11] ✅ Category pill smooth animasyon: opacity-based gradient overlay (2026-05-04)
[12] Mobile: BottomSheet drag handle — bottomSheetTheme radius 28px zaten var, drag handle bazı sheet'lerde eksik
```

### Sprint 5 — Kısmen Tamamlandı
```
[x] Dark mode toggle butonu — ana sayfa navbar'ına eklendi (ThemeToggle, localStorage, flash prevention) (2026-05-04)
[x] darkMode: 'class' (Tailwind) — html.dark + html.light + @media fallback (2026-05-04)
[ ] Mobile BottomSheet drag handle — bazı sheet'lerde eksik
[ ] Dark mode full test: tüm sayfa snapshot'ları
```

---

## Kontrol Listesi

### Token Güncellemeleri
- [x] Easing fonksiyonları (spring, elasticPop, smoothOut)
- [x] Layered shadow sistemi (S1–S4 + SP + SPLg)
- [x] Gradient token'lar (primary, soft, hero, surface, card-hover)
- [x] CSS variables `tokens.css` ✅
- [x] Flutter `AppTokens` ✅

### Mobile Flutter
- [x] PressableCard — BusinessTile ve review kartlarında
- [x] GradientButton — login CTA, form CTA'ları
- [x] AppShimmer — shimmer sweep animasyon
- [x] AppSkeletonLine/Box/Card — tüm loading state'ler
- [x] BusinessTile — AppCard, badge chips, quality score
- [x] RepaintBoundary — tüm feed item render'ları
- [x] SuccessOverlay widget — zaten mevcut (`features/shared/ui/components/success_overlay.dart`) ✅
- [x] Login page dekoratif arka plan — zaten mevcut (RadialGradient + 2 circle) ✅
- [x] AppEmptyState gradient icon circle — zaten mevcut (RadialGradient, alpha 0.10→0.04) ✅
- [x] Tab indicator → gradient pill (BoxDecoration + LinearGradient bordo→kırmızı + shadow) (2026-05-04)

### Next.js Web
- [x] tokens.css easing + shadow + gradient ✅
- [x] globals.css animasyonlar (float, slide-up, fade-scale-in, shimmer) ✅
- [x] `card-interactive` class ✅
- [x] `btn-primary` gradient + hover ✅
- [x] `AppCard`, `AppButton`, `AppChip`, `AppSectionHeader`, `BusinessTile` ✅
- [x] GradientButton web eşdeğeri ✅
- [x] Focus-visible ring tüm interaktif elemanlarda ✅
- [x] min-h-[44px] tüm touch hedefler ✅
- [x] Business detail hero + hours + photos ✅
- [x] Profile 3-sekme + XP + achievements ✅
- [x] Public menu item sol accent bar (opacity-0 → opacity-100, gradient, group-hover)
- [x] Görsel zoom group-hover:scale-[1.04] zaten vardı ✅
- [x] Dark mode tokens — tokens.css @media dark (bg/card/border/text/shadow) (2026-05-04)
- [x] globals.css dark body background radial gradient (2026-05-04)
- [x] Tailwind darkMode: 'media' + borderStrong token eklendi (2026-05-04)
- [x] Template.tsx sayfa geçiş animasyonu zaten vardı (slide-up 260ms) ✅
- [x] Category pill gradient — opacity-based smooth geçiş (absolute span, opacity-0→100) (2026-05-04)
- [x] Sticky header backdrop-blur-md güçlendirildi

### Panel (Artık Next.js)
- [x] `panel_flutter_web` silindi — Next.js'e geçildi
- [x] PanelActionButton primary → gradient + colored shadow
- [x] MetricCard hover lift + border color
- [x] PanelPageHeader (eyebrow + title + description pattern)
- [x] focus-visible ring tüm panel butonlarında

---

## Referanslar

- **Linear.app** — sidebar animasyon, hover feedback, typographic hierarchy
- **Vercel Dashboard** — metric card depth, hover state, table styling
- **Stripe** — gradient button, shadow system, smooth transitions
- **Framer** — micro-animation, spring easing
- **Luma** — card tasarımı, backdrop blur

---

*Güncelleme: `panel_flutter_web` tüm referanslar kaldırıldı (silindi). Sprint 1+2 tamamlandı olarak işaretlendi. Dark mode ve public menu iyileştirmeleri Sprint 3'e alındı.*
