# Keşif Haritası Pin Clustering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/kesif/harita` sayfasında yoğun bölgelerde üst üste binen işletme pin'lerini, tıklayınca yakınlaştıran sayı balonu kümelerine (cluster) dönüştürmek — tekil pinlerin mevcut zengin (logo + isim) görünümüne dokunmadan.

**Architecture:** `supercluster` kütüphanesiyle client-side clustering. İşletme verisi her API fetch'inde bir `Supercluster` index'ine yüklenir; harita `move` event'inde (throttle'lı) ve yeni veri geldiğinde `getClusters(bbox, zoom)` çağrılıp DOM marker'ları (mevcut `maplibregl.Marker` + custom HTML element deseni) yeniden çizilir. Kümeler tıklanınca `getClusterExpansionZoom` ile hesaplanan zoom'a `flyTo` yapılır.

**Tech Stack:** Next.js 15 App Router, maplibre-gl v6, `supercluster` (yeni bağımlılık), vitest (jsdom), Playwright.

**Spec:** `docs/superpowers/specs/2026-08-01-harita-pin-clustering-design.md`

---

### Task 1: `supercluster` bağımlılığını ekle

**Files:**
- Modify: `uygulamalar/web/package.json`

- [ ] **Step 1: Bağımlılıkları kur**

Run (proje kökü değil, `uygulamalar/web` içinden):

```bash
cd uygulamalar/web
pnpm add supercluster@^7.1.5
pnpm add -D @types/supercluster@^7.1.3
```

Expected: `package.json`'da `dependencies.supercluster` ve `devDependencies["@types/supercluster"]` eklenmiş, kök `pnpm-lock.yaml` güncellenmiş olarak çıkar.

- [ ] **Step 2: Kurulumu doğrula**

Run: `node -e "console.log(require('supercluster/package.json').version)"`
Expected: `7.1.5` (veya `^7.1.5` aralığında çözülen bir sürüm) yazdırır.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/package.json pnpm-lock.yaml
git commit -m "chore(web): supercluster + @types/supercluster bağımlılığı ekle"
```

---

### Task 2: `harita-cluster.ts` — saf yardımcı fonksiyonlar (TDD)

**Files:**
- Create: `uygulamalar/web/src/lib/harita-cluster.ts`
- Test: `uygulamalar/web/test/lib/harita-cluster.test.ts`

- [ ] **Step 1: Başarısız olacak testi yaz**

Create `uygulamalar/web/test/lib/harita-cluster.test.ts`:

```typescript
import { describe, expect, it } from 'vitest';
import { clusterSizeTier, toGeoJSONPoints } from '@/src/lib/harita-cluster';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

const isletme = (overrides: Partial<HaritaIsletme> = {}): HaritaIsletme => ({
  id: 'id-1',
  name: 'Test İşletme',
  slug: 'test-isletme',
  category: 'Kafe',
  lat: 39.9,
  lng: 32.8,
  avg_rating: 4.5,
  logo_url: null,
  cover_url: null,
  is_verified: false,
  ...overrides,
});

describe('harita-cluster', () => {
  describe('toGeoJSONPoints', () => {
    it('converts businesses into GeoJSON point features with lng/lat coordinates', () => {
      const businesses = [isletme({ id: 'a', lat: 39.9, lng: 32.8 })];
      const points = toGeoJSONPoints(businesses);

      expect(points).toHaveLength(1);
      expect(points[0].type).toBe('Feature');
      expect(points[0].geometry).toEqual({ type: 'Point', coordinates: [32.8, 39.9] });
      expect(points[0].properties).toEqual(businesses[0]);
    });

    it('returns an empty array for an empty input', () => {
      expect(toGeoJSONPoints([])).toEqual([]);
    });
  });

  describe('clusterSizeTier', () => {
    it('returns sm for counts under 10', () => {
      expect(clusterSizeTier(1)).toBe('sm');
      expect(clusterSizeTier(9)).toBe('sm');
    });

    it('returns md for counts between 10 and 49', () => {
      expect(clusterSizeTier(10)).toBe('md');
      expect(clusterSizeTier(49)).toBe('md');
    });

    it('returns lg for counts 50 and above', () => {
      expect(clusterSizeTier(50)).toBe('lg');
      expect(clusterSizeTier(1000)).toBe('lg');
    });
  });
});
```

- [ ] **Step 2: Testin başarısız olduğunu doğrula**

Run (proje kökü `uygulamalar/web` içinden): `pnpm run test:unit -- harita-cluster`
Expected: FAIL — `Cannot find module '@/src/lib/harita-cluster'` (dosya henüz yok).

- [ ] **Step 3: Minimal implementasyonu yaz**

Create `uygulamalar/web/src/lib/harita-cluster.ts`:

```typescript
import type Supercluster from 'supercluster';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

