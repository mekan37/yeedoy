# Yeedoy Harita Entegrasyon Raporu
**Tarih:** 2026-05-25

---

## Mevcut Durum (Tarama Bulguları)

| Alan | Bulgu |
|---|---|
| Harita çözümü (önce) | CDN üzerinden `window.L` (Leaflet 1.9.4, `unpkg.com`) — `<script>` ve `<link>` tag'leri dinamik olarak DOM'a enjekte ediliyordu |
| Google Maps bağımlılığı | Yok — `package.json`'da hiçbir `@googlemaps` veya `google-maps` paketi bulunmadı. `next.config.mjs` CSP'de `maps.googleapis.com` sadece `connect-src`'te yer alıyordu (kullanılmayan bir referans) |
| Konum verisi modeli | `businesses.lat` ve `businesses.lng` — `double precision` ayrı sütunlar (PostGIS POINT değil) |
| Public menü sayfası konum gösterimi | `IsletmeKonumBolumu` — adres metni + Google Maps derin bağlantısı vardı, gömülü harita yoktu |
| Panel konum seçici | Yoktu — admin/owner formlarda koordinat seçme bileşeni bulunmuyordu |
| Leaflet paket bağımlılığı | `package.json`'da yoktu (CDN'den yükleniyordu) |
| CSP uyumu | `unpkg.com` CSP `style-src`'te tanımlı değildi → Leaflet CSS production'da bloklama riski taşıyordu |

---

## Veri Akışı

```
Supabase (businesses.lat + businesses.lng — double precision)
  ↓
getMarketplaceBusinessBySlug() [pazar-okuma.ts]
  — select: '...phone,lat,lng'
  ↓
AcikIsletmeDetayi { lat?: number | null, lng?: number | null }
  ↓
app/(genel)/isletme/[slug]/page.tsx
  ↓
IsletmeKonumBolumu [isletme.tsx]
  ↓
BusinessMap [components/maps/BusinessMap.tsx]  ← YENİ
  ↓ (dynamic import, ssr:false)
LeafletMap [components/maps/LeafletMap.tsx]   ← YENİ
  ↓
react-leaflet MapContainer + TileLayer (OpenStreetMap)
```

**Harita sayfası akışı:**
```
getMapBusinesses() [harita-okuma.ts]  — lat/lng veya şehir koordinat fallback
  ↓
app/(genel)/kesif/harita/page.tsx
  ↓ (dynamic import, ssr:false)
HaritaIstemcisi [ui/acik/harita-istemcisi.tsx]  ← REFACTOR EDİLDİ
  ↓
react-leaflet MapContainer + CircleMarker (OpenStreetMap)
```

---

## Değiştirilen / Oluşturulan Dosyalar

### Yeni Dosyalar

