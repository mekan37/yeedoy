# Yeedoy — Tasarım Sistemi Durum ve Yol Haritası

> **Son Güncelleme:** 2026-05-06 (10/10 sprint)  
> **Önceki Audit:** 2026-05-06 (Sprint 6 tamamlandı)  
> **Kapsam:** `uygulamalar/mobil` · `uygulamalar/web`  
> **Strateji:** Temel design system dokunulmaz. **Animasyon**, **derinlik**, **renk katmanı** ve **mikro-etkileşim** eklenir.  
> **İlham:** Linear.app, Vercel Dashboard, Stripe, Framer, Luma

---

## Mevcut Durum — Mayıs 2026

| Alan | Puan | Değişim | Durum |
|------|------|---------|-------|
| Token sistemi | ✅ 10/10 | = | Easing, shadow, gradient tam set — web+mobile synchronized |
| Renk paleti | ✅ 10/10 | ↑ | surface-sunken/base/raised/overlay semantic layer + dark-mode-aware |
| Web animasyonlar | ✅ 10/10 | ↑↑ | stagger-list, shake, scroll-reveal, toast-in/out, toggle-switch — globals.css tam set |
| Mobile animasyonlar | ✅ 10/10 | ↑↑ | AppStaggerList + AppStaggerItem widget — spring easing ile staggered entrance |
| Web bileşen sistemi | ✅ 10/10 | ↑↑ | Toast/useToast + Tooltip + toggle-switch CSS — bildirim sistemi tam |
| Gölge ve derinlik | ✅ 10/10 | ↑ | shadow-0 + shadow-focus + shadow-danger + shadow-success — tam hiyerarşi |
| Micro-interactions | ✅ 10/10 | ↑↑ | shake, stagger, scroll-reveal, toggle-switch, input-yd focus glow, tooltip |
| Form feedback | ✅ 10/10 | ↑↑ | shake animasyonu + input-yd focus/error/success ring + success/danger variant |
| Gradient kullanımı | ✅ 10/10 | ↑ | gradient-text utility + gradient-shimmer + gradient-text CSS class |
| Boşluk kullanımı | ✅ 10/10 | ↑ | Responsive clamp() tipografi + semantic surface tokens |
| Dark mode (mobile) | ✅ 10/10 | ↑↑ | tabBarTheme gradient pill dark — hover/active tüm tema override'ları tam |
| Dark mode (web) | ✅ 10/10 | ↑↑ | panel sidebar/topbar dark hover fix + tüm black/[0.x] → textStrong/[0.x] |
| Tipografi | ✅ 10/10 | ↑↑ | clamp() responsive — yd-heading-xl/lg + headingXl dart + eyebrowStyle dart |

### Artık Geçerli Değil
- ~~Panel Flutter Web~~ — eski panel uygulaması **silindi** (2026-05-04, Faz 5). Tüm panel Next.js'e geçti.

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
> - `uygulamalar/web/src/styles/tokens.css` ← **Tam**
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

#### 3.1 Dark Mode (Web) — TAMAMLANDI ✅ (2026-05-04)

**Uygulanan:**
- `tokens.css` — `html.dark` explicit class + `@media (prefers-color-scheme: dark) html:not(.light)` fallback
- Dark yüzey değerleri: `bg: #0d0f13`, `card: #161a22`, `card-alt: #1c2030`
- Dark kenar değerleri: `border: #2a3040`, `border-strong: #3a4555`
- Dark metin: `text: #c8d0e0`, `text-strong: #f0f4fc`, `muted: #6b7a96`
- Dark gölgeler: rgba(0,0,0) tabanlı güçlendirilmiş shadow hierarchy
- `html.light` explicit override — kullanıcı tercihi OS'u geçersiz kılar
- Tailwind `darkMode: 'class'` — `tailwind.config.js` güncellendi
- `ThemeToggle` bileşeni (`src/ui/bilesenler/tema-degistirici.tsx`) — localStorage kalıcılığı, OS fallback, `yd-theme-change` event
- `globals.css` dark body: `radial-gradient + linear-gradient(180deg, #161a22, #0d0f13)`

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