export function toGeoJSONPoints(
  businesses: HaritaIsletme[],
): Array<Supercluster.PointFeature<HaritaIsletme>> {
  return businesses.map((b) => ({
    type: 'Feature' as const,
    properties: b,
    geometry: { type: 'Point' as const, coordinates: [b.lng, b.lat] },
  }));
}

export type ClusterSizeTier = 'sm' | 'md' | 'lg';

export function clusterSizeTier(count: number): ClusterSizeTier {
  if (count < 10) return 'sm';
  if (count < 50) return 'md';
  return 'lg';
}
```

- [ ] **Step 4: Testin geçtiğini doğrula**

Run: `pnpm run test:unit -- harita-cluster`
Expected: PASS — 5 test.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/harita-cluster.ts uygulamalar/web/test/lib/harita-cluster.test.ts
git commit -m "feat(web): harita-cluster.ts — GeoJSON dönüşümü ve cluster boyut kademesi yardımcıları"
```

---

### Task 3: `buildClusterBadgeEl` — küme balonu DOM elementi (TDD)

**Files:**
- Modify: `uygulamalar/web/src/lib/harita-paylasim.ts`
- Test: `uygulamalar/web/test/lib/harita-paylasim.test.ts`

- [ ] **Step 1: Başarısız olacak testi yaz**

Create `uygulamalar/web/test/lib/harita-paylasim.test.ts`:

```typescript
import { describe, expect, it } from 'vitest';
import { buildClusterBadgeEl } from '@/src/lib/harita-paylasim';

describe('buildClusterBadgeEl', () => {
  it('renders the count as text content', () => {
    const el = buildClusterBadgeEl(24);
    expect(el.textContent).toBe('24');
  });

  it('tags the element with a stable test id for e2e targeting', () => {
    const el = buildClusterBadgeEl(5);
    expect(el.dataset.testid).toBe('harita-cluster');
  });

  it('sizes large clusters (>=50) bigger than small clusters (<10)', () => {
    const small = buildClusterBadgeEl(3);
    const large = buildClusterBadgeEl(120);
    const smallWidth = parseInt(small.style.width, 10);
    const largeWidth = parseInt(large.style.width, 10);
    expect(largeWidth).toBeGreaterThan(smallWidth);
  });
});
```

- [ ] **Step 2: Testin başarısız olduğunu doğrula**

Run: `pnpm run test:unit -- harita-paylasim`
Expected: FAIL — `buildClusterBadgeEl is not exported` / `undefined is not a function`.

- [ ] **Step 3: Implementasyonu yaz**

Modify `uygulamalar/web/src/lib/harita-paylasim.ts` — import satırına ekle (dosyanın en üstü, satır 1-3):

```typescript
import { Protocol } from 'pmtiles';
import { addProtocol, setWorkerUrl, type StyleSpecification } from 'maplibre-gl';
import { layers, namedFlavor } from '@protomaps/basemaps';
import { clusterSizeTier, type ClusterSizeTier } from '@/src/lib/harita-cluster';
```

Dosyanın sonuna (`_initialSpan` fonksiyonundan sonra) ekle:

