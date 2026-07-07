# PMTiles Harita Entegrasyonu

> Tarih: 2026-07-07  
> Durum: Production

## Mimari Özet

Yeedoy haritası Cloudflare R2 üzerinde barındırılan PMTiles Türkiye vektör tile arşivini kullanır.
OSM raster tile kullanılmaz.

```
Cloudflare R2 (maps.yeedoy.com)
         │
    turkiye.pmtiles
         │
    ┌────┴────┐
    │         │
  Web       Mobil
(MapLibre) (flutter_map
  GL JS)   + vector_map_tiles)
    │         │
    └────┬────┘
         │
   Supabase nearby_businesses_v2
   (gerçek lat/lng marker'ları)
```

## PMTiles URL

```
https://maps.yeedoy.com/turkiye.pmtiles
```

**Bu URL public'tir, secret/gizli değildir.**  
R2 bucket'ı public read ile yapılandırılmıştır.

## Web Entegrasyonu (Next.js)

### Bağımlılıklar

```bash
npm install maplibre-gl pmtiles protomaps-themes-base
```

### Env Değişkeni

```bash
# .env.local veya deployment environment'ta
NEXT_PUBLIC_YEEDOY_PMTILES_URL=https://maps.yeedoy.com/turkiye.pmtiles
```

### PMTiles Protokol Kaydı

```typescript
import { Protocol } from 'pmtiles';
import maplibregl from 'maplibre-gl';

const protocol = new Protocol();
maplibregl.addProtocol('pmtiles', protocol.tile as maplibregl.AddProtocolAction);
```

### Map Style

```typescript
const style: maplibregl.StyleSpecification = {
  version: 8,
  sources: {
    protomaps: {
      type: 'vector',
      url: `pmtiles://${PMTILES_URL}`,
    },
  },
  layers: layers('protomaps', 'light'), // protomaps-themes-base
};
```

### İlgili Dosyalar

| Dosya | Rol |
|-------|-----|
| `src/ui/acik/harita-istemcisi.tsx` | Ana MapLibre client component |
| `src/lib/veri/harita-okuma.ts` | Marker veri katmanı |
| `app/(genel)/kesif/harita/page.tsx` | Server component, SSR veri |
| `app/api/harita-isletmeler/route.ts` | Viewport tabanlı marker API |

## Mobil Entegrasyonu (Flutter)

### Bağımlılıklar

```yaml
# pubspec.yaml
flutter_map: ^7.0.2      # mevcut
vector_map_tiles: ^8.x.x
vector_map_tiles_pmtiles: ^8.x.x
```

### Env Değişkeni

```bash
# .env dosyası (flutter_dotenv)
YEEDOY_PMTILES_URL=https://maps.yeedoy.com/turkiye.pmtiles
```

### Kullanım

```dart
final pmtilesUrl = dotenv.env['YEEDOY_PMTILES_URL'] 
    ?? 'https://maps.yeedoy.com/turkiye.pmtiles';

VectorTileLayer(
  tileProviders: TileProviders({'protomaps': PmTilesVectorTileProvider(url: pmtilesUrl)}),
  maximumCachedTiles: 200, // S7 bellek optimizasyonu
)
```

### İlgili Dosyalar

| Dosya | Rol |
|-------|-----|
| `lib/features/discovery/ui/surfaces/discovery_map_page.dart` | Ana harita sayfası |
| `lib/features/discovery/ui/surfaces/discovery_map_surface.dart` | Mini harita |

## Supabase Marker Veri Akışı

Harita marker'ları sadece gerçek `lat`/`lng` koordinatı olan işletmelerden oluşur.  
Sahte/fallback koordinat kullanılmaz.

### Kullanılan RPC

```sql
nearby_businesses_v2(
  p_lat       double precision,
  p_lng       double precision,
  p_radius_m  integer,   -- metre cinsinden radius
  p_limit     integer    -- max 150-200 marker
)
-- Döner: id, name, slug, public_slug, category, lat, lng, avg_rating, logo_url, is_verified
-- GRANT: anon, authenticated, service_role
```

### Veri Akışı

```
Kullanıcı haritayı sürükler
        ↓ (500ms debounce)
nearby_businesses_v2(center_lat, center_lng, radius=50km)
        ↓
lat/lng null olan işletmeler filtrelenir
        ↓
max 150 marker render edilir
```

## R2 / CDN Notları

### CORS

PMTiles range request için R2 bucket'ında CORS ayarı gerekmektedir:

```json
[
  {
    "AllowedOrigins": ["https://yeedoy.com", "https://*.yeedoy.com"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["Range"],
    "ExposeHeaders": ["Content-Range", "Content-Length", "Accept-Ranges"],
    "MaxAgeSeconds": 86400
  }
]
```

### Range Request

PMTiles formatı HTTP Range request kullanır. R2 range request'i native destekler.  
CDN (Cloudflare) cache davranışı: Range request'ler default olarak cache'lenir.

### Cache Headers

```
Cache-Control: public, max-age=86400
```

## Local Test Adımları

### Web

```bash
cd uygulamalar/web
cp .env.example .env.local
# .env.local içinde NEXT_PUBLIC_YEEDOY_PMTILES_URL zaten default URL ile dolu
npm run dev
# http://localhost:3000/kesif/harita
```

### Mobil

```bash
cd uygulamalar/mobil
# .env içinde YEEDOY_PMTILES_URL ekli
flutter run -d <device>
# Keşif → Harita sekmesi
```

### PMTiles URL Test

```bash
# Range request testi
curl -I -H "Range: bytes=0-127" https://maps.yeedoy.com/turkiye.pmtiles
# 206 Partial Content dönmeli
```

## Rollback Planı

### Web Rollback

1. `maplibre-gl`, `pmtiles`, `protomaps-themes-base` paketlerini kaldır
2. `leaflet`, `react-leaflet` paketlerini yeniden kur
3. `harita-istemcisi.tsx` ve `harita-okuma.ts` dosyalarını git'ten restore et

### Mobil Rollback (S7 Performans Sorunu)

Eğer `vector_map_tiles` S7'de performans sorunu çıkarırsa:

**Aşama 2 Fallback — Cloudflare Worker XYZ Proxy:**

```
Cloudflare Worker → PMTiles → XYZ raster tile
URL: https://tiles.yeedoy.com/{z}/{x}/{y}.png
```

Flutter'da:
```dart
TileLayer(
  urlTemplate: 'https://tiles.yeedoy.com/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.yeedoy.app',
)
```

Bu yaklaşım S7'de raster tile render kullanır, daha az GPU kullanımı sağlar.

## Koordinatsız İşletmeler

`lat`/`lng` null olan işletmeler haritada gösterilmez.  
Bu işletmeler liste/arama tarafında görünmeye devam eder.

Geocoding/backfill işi için → `docs/kalan-isler.md`

---

*Not: Leaflet bağımlılığı `src/components/maps/` altındaki `KonumGoruntuleyici`, `LeafletMap`, `LocationPickerMap` bileşenleri için hâlâ gereklidir. Bu bileşenler harita önizlemesi/konum seçici için kullanılmaktadır; PMTiles entegrasyonuna dahil değildir.*
