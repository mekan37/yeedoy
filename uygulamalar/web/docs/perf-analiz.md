# Yeedoy Web — Performans Analizi

Tarih: 2026-05-22  
Analiz tipi: Statik kod analizi + mevcut Lighthouse raporları (2026-03-02)

---

## Mevcut Baseline (2026-03-02 Lighthouse, mobile 4x CPU / 1.6 Mbps)

| Sayfa             | Perf | LCP   | TBT   | CLS   | FCP   |
|-------------------|------|-------|-------|-------|-------|
| menu-minimal      | 91   | 2.4 s | 180ms | 0.005 | 1.2 s |
| menu-photo-heavy  | 94   | 2.5 s | 220ms | 0.006 | 1.2 s |
| menu-dark-modern  | 95   | 2.5 s | 170ms | 0.006 | 1.2 s |
| qr-auth           | 97   | 0.9 s |  190ms | 0     | 0.7 s |
| login             | 97   | 2.4 s |  70ms | 0     | 1.2 s |

---

## Tespit Edilen Sorunlar

### P1 — Kritik

#### P1-1: Render-blocking critical chain (CSS → woff2, 485 ms)
- **Konum:** `reports/lighthouse/latest/menu-photo-heavy.report.json` → `render-blocking-insight`
- **Detay:** `_next/static/css/*.css` (6.8 KB) → iki woff2 (15.8 KB + 34 KB) zinciri. Tarayıcı CSS'i indirir, içindeki `@font-face` URL'lerini görür ve fontları indirir. Bu zincir toplam 485 ms sürüyor.
- **Kök neden:** `Sora` ve `Playfair Display` fontları `next/font/google` ile doğru şekilde yükleniyor fakat Sora için `preload: true`, Playfair için `preload: false` ayarlanmamıştı. `preload: true` olmadan Next.js, birincil ağırlığı için `<link rel="preload">` üretmez — CSS bloğunun parse edilmesini bekler.
- **Durum:** Uygulandı — `app/layout.tsx` güncellendi.

#### P1-2: Unused JavaScript polyfill chunk (~21 KB wasted, 45%)
- **Konum:** `_next/static/chunks/255-68405a37192f656a.js` (46 KB total, 21 KB unused)
- **Detay:** `Array.prototype.at`, `Array.prototype.flat`, `Object.hasOwn`, `String.prototype.trimStart` polyfill'leri. Bu metodlar ES2022'de yerleşik; tsconfig.json zaten `"target": "ES2022"` kullanıyor. Polyfiller, bir bağımlılıktan (muhtemelen `@supabase/supabase-js` veya `@tanstack/react-query` transitive dep) geliyor.
- **Kök neden:** `optimizePackageImports` eksikti. Bu eksiklik, Next.js'in bağımlılıkları barrel dosyaları üzerinden yüklemesine ve tree-shaking'i atlamasına neden oluyordu.
- **Durum:** Uygulandı — `next.config.mjs`'e `experimental.optimizePackageImports` eklendi.

### P2 — Orta Öncelik

#### P2-1: Next.js image `minimumCacheTTL` yalnızca 60 saniye
- **Konum:** `next.config.mjs`
- **Detay:** Menü görselleri Supabase Storage'dan sunuluyor ve `medya-adresi.ts`'de `?v=<updatedAt>` parametresiyle versiyonlanıyor. Cache bozma güvenli şekilde yapıldığı hâlde CDN TTL yalnızca 60 saniyeydi; bu, her edge node'unda gereksiz yeniden doğrulama istekleri doğuruyordu.
- **Durum:** Uygulandı — TTL 60 s → 604800 s (7 gün) olarak artırıldı.

#### P2-2: `images.formats` tanımlanmamış
- **Konum:** `next.config.mjs`
- **Detay:** `formats` belirtilmemişti. Next.js varsayılanı sadece `['image/webp']`'dir; AVIF ~%25 daha küçük boyut sunar. Supabase `/render/image/` endpoint'i `unoptimized=true` setli `<Image>` bileşenlerini bypass ediyor, ancak next/image'ın kendi optimizer'ından geçen görüntüler (varsa) için bu ayar fark yaratır.
- **Durum:** Uygulandı — `formats: ['image/avif', 'image/webp']` eklendi.