```typescript

const CLUSTER_TIER_SIZE: Record<ClusterSizeTier, number> = { sm: 30, md: 42, lg: 54 };
const CLUSTER_TIER_FONT: Record<ClusterSizeTier, number> = { sm: 11, md: 13, lg: 15 };

/** Kalabalık bölgelerdeki işletmeleri temsil eden sayı balonu — üst üste binen pin'lerin yerini alır */
export function buildClusterBadgeEl(count: number): HTMLDivElement {
  const tier = clusterSizeTier(count);
  const size = CLUSTER_TIER_SIZE[tier];
  const font = CLUSTER_TIER_FONT[tier];

  const el = document.createElement('div');
  el.dataset.testid = 'harita-cluster';
  el.style.cssText = [
    `width:${size}px`,
    `height:${size}px`,
    'border-radius:50%',
    'background:#7F1D1D',
    'color:white',
    'border:2px solid white',
    'box-shadow:0 2px 8px rgba(0,0,0,0.3)',
    'display:flex',
    'align-items:center',
    'justify-content:center',
    `font-size:${font}px`,
    'font-weight:800',
    'font-family:system-ui,sans-serif',
    'cursor:pointer',
  ].join(';');
  el.textContent = String(count);
  return el;
}
```

Ayrıca `buildRichMarkerEl`'in `wrap` elementine (satır ~67-68) test-id ekle, mevcut satırı:

```typescript
  const wrap = document.createElement('div');
  wrap.style.cssText = 'display:flex;flex-direction:column;align-items:center;cursor:pointer;';
```

şununla değiştir:

```typescript
  const wrap = document.createElement('div');
  wrap.dataset.testid = 'harita-pin';
  wrap.style.cssText = 'display:flex;flex-direction:column;align-items:center;cursor:pointer;';
```

- [ ] **Step 4: Testin geçtiğini doğrula**

Run: `pnpm run test:unit -- harita-paylasim`
Expected: PASS — 3 test.

- [ ] **Step 5: typecheck çalıştır**

Run: `pnpm run typecheck`
Expected: Hatasız biter.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/src/lib/harita-paylasim.ts uygulamalar/web/test/lib/harita-paylasim.test.ts
git commit -m "feat(web): buildClusterBadgeEl — küme sayı balonu bileşeni ve test-id'ler"
```

---

### Task 4: Playwright E2E testini yaz (henüz başarısız olmalı)

**Files:**
- Create: `uygulamalar/web/e2e/harita-kesif.spec.ts`

Bu test, mevcut `addMarkers` kodu clustering'siz olduğu için Task 6 tamamlanana kadar **kasıtlı olarak FAIL edecek** — bu, testin gerçekten kümeleme davranışını doğruladığını kanıtlar (red-green TDD, entegrasyon seviyesinde).

- [ ] **Step 1: Testi yaz**

Create `uygulamalar/web/e2e/harita-kesif.spec.ts`:

```typescript
import { expect, test } from '@playwright/test';
import type { HaritaIsletme } from '../src/lib/veri/harita-okuma';

function syntheticBusiness(i: number): HaritaIsletme {
  return {
    id: `synthetic-${i}`,
    name: `Test İşletme ${i}`,
    slug: `test-isletme-${i}`,
    category: 'Kafe',
    lat: 39.925 + i * 0.0005,
    lng: 32.866 + i * 0.0005,
    avg_rating: 4.2,
    logo_url: null,
    cover_url: null,
    is_verified: false,
  };
}

test.describe('Keşif haritası — pin clustering', () => {
  test('yoğun bölgede tekil pin yerine küme balonu gösterir ve tıklayınca yakınlaştırır', async ({ page }) => {
    test.slow();
    const businesses = Array.from({ length: 30 }, (_, i) => syntheticBusiness(i));

    await page.route('**/api/harita-isletmeler*', (route) => route.fulfill({ json: businesses }));

    await page.goto('/kesif/harita');
    await page.waitForSelector('.maplibregl-canvas');

    // moveend tetikleyip mock veriyi çektirmek için zoom kontrolüne tıkla
    await page.click('.maplibregl-ctrl-zoom-in');
    await page.waitForTimeout(1500); // 500ms fetch debounce + network + render

    const clusterBadges = page.locator('[data-testid="harita-cluster"]');
    const richPins = page.locator('[data-testid="harita-pin"]');

    await expect(clusterBadges.first()).toBeVisible();
    const richPinCountBefore = await richPins.count();
    expect(richPinCountBefore).toBeLessThan(businesses.length);

    await clusterBadges.first().click();
    await page.waitForTimeout(1500); // flyTo (500ms) + yeniden render

    const richPinCountAfter = await richPins.count();
    expect(richPinCountAfter).toBeGreaterThan(richPinCountBefore);
  });
});
```

- [ ] **Step 2: Testin başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && npx playwright test e2e/harita-kesif.spec.ts`
Expected: FAIL — `clusterBadges.first()` görünür değil (`[data-testid="harita-cluster"]` hiçbir yerde yok, çünkü mevcut kod hâlâ `addMarkers` kullanıyor).

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/e2e/harita-kesif.spec.ts
git commit -m "test(web): harita clustering için başarısız (red) Playwright testi ekle"
```

---

### Task 5: `harita-istemcisi.tsx` entegrasyonu — clustering'i devreye al

**Files:**
- Modify: `uygulamalar/web/src/ui/acik/harita-istemcisi.tsx`

- [ ] **Step 1: Import satırlarını güncelle**

Dosyanın en üstündeki (satır 1-7) importları:

```typescript
'use client';