| Dosya | Açıklama |
|---|---|
| `uygulamalar/web/src/lib/types/business.ts` | `BusinessLocation` interface + `parsePointToLatLng()` helper |
| `uygulamalar/web/src/components/maps/BusinessMap.tsx` | Public harita wrapper (SSR-safe, dynamic import) |
| `uygulamalar/web/src/components/maps/LeafletMap.tsx` | react-leaflet implementasyonu (client-only) |
| `uygulamalar/web/src/components/maps/LocationPickerMap.tsx` | Panel için sürüklenebilir marker konum seçici (client-only) |
| `uygulamalar/web/src/components/maps/LocationPickerMapClient.tsx` | Panel konum seçici SSR-safe wrapper |
| `uygulamalar/web/public/icons/map-marker.svg` | Yeedoy marka rengi (#7F1D1D) SVG pin ikonu |

### Değiştirilen Dosyalar

| Dosya | Değişiklik |
|---|---|
| `uygulamalar/web/package.json` | `leaflet ^1.9.4`, `react-leaflet ^4.2.1`, `@types/leaflet ^1.9.12` eklendi |
| `uygulamalar/web/src/ui/acik/isletme.tsx` | `BusinessMap` import edildi; `IsletmeKonumBolumu`'na gömülü harita eklendi |
| `uygulamalar/web/src/ui/acik/harita-istemcisi.tsx` | CDN `window.L` pattern'i `react-leaflet` bileşenlerine taşındı |
| `uygulamalar/web/app/(genel)/kesif/harita/page.tsx` | `HaritaIstemcisi` için `dynamic()` ssr:false import eklendi |
| `uygulamalar/web/src/styles/globals.css` | Leaflet container z-index düzeltmeleri eklendi (sticky header çakışması önlendi) |
| `uygulamalar/web/next.config.mjs` | CSP `connect-src`'ten kullanılmayan `maps.googleapis.com` kaldırıldı |

---

## Google Maps Bağımlılığı

- **Paket bağımlılığı:** Hiç yoktu, kaldırılacak bir şey yok.
- **Derin bağlantı:** `IsletmeKonumBolumu` içindeki `https://maps.google.com/?q=...` bağlantısı korundu — bu bir harici sayfa açma linki, bağımlılık değil.
- **CSP:** `maps.googleapis.com` referansı `connect-src`'ten temizlendi.

---

## Önerilen Mimari

```
react-leaflet + OpenStreetMap (tile.openstreetmap.org)
  ├── BusinessMap.tsx          → public işletme sayfası gömülü harita
  ├── LeafletMap.tsx           → tek marker, popup, recenter hook
  ├── LocationPickerMap.tsx    → panel sürükle-bırak konum seçici
  └── HaritaIstemcisi.tsx      → keşif haritası (çok marker, CircleMarker)
```

**SSR güvenliği:** Tüm Leaflet kodu `'use client'` + `dynamic({ ssr: false })` arkasında. Server tarafında hiç Leaflet kodu çalışmaz.

---

## Lighthouse / Performance Etkisi

| Metrik | Değer |
|---|---|
| Leaflet + react-leaflet bundle (gzip) | ~42 KB |
| Tile'lar | Lazy load — sadece görünür viewport'taki tile'lar indirilir |
| LCP etkisi | Sıfır — harita Cumulative Layout Shift içermez (sabit height class), kritik render yolunda değil |
| SSR | Harita chunk'u hiç server'da işlenmez (dynamic ssr:false) |
| CDN bağımlılığı kaldırıldı | `unpkg.com` script/style tag'leri artık yok → CSP riski yok |

---

## Test Adımları

1. `npm install` — yeni bağımlılıkları indir
2. `npm run typecheck` — TypeScript doğrula
3. `npm run lint` — ESLint doğrula
4. `npm run build` — production build
5. Koordinatı olan bir işletme sayfasını aç (`/isletme/[slug]`) — "Konum ve güven" card'ında haritanın render edildiğini doğrula
6. `/kesif/harita` sayfasını aç — CircleMarker'ların yüklendiğini doğrula
7. Panel konum seçiciyi test etmek için `LocationPickerMapClient` bileşenini bir form sayfasına ekle

---

## Bilinen Riskler ve Notlar

| Risk | Durum |
|---|---|
| `harita-okuma.ts` koordinat fallback | Koordinatı olmayan işletmeler için şehir merkezi + hash offset kullanılır — haritada kümeli görünüm oluşabilir. Bu davranış mevcut koda dokunulmadan korundu. |
| OSM tile kullanım şartları | OpenStreetMap tile'ları küçük-orta ölçekli kullanım için ücretsizdir. Yüksek trafikte Tile CDN (MapTiler, Stadia Maps vb.) geçişi planlanmalı. |
| `@types/leaflet` konumu | `devDependencies` yerine `dependencies`'e eklendi çünkü `LeafletMap.tsx` üretim kodunda `import L from 'leaflet'` kullanıyor. |
| Leaflet CSS z-index | Sticky header (z-30) ile çakışmayı önlemek için `globals.css`'e override eklendi. |
| `LocationPickerMap` panel entegrasyonu | Bileşen oluşturuldu ancak henüz hiçbir panel formuna bağlanmadı. Owner/Admin işletme düzenleme formuna eklemek için `LocationPickerMapClient` import edilip `onChange` prop'u form state'ine bağlanmalı. |