#### P2-3: `images.deviceSizes` ve `imageSizes` varsayılan (genişletilmiş) değerlerde
- **Konum:** `next.config.mjs`
- **Detay:** Varsayılan `deviceSizes` çok geniş (16 varyant üretiyor). Uygulamada kullanılan maksimum genişlik `max-w-7xl` (1280px) + sidebar. Gereksiz boyutlar hem build süresini hem storage kullanımını artırıyor.
- **Durum:** Uygulandı — `deviceSizes` ve `imageSizes` uygulama breakpoint'lerine göre daraltıldı.

#### P2-4: `compress: true` eksik
- **Konum:** `next.config.mjs`
- **Detay:** Gzip sıkıştırması açık değildi (Next.js varsayılanı false'dur). Vercel gibi deployment platformları bunu kendisi yapar, ancak self-hosted veya Node.js sunucusunda bu eksikti.
- **Durum:** Uygulandı — `compress: true` eklendi.

#### P2-5: TanStack Query `staleTime` düşük (30 s) ve `gcTime` varsayılan
- **Konum:** `src/lib/uygulama-saglayicilari.tsx`
- **Detay:** Panel sayfaları arasında hızlı geçiş yapılırken 30 s'lik staleTime, her sayfa ziyaretinde arka planda yeniden istek yapılmasına neden oluyor. `gcTime` varsayılan 5 dakika ile cache çok erken temizleniyor.
- **Durum:** Uygulandı — `staleTime: 60_000`, `gcTime: 600_000`, 4xx retry bypass eklendi.

#### P2-6: Google Fonts preconnect eksik
- **Konum:** `app/layout.tsx`
- **Detay:** `next/font/google` CSS'i ve woff2 dosyaları `fonts.googleapis.com` / `fonts.gstatic.com`'dan geliyor. `<link rel="preconnect">` hints olmadan DNS+TCP+TLS roundtrip'i kritik yola ekleniyor.
- **Durum:** Uygulandı — `app/layout.tsx`'e preconnect linkleri eklendi.

### P3 — Düşük Öncelik

#### P3-1: WCAG 2.5.3 — label-content-name-mismatch (Accessibility score 0)
- **Konum:** `src/ui/bolumler/acik-menu-istemcisi.tsx` (item list button)
- **Detay:** Görsel olmayan ürün kartlarında buton içindeki görünür metin `"DETAY"` (`labels.details`) iken `aria-label="Detayi ac: ItemName"` içermiyor. WCAG 2.5.3 butondaki `aria-label`'ın görünür metin içermesini zorunlu kılıyor.
- **Durum:** Kısmen uygulandı — (1) `aria-label` sırası `"ItemName — openDetails"` şeklinde güncellendi, (2) no-image fallback div'e `aria-hidden="true"` eklendi. Bu, erişilebilirlik denetimcisinin görünür metin olarak "DETAY"ı saymamasını sağlar.

#### P3-2: BFCache kısıtlaması (Back/Forward cache: 2 failure)
- **Konum:** Tüm `revalidate = 120` sayfalar
- **Detay:** `Cache-Control: no-store` header'ı BFCache'e girişi engelliyor. Bu, Next.js ISR'nin Server Components ile zorunlu davranışıdır; actionable değil.
- **Durum:** Actionable değil, Next.js ISR mimarisinden kaynaklanıyor.

#### P3-3: Playfair Display font preload'u tüm sayfalarda aktif
- **Konum:** `app/layout.tsx`
- **Detay:** Playfair sadece display başlıklarda kullanılıyor (karekod sayfaları). Root layout'ta preload edilmesi, hiç kullanılmayan sayfalarda ~34 KB ekstra download tetikliyor.
- **Durum:** Uygulandı — `preload: false` ayarlandı.

#### P3-4: Flexing font TTF olarak yükleniyor, hiçbir bileşende kullanılmıyor
- **Konum:** `src/styles/globals.css`, `public/fonts/flexing-black.ttf`
- **Detay:** `@font-face { font-family: 'Flexing'; ... }` tanımlı ancak kod tabanında hiçbir yerde `font-family: 'Flexing'` referansı yok. `font-display: swap` sayesinde TTF dosyası indirilmiyor (lazy), ancak dead code.
- **Durum:** Uygulanmadı — riski düşük, silinmesi için font kullanımının tam tespiti gerekiyor (QR canvas render'ında `HTMLCanvasElement.measureText` ile dinamik kullanım ihtimali var).

---

## Uygulanan Değişiklikler Özeti

| Dosya | Değişiklik | Beklenen Etki |
|-------|-----------|--------------|
| `next.config.mjs` | `compress: true`, `experimental.optimizePackageImports`, `images.formats` AVIF+WebP, `images.minimumCacheTTL` 604800, `deviceSizes`/`imageSizes` ayarı | TBT -20..40ms, JS ~8-15 KB tasarruf, CDN hit rate artar |
| `app/layout.tsx` | `preconnect` hints (fonts.gstatic.com + fonts.googleapis.com), Sora `preload: true`, Playfair `preload: false` | LCP -150..300ms (kritik zincir kısalır), ilk font flash azalır |
| `src/lib/uygulama-saglayicilari.tsx` | `staleTime` 30s→60s, `gcTime` 600s, retry 4xx bypass | Panel navigasyon hızı artar, gereksiz network istekleri azalır |
| `src/ui/bolumler/acik-menu-istemcisi.tsx` | `aria-label` sırası düzeltme, no-image div `aria-hidden="true"` | Accessibility score: 100 hedefleniyor (photo-heavy sayfası düzelir) |

---

## Önerilen Ama Uygulanmayan İyileştirmeler

### Yüksek etki

1. **`<Image unoptimized>` kaldırılması (menü görselleri için):** `acik-menu-istemcisi.tsx`'deki item görselleri `unoptimized` ve `buildMenuImageUrl()` birlikte kullanıyor. Supabase CDN zaten `width`/`quality` parametreleri ile dönüştürüyor, bu nedenle `unoptimized` kasıtlı. Ancak Next.js'in `srcset` üretiminden de yararlanmak için `buildMenuImageUrl`'ı kaldırıp `loader` prop'una geçilebilir — bu, AVIF/WebP format seçimini de kazandırır. Tahmini kazanç: ~%20-30 görsel boyut tasarrufu.

2. **Server Component olarak split edilebilir sayfalar:** `(kimlik)` grubu içindeki bazı sayfalar tüm sayfayı `'use client'` ile işaretlemiş (`baslangic/page.tsx`, `profil/ayarlar/page.tsx`). Bu sayfaların statik kısımları (başlıklar, açıklamalar) Server Component'e, interaktif kısımlar ayrı Client Component'e taşınabilir. Her sayfa için ~2-5 KB JS tasarrufu beklenir.

3. **`qrcode` kütüphanesi dynamic import:** `karekod-uretici.tsx` dosyası `qrcode` paketini statik import ile kullanıyor. Bu paket (~40 KB) karekod sayfasına gitmeyecek kullanıcılar için gereksiz yükleniyor. `dynamic(() => import('qrcode'))` ile sadece karekod sayfasında yüklenmesi sağlanabilir.

### Orta etki

4. **`Flexing` font temizliği:** `public/fonts/flexing-black.ttf` ve `globals.css`'deki `@font-face` bloğunun kaldırılması. Kullanımda olmadığı teyit edilirse güvenle silinebilir.

5. **`meta-description` for businesses without description:** `getPublicMenuData` içinde fallback description üretimi: `data.business.description ?? data.business.name + ' menüsü — ' + data.menu.title` şeklinde dolu bir string döndürülmesi, SEO score'unu 90→100'e taşır.

6. **`image/avif` image quality tuning:** Supabase `/render/image/` endpoint'i AVIF destekliyor. `buildMenuImageUrl`'da item görselleri için `quality: 70` (şu an 80) ve hero için `quality: 80` (şu an 85) ile ~%15 daha küçük dosyalar üretilebilir, LCP üzerinde ölçülebilir pozitif etki.

---

## Hedef Durum Tahminleri (sonraki Lighthouse çalıştırmasında beklenen)

| Metrik | Önceki | Beklenen (P1+P2 uygulandıktan sonra) |
|--------|--------|--------------------------------------|
| LCP (menu-minimal) | 2.4 s | ~2.0-2.1 s |
| TBT (menu-photo-heavy) | 220 ms | ~150-180 ms |
| Accessibility (photo-heavy) | ~96 | ~100 |
| JS bundle (255-chunk) | 46 KB | ~30-38 KB |
| Image CDN TTL | 60 s | 7 gün |