import { useEffect, useRef, useCallback, useState, type ChangeEvent } from 'react';
import * as maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle, buildRichMarkerEl } from '@/src/lib/harita-paylasim';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';
```

şununla değiştir:

```typescript
'use client';

import { useEffect, useRef, useCallback, useState, type ChangeEvent } from 'react';
import * as maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import Supercluster from 'supercluster';
import { ensurePmtilesProtocol, buildPmtilesStyle, buildRichMarkerEl, buildClusterBadgeEl } from '@/src/lib/harita-paylasim';
import { toGeoJSONPoints } from '@/src/lib/harita-cluster';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';
```

- [ ] **Step 2: Yeni ref'leri ve `addMarkers`'ın yerine `renderClusters`'ı ekle**

`HaritaIstemcisi` bileşeni içinde (mevcut satır ~490-536), şu bloğu:

```typescript
export function HaritaIstemcisi({ initialBusinesses }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [selected, setSelected] = useState<HaritaIsletme | null>(null);

  // Ref: addMarkers'ı her render'da yeniden oluşturmadan click state'ini günceller
  const onClickRef = useRef((_b: HaritaIsletme) => {});
  useEffect(() => {
    onClickRef.current = (b) => setSelected(b);
  }, []);

  const handleSearchSelect = useCallback((isletme: HaritaIsletme) => {
    setSelected(isletme);
    if (mapRef.current) {
      mapRef.current.flyTo({
        center: [isletme.lng, isletme.lat],
        zoom: 16,
        duration: 1000,
      });
    }
  }, []);

  const clearMarkers = useCallback(() => {
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];
  }, []);

  const addMarkers = useCallback(
    (businesses: HaritaIsletme[]) => {
      if (!mapRef.current) return;
      clearMarkers();
      businesses.slice(0, MAX_MARKERS).forEach((b) => {
        const el = buildRichMarkerEl(b.name, b.logo_url);
        el.addEventListener('click', (e) => {
          e.stopPropagation();
          onClickRef.current(b);
        });
        const marker = new maplibregl.Marker({ element: el, anchor: 'bottom' })
          .setLngLat([b.lng, b.lat])
          .addTo(mapRef.current!);
        markersRef.current.push(marker);
      });
    },
    [clearMarkers],
  );