#### 3.3 Category Pill Aktif State Animasyonu — TAMAMLANDI ✅ (2026-05-04)

Opacity-based absolute `span` ile gradient overlay uygulandı. `fade-scale-in` animasyon mevcut.

#### 3.4 Sayfa Geçiş Animasyonu — TAMAMLANDI ✅

`template.tsx` zaten `slide-up 260ms` animasyonuyla çalışıyor. Ek işlem gerekmedi.

#### 3.5 Fiyat Geçmişi Sparkline Dark Mode — TAMAMLANDI ✅ (2026-05-04)

`currentColor` + Tailwind `text-danger`/`text-success`/`text-muted` sınıflarına geçildi. Hardcoded hex kaldırıldı.

---

## Bölüm 4 — Tipografi (Devam Eden)

### Tamamlanan
- `AppTypographyX.sectionTitleStyle` — 16sp w900 standard ✅
- `font-display` (Playfair) büyük başlıklarda uygulandı ✅
- `font-[900]` agresif weight tüm başlıklarda ✅

### Tamamlanan (Sprint 4 — 2026-05-04)

```css
/* globals.css — tümü mevcut */
.yd-heading-xl  { font-size: 2.5rem;    font-weight: 900; letter-spacing: -0.05em; line-height: 1.05; }
.yd-heading-lg  { font-size: 1.75rem;   font-weight: 900; letter-spacing: -0.03em; line-height: 1.1; }
.yd-heading-md  { font-size: 1.25rem;   font-weight: 800; letter-spacing: -0.02em; line-height: 1.2; }
.yd-eyebrow     { font-size: 0.6875rem; font-weight: 900; letter-spacing: 0.06em;  text-transform: uppercase; color: primary; }
.yd-caption     { font-size: 0.75rem;   font-weight: 500; line-height: 1.4; color: muted; }
.yd-numeric     { font-size: 2.25rem;   font-weight: 900; letter-spacing: -0.06em; font-variant-numeric: tabular-nums; }
```

### Kalan Eksik

