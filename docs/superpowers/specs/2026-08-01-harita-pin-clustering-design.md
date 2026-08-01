# Keşif Haritası — Pin Clustering Design

## Bağlam

`/kesif/harita` sayfasında (`src/ui/acik/harita-istemcisi.tsx`) `addMarkers()` her işletme için ayrı, zengin bir DOM marker'ı (logo/harf + isim etiketi, `buildRichMarkerEl`) basıyor — `MAX_MARKERS = 150`'ye kadar. Yoğun bölgelerde (örn. Ankara/Yenimahalle gibi bir mahalle zoom'unda) onlarca pin aynı ekran alanında üst üste biniyor, isim etiketleri okunamaz hale geliyor. Bu, üzerinde çalışılan [[project_pmtiles_map_worker_fix]] harita zemin bug'ından tamamen bağımsız, ayrı bir UX sorunu.

Görsel karşılaştırma (brainstorming companion, 2026-08-01) sonucunda kullanıcı **Seçenek A**'yı onayladı: tekil pinler mevcut zengin tasarımı (logo + isim etiketi) korur, sadece kalabalık noktalar sayı balonuna (cluster) dönüşür — Google Haritalar'daki gibi tüm pinleri sade noktaya indirgeyen Seçenek B reddedildi.

## Kapsam

Sadece `src/ui/acik/harita-istemcisi.tsx` ve `src/lib/harita-paylasim.ts`. Projedeki diğer 3 harita bileşeni (`LocationPickerMap`, `KonumGoruntuleyici`, `OsmHarita`) tek bir konum/pin gösteriyor — kalabalık sorunu onlarda yok, dokunulmayacak.

## Yaklaşım

**Kütüphane:** `supercluster` (npm) — Mapbox ekosisteminin standart client-side clustering algoritması, ~5KB, sıfır ek network bağımlılığı. `uygulamalar/web/package.json`'a `dependencies` altına eklenecek.

### Veri akışı

1. `fetchAndUpdate()` (mevcut, `moveend`'de `FETCH_DEBOUNCE_MS=500` debounce'lu) `/api/harita-isletmeler`'den işletmeleri çeker — **değişmiyor**.
2. Yeni: gelen `HaritaIsletme[]` bir `Supercluster` index'ine yüklenir (`clusterRef.current = new Supercluster({radius: 60, maxZoom: 16}).load(toGeoJSONPoints(data))`). `radius: 60` (piksel) ve `maxZoom: 16`, `MAX_MARKERS`/mevcut `maxZoom: 18` harita ayarıyla tutarlı başlangıç değerleri — ince ayar gerekirse görsel testte revize edilir.
3. Yeni `renderClusters()` fonksiyonu: `clusterRef.current.getClusters([west, south, east, north], Math.floor(map.getZoom()))` çağırır, dönen `cluster`/`point` feature'larını mevcut `markersRef` listesiyle diff'leyip DOM marker'larını günceller (tam `clearMarkers()`+yeniden oluşturmak yerine, gereksiz DOM churn'ü önlemek için sadece değişenleri güncellemek tercih edilir; ilk implementasyonda basitlik için tam yeniden oluşturma da kabul edilebilir, performans sorunu çıkarsa diff'e geçilir).
4. `renderClusters()` iki yerden tetiklenir:
   - `fetchAndUpdate()` sonunda (yeni veri geldiğinde)
   - Harita `zoom`/`move` event'inde, `requestAnimationFrame` ile throttle'lı (ayrı API çağrısı gerektirmez — küme grupları zoom'a bağlı olduğu için mevcut veri setiyle yeniden hesaplanır)

### Marker render mantığı

`addMarkers()` yerine `renderClusters()` çağrılır; her feature için:

- **Küme** (`properties.cluster === true`): yeni `buildClusterBadgeEl(count)` — kırmızı (`#7F1D1D`) yuvarlak balon, sayıya göre 3 boyut tiers (`sm <10` 30px, `md 10-49` 42px, `lg 50+` 54px), ortasında `point_count_abbreviated`. Tıklanınca `clusterRef.current.getClusterExpansionZoom(id)` ile hesaplanan zoom'a `map.flyTo({center: [lng, lat], zoom: expansionZoom, duration: 500})`.
- **Tekil işletme**: **değişmeden** mevcut `buildRichMarkerEl` + click → `IsletmePaneli` açma davranışı.

### Yeni yardımcı — `harita-paylasim.ts`

`buildClusterBadgeEl(count: number): HTMLDivElement` — `buildRichMarkerEl`'in yanına eklenir, aynı dosya deseni (inline style, `cssText`).

## Test planı

- `pnpm run typecheck` + `pnpm run lint`.
- Playwright ile aynı yoğun bölge senaryosu (bu spec'in tetikleyicisi olan ekran görüntüsündeki Ankara/Yenimahalle yoğunluğuna benzer sentetik veri veya gerçek bölgeye `flyTo`): üst üste binen pin kalmadığını, küme sayılarının API'den dönen toplam işletme sayısıyla tutarlı olduğunu, küme tıklamasının zoom-in yaptığını ve tam zoom'da (`maxZoom: 16` üstü) tekil pinlerin göründüğünü doğrula.
- Manuel: gerçek tarayıcıda `/kesif/harita` üzerinde pan/zoom ile küme davranışının akıcı olduğunu (jank yok) kontrol et.

## Kapsam dışı

- Diğer 3 harita bileşeninde clustering (ihtiyaç yok, tek pin gösteriyorlar).
- `MAX_MARKERS=150` API-tarafı limitinin değiştirilmesi (clustering client-side olduğu için mevcut limitle çalışır; ihtiyaç çıkarsa ayrı bir iş).
- Cluster tıklamasında liste/panel açma (kullanıcı zoom-in'i seçti, bu spec'te yok).