```

şununla değiştir:

```typescript
export function HaritaIstemcisi({ initialBusinesses }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const clusterRef = useRef<Supercluster<HaritaIsletme> | null>(null);
  const rafRef = useRef<number | null>(null);
  const [selected, setSelected] = useState<HaritaIsletme | null>(null);

  // Ref: renderClusters'ı her render'da yeniden oluşturmadan click state'ini günceller
  const onClickRef = useRef((_b: HaritaIsletme) => {});
  useEffect(() => {
    onClickRef.current = (b) => setSelected(b);
  }, []);

  const handleSearchSelect = useCallback((isletme: HaritaIsletme) => {
    setSelected(isletme);
    if (mapRef.current) {
      mapRef.current.flyTo({
        center: [isletme.lng, isletme.lat],
        zoom: 16,
        duration: 1000,
      });
    }
  }, []);

  const clearMarkers = useCallback(() => {
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];
  }, []);

  const buildClusterIndex = useCallback((businesses: HaritaIsletme[]) => {
    clusterRef.current = new Supercluster<HaritaIsletme>({ radius: 60, maxZoom: 16 }).load(
      toGeoJSONPoints(businesses.slice(0, MAX_MARKERS)),
    );
  }, []);

  const renderClusters = useCallback(() => {
    const map = mapRef.current;
    const index = clusterRef.current;
    if (!map || !index) return;

    clearMarkers();
    const bounds = map.getBounds();
    const bbox: [number, number, number, number] = [
      bounds.getWest(),
      bounds.getSouth(),
      bounds.getEast(),
      bounds.getNorth(),
    ];
    const zoom = Math.floor(map.getZoom());
    const features = index.getClusters(bbox, zoom);

    features.forEach((feature) => {
      const [lng, lat] = feature.geometry.coordinates;

      if ('cluster' in feature.properties && feature.properties.cluster) {
        const clusterId = feature.properties.cluster_id;
        const pointCount = feature.properties.point_count;
        const el = buildClusterBadgeEl(pointCount);
        el.addEventListener('click', (e) => {
          e.stopPropagation();
          const expansionZoom = index.getClusterExpansionZoom(clusterId);
          map.flyTo({ center: [lng, lat], zoom: expansionZoom, duration: 500 });
        });
        const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
          .setLngLat([lng, lat])
          .addTo(map);
        markersRef.current.push(marker);
        return;
      }

      const business = feature.properties as HaritaIsletme;
      const el = buildRichMarkerEl(business.name, business.logo_url);
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        onClickRef.current(business);
      });
      const marker = new maplibregl.Marker({ element: el, anchor: 'bottom' })
        .setLngLat([lng, lat])
        .addTo(map);
      markersRef.current.push(marker);
    });
  }, [clearMarkers]);

  const onMapRender = useCallback(() => {
    if (rafRef.current !== null) return;
    rafRef.current = requestAnimationFrame(() => {
      rafRef.current = null;
      renderClusters();
    });
  }, [renderClusters]);
```

- [ ] **Step 3: `fetchAndUpdate`'i cluster index'i yeniden kuracak şekilde güncelle**

Mevcut (satır ~538-551):

```typescript
  const fetchAndUpdate = useCallback(async () => {
    if (!mapRef.current) return;
    const center = mapRef.current.getCenter();
    try {
      const res = await fetch(
        `/api/harita-isletmeler?lat=${center.lat}&lng=${center.lng}&radius=50`,
      );
      if (!res.ok) return;
      const data: HaritaIsletme[] = await res.json();
      addMarkers(data);
    } catch {
      // sessizce geç
    }
  }, [addMarkers]);
```

şununla değiştir:

```typescript
  const fetchAndUpdate = useCallback(async () => {
    if (!mapRef.current) return;
    const center = mapRef.current.getCenter();
    try {
      const res = await fetch(
        `/api/harita-isletmeler?lat=${center.lat}&lng=${center.lng}&radius=50`,
      );
      if (!res.ok) return;
      const data: HaritaIsletme[] = await res.json();
      buildClusterIndex(data);
      renderClusters();
    } catch {
      // sessizce geç
    }
  }, [buildClusterIndex, renderClusters]);
```

- [ ] **Step 4: Harita init `useEffect`'ini güncelle — ilk yükleme, move listener, cleanup**

Mevcut (satır ~558-609):

```typescript
  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    ensurePmtilesProtocol();

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: buildPmtilesStyle(),
      center: DEFAULT_CENTER,
      zoom: DEFAULT_ZOOM,
      minZoom: 4,
      maxZoom: 18,
    });

    map.addControl(new maplibregl.NavigationControl(), 'top-right');
    map.addControl(
      new maplibregl.GeolocateControl({
        positionOptions: { enableHighAccuracy: true },
        trackUserLocation: false,
      }),
      'top-right',
    );

    map.on('load', () => {
      addMarkers(initialBusinesses);

      if ('geolocation' in navigator) {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            map.flyTo({
              center: [pos.coords.longitude, pos.coords.latitude],
              zoom: 13,
              duration: 1200,
            });
          },
          () => {},
          { timeout: 8000, maximumAge: 300_000 },
        );
      }
    });

    map.on('moveend', onMoveEnd);

    mapRef.current = map;

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      clearMarkers();
      map.remove();
      mapRef.current = null;
    };
  }, [initialBusinesses, addMarkers, onMoveEnd, clearMarkers]);
