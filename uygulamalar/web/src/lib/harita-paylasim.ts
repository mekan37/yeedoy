import { Protocol } from 'pmtiles';
import { addProtocol, setWorkerUrl, type StyleSpecification } from 'maplibre-gl';
import { layers, namedFlavor } from '@protomaps/basemaps';
import { clusterSizeTier, type ClusterSizeTier } from '@/src/lib/harita-cluster';

const PMTILES_URL =
  process.env.NEXT_PUBLIC_YEEDOY_PMTILES_URL ??
  'https://maps.yeedoy.com/turkiye.pmtiles';

// maplibre-gl v6 module worker'ının src'ini `import.meta.url`'e göre relative
// hesaplıyor (bkz. maplibre-gl.mjs içindeki fi()); Turbopack bundle'ında bu
// chunk-relative path gerçekte var olmayan bir dosyaya (veya boş string'e)
// çözülüyor, worker sessizce hiç yüklenmiyor ve harita sonsuza dek boş kalıyor
// (network'te tek bir tile isteği bile atılmıyor, konsolda hata da yok).
// Sprite'lardaki gibi worker dosyasını self-hosted servis ederek kesin path veriyoruz.
// maplibre-gl-worker.mjs kendi başına çalışmıyor, aynı klasördeki
// maplibre-gl-shared.mjs'i relative import ediyor — o da kopyalanmalı, yoksa
// worker script'i 404 alıp yine sessizce hiç yüklenmeden ölüyor.
// public/map-assets/{maplibre-gl-worker,maplibre-gl-shared}.mjs,
// node_modules/maplibre-gl/dist/ ile aynı sürüme (v6.0.0) pinli — maplibre-gl
// güncellenince ikisi birden yeniden kopyalanmalı.
const WORKER_URL = '/map-assets/maplibre-gl-worker.mjs';

let _registered = false;

export function ensurePmtilesProtocol(): void {
  if (typeof window === 'undefined' || _registered) return;
  setWorkerUrl(new URL(WORKER_URL, window.location.origin).href);
  const protocol = new Protocol();
  addProtocol('pmtiles', protocol.tile as Parameters<typeof addProtocol>[1]);
  _registered = true;
}

// Sprite'lar public/map-assets/ altında self-hosted (CDN bağımlılığı yok).
// Glyph'ler jsDelivr npm CDN — GitHub CDN'den daha stabil, sürüm sabitlenmiş.
const GLYPHS_CDN = 'https://cdn.jsdelivr.net/gh/protomaps/basemaps-assets@main/fonts';

// @protomaps/basemaps v5'te geometry ve label katmanları tek layers() fonksiyonundan
// options.labelsOnly ile ayrı ayrı üretiliyor (protomaps-themes-base v4'ün ayrı
// layers()/labels() fonksiyonlarının yerini aldı — bkz. CHANGELOG migration guide).
// 'pois' katmanı filtre edilip gereksiz OSM işletme/transit ikonları gizleniyor.
const POI_LABEL_IDS = new Set(['pois']);

export function buildPmtilesStyle(): StyleSpecification {
  const geomLayers = layers('protomaps', namedFlavor('light'));
  // lang:'tr' → name:tr etiketi varsa onu, yoksa yerel OSM adını (Türkiye'de zaten
  // çoğunlukla Türkçe) kullanır; script otomatik 'Latin' (dil-script eşleşme tablosu).
  const labelLayers = (
    layers('protomaps', namedFlavor('light'), { lang: 'tr', labelsOnly: true }) as StyleSpecification['layers']
  ).filter((l) => !POI_LABEL_IDS.has(l.id));
  return {
    version: 8,
    glyphs: `${GLYPHS_CDN}/{fontstack}/{range}.pbf`,
    sprite: `${typeof window !== 'undefined' ? window.location.origin : ''}/map-assets/sprites/v4/light`,
    sources: {
      protomaps: {
        type: 'vector',
        url: `pmtiles://${PMTILES_URL}`,
        attribution: '© OpenStreetMap',
      },
    },
    layers: [...geomLayers, ...labelLayers] as StyleSpecification['layers'],
  };
}

/** İşletme adı etiketi + logo/harf daire pin — harita sayfasıyla aynı stil */
export function buildRichMarkerEl(name: string, logoUrl?: string | null): HTMLDivElement {
  const wrap = document.createElement('div');
  wrap.dataset.testid = 'harita-pin';
  wrap.style.cssText = 'display:flex;flex-direction:column;align-items:center;cursor:pointer;';

  const label = document.createElement('div');
  label.textContent = name;
  label.style.cssText = [
    'background:rgba(255,255,255,0.97)',
    'border:1px solid rgba(0,0,0,0.08)',
    'border-radius:5px',
    'padding:2px 7px',
    'font-size:10px',
    'font-weight:700',
    'color:#111',
    'white-space:nowrap',
    'max-width:130px',
    'overflow:hidden',
    'text-overflow:ellipsis',
    'box-shadow:0 1px 4px rgba(0,0,0,0.18)',
    'margin-bottom:4px',
    'font-family:system-ui,sans-serif',
    'line-height:1.5',
    'pointer-events:none',
  ].join(';');

  const pin = document.createElement('div');
  pin.style.cssText = [
    'width:40px', 'height:40px', 'border-radius:50%',
    'border:2.5px solid white',
    'box-shadow:0 2px 8px rgba(0,0,0,0.28)',
    'overflow:hidden', 'background:#7F1D1D',
    'display:flex', 'align-items:center', 'justify-content:center',
    'flex-shrink:0',
  ].join(';');

  if (logoUrl) {
    const img = document.createElement('img');
    img.src = logoUrl;
    img.alt = '';
    img.style.cssText = 'width:100%;height:100%;object-fit:cover;';
    img.onerror = () => {
      img.remove();
      pin.appendChild(_initialSpan(name));
    };
    pin.appendChild(img);
  } else {
    pin.appendChild(_initialSpan(name));
  }

  wrap.appendChild(label);
  wrap.appendChild(pin);
  return wrap;
}

function _initialSpan(name: string): HTMLSpanElement {
  const s = document.createElement('span');
  s.textContent = (name.charAt(0) || '?').toUpperCase();
  s.style.cssText = 'color:white;font-size:17px;font-weight:800;font-family:system-ui,sans-serif;';
  return s;
}

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