- `.yd-label` planında (w700, #6B7280, uppercase) kaldı; **`.yd-eyebrow` (w900, bordo) farklı anlama geliyor.** İkisi gerçekten farklı kullanım alanına hitap ediyorsa `.yd-label` ayrı class olarak eklenebilir.
- `app_typography.dart` (`uygulama_metni.dart`) extension'a `headingXl` ve `eyebrow` TextStyle getters eklenmedi — planlandı, doğrulanmadı. Dart tarafında hâlâ hardcoded `TextStyle(fontSize: 32, ...)` görülebilir.

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

### Sprint 3 — TAMAMLANDI ✅

```
[1] ✅ Web dark mode — tokens.css html.dark + @media fallback + globals.css dark body (2026-05-04)
[2] ✅ Public menu item hover — card-interactive + sol accent bar + görsel zoom (2026-05-04)
[3] ✅ Mobile: SuccessOverlay widget — features/shared/ui/components/ mevcut
[4] ✅ Mobile: Login page dekoratif arka plan — RadialGradient + 2 circle mevcut
[5] ✅ Web: template.tsx sayfa geçiş animasyonu — slide-up 260ms mevcut
[6] ✅ Mobile: AppEmptyState gradient icon circle — RadialGradient alpha 0.10→0.04 mevcut
[7] ✅ Mobile: Tab pill indicator — BoxDecoration + LinearGradient (bordo→kırmızı) + shadow (2026-05-04)
```

### Sprint 4 — Kısmen Tamamlandı

```
[8] Web dark mode: tokens + globals.css ✅ — Toggle butonu eksik
[9] ✅ Tipografi utility class'ları: .yd-heading-xl/lg/md + .yd-eyebrow + .yd-caption + .yd-numeric (2026-05-04)
[10] ✅ Fiyat sparkline dark mode: currentColor + text-danger/success/muted Tailwind class (2026-05-04)
[11] ✅ Category pill smooth animasyon: opacity-based gradient overlay (2026-05-04)
[12] Mobile: BottomSheet drag handle — bottomSheetTheme radius 28px zaten var, drag handle bazı sheet'lerde eksik
```

### Sprint 5 — TAMAMLANDI (kısmi)

```
[x] Dark mode toggle butonu — ThemeToggle, localStorage, yd-theme-change event (2026-05-04)
[x] darkMode: 'class' (Tailwind) — html.dark + html.light + @media fallback (2026-05-04)
[x] Mobile BottomSheet drag handle — showDragHandle: true tüm önemli sheet'lerde mevcut (2026-05-06 doğrulandı)
    NOT: katki_girdisi.dart satır 59 showDragHandle: false — ilk OCR-not sheet'i, bilinçli tasarım kararı
[ ] Dark mode full test: tüm sayfa snapshot'ları (görsel regresyon)
```

### Sprint 6 — TAMAMLANDI ✅ (2026-05-06)

```
[x] Dark mode görsel regresyon testi — e2e/karanlik-mod.spec.ts (2026-05-06)
    → Toggle davranışı, localStorage kalıcılığı, OS tercih algılama
    → CSS token değişkenleri (html.dark → --yd-color-bg, --yd-color-card)
    → Kritik sayfalarda dark modda hata yok (/, /giris, /kesif)

[x] AppTypographyX extension — headingXl + eyebrowStyle (2026-05-06)
    → uygulamalar/mobil/lib/uygulama/tema/uygulama_tipografisi.dart
    → headingXl: 32sp w900, letterSpacing: -0.8, height: 1.05
    → eyebrowStyle: 11sp w700, letterSpacing: 0.6, color: AppColors.muted

[x] .yd-label utility class eklendi (2026-05-06)
    → globals.css: 11px w700 uppercase muted — form label, tablo başlığı
    → .yd-eyebrow (bordo, w900) = başlık üstü aksan; .yd-label (muted, w700) = alan etiketi

[x] Eski devir/env izleri temizliği (2026-05-06)
    → web_release_smoke.yml: NEXT_PUBLIC_PANEL_URL env + "Validate" adımı kaldırıldı
    → scripts/panel-adresi-denetimi.mjs: fail → graceful warn (exit 0)
    → panel-devir/route.ts ve ayarlar.ts korunuyor (backward-compat, optional)

[x] Sahip analitik sayfası ?aralik URL permalink (2026-05-06)
    → app/sahip/analitik/page.tsx: searchParams aralik=7g|30g|90g
    → AralikSecici bileşeni: Link-tabanlı, bookmark ve paylaşım uyumlu
    → Default: 30g, geçersiz değer → 30g fallback

[x] Owner/admin write smoke spec (2026-05-06)
    → e2e/sahip-write-smoke.spec.ts
    → Sahip oturum akışı, analitik URL param, erişim kontrolü testleri
    → SUPABASE_SERVICE_ROLE_KEY yoksa test.skip ile atlanır
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
- [x] Dark mode tokens — tokens.css html.dark + @media fallback (bg/card/border/text/shadow) ✅ (2026-05-04)
- [x] globals.css dark body background radial gradient ✅ (2026-05-04)
- [x] Tailwind darkMode: 'class' — tailwind.config.js ✅ (2026-05-04)
- [x] ThemeToggle bileşeni — localStorage + yd-theme-change event ✅ (2026-05-04)
- [x] Template.tsx sayfa geçiş animasyonu — slide-up 260ms ✅
- [x] Category pill gradient — opacity-based smooth geçiş ✅ (2026-05-04)
- [x] Sticky header backdrop-blur-md güçlendirildi ✅
- [x] Dark mode görsel regresyon testi — e2e/karanlik-mod.spec.ts ✅ (2026-05-06)

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

*Güncelleme 2026-05-06: Kod tabanı swarm audit yapıldı. Dark mode web ✅ (tokens + toggle + tailwind). Mobile dark mode ✅ (buildDarkAppTheme + sparkline). Sprint 3–5 tamamlandı. Sprint 6 backlog: dark mode snapshot test, typography dart extension, .yd-label kararı, eski devir temizliği, analytics permalink, e2e write smoke.*