```

şununla değiştir:

```typescript
  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    ensurePmtilesProtocol();

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: buildPmtilesStyle(),
      center: DEFAULT_CENTER,
      zoom: DEFAULT_ZOOM,
      minZoom: 4,
      maxZoom: 18,
    });

    map.addControl(new maplibregl.NavigationControl(), 'top-right');
    map.addControl(
      new maplibregl.GeolocateControl({
        positionOptions: { enableHighAccuracy: true },
        trackUserLocation: false,
      }),
      'top-right',
    );

    map.on('load', () => {
      buildClusterIndex(initialBusinesses);
      renderClusters();

      if ('geolocation' in navigator) {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            map.flyTo({
              center: [pos.coords.longitude, pos.coords.latitude],
              zoom: 13,
              duration: 1200,
            });
          },
          () => {},
          { timeout: 8000, maximumAge: 300_000 },
        );
      }
    });

    map.on('moveend', onMoveEnd);
    map.on('move', onMapRender);

    mapRef.current = map;

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
      clearMarkers();
      map.remove();
      mapRef.current = null;
    };
  }, [initialBusinesses, buildClusterIndex, renderClusters, onMoveEnd, onMapRender, clearMarkers]);
```

- [ ] **Step 5: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter. (`'cluster' in feature.properties` type guard'ının `Supercluster.ClusterFeature<{}> | Supercluster.PointFeature<HaritaIsletme>` union'ını doğru daralttığını doğrula — TS hata verirse `feature.properties.cluster === true` yerine önce `const props = feature.properties;` değişkenine alıp `if ('cluster' in props && props.cluster)` şeklinde dene.)

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/src/ui/acik/harita-istemcisi.tsx
git commit -m "feat(web): keşif haritasında pin clustering'i devreye al"
```

---

### Task 6: E2E testinin artık geçtiğini doğrula (green)

**Files:** Yok (sadece doğrulama)

- [ ] **Step 1: Playwright testini tekrar çalıştır**

Run: `cd uygulamalar/web && npx playwright test e2e/harita-kesif.spec.ts`
Expected: PASS.

- [ ] **Step 2: Başarısız olursa hata ayıklama ipuçları**

- `clusterBadges.first()` hâlâ görünmüyor → `page.click('.maplibregl-ctrl-zoom-in')`'in gerçekten `moveend` tetiklediğini, `test.slow()`'un yeterli süre verdiğini kontrol et; `page.waitForTimeout(1500)` süresini `2500`'e çıkarmayı dene.
- `richPinCountAfter` artmıyor → `getClusterExpansionZoom` sonrası `flyTo` hedef zoom'unun `maxZoom:16` sınırını gerçekten aştığını (yani senkron veri noktalarının birbirinden ayrıldığını) doğrula; `syntheticBusiness`'daki `0.0005` derece aralığını büyütmeyi dene.

- [ ] **Step 3: Tüm doğrulama paketini çalıştır**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit + build hepsi başarılı.

---

### Task 7: Manuel görsel doğrulama

**Files:** Yok

- [ ] **Step 1: Dev server'ı başlat ve tarayıcıda kontrol et**

Run: `cd uygulamalar/web && pnpm run dev`

Tarayıcıda `http://localhost:3000/kesif/harita` aç, önceki bug raporundaki gibi yoğun bir bölgeye (ör. bir büyükşehir mahallesi) zoom yap. Üst üste binen tekil pin kalmadığını, kalabalık noktalarda sayı balonu göründüğünü, balona tıklayınca yakınlaşıp tekil pinlere ayrıldığını doğrula.

- [ ] **Step 2: Dev server'ı durdur**

`Ctrl+C` ile durdur (veya `pnpm run dev` komutunu çalıştıran arka plan sürecini sonlandır).

---

### Task 8: Production'a deploy ve son doğrulama

**Files:** Yok

- [ ] **Step 1: Production'a deploy et**

Run: `cd uygulamalar/web && vercel deploy --prod --archive=tgz --yes`
Expected: `readyState: READY`, `www.yeedoy.com`'a alias'lanmış deployment URL'i.

- [ ] **Step 2: `www.yeedoy.com/kesif/harita` üzerinde görsel doğrulama**

Kullanıcıdan (veya Playwright ile gerçek prod domain'inde) aynı yoğun bölgede kontrol istenir: kümeleme davranışının canlıda da çalıştığı teyit edilir.
