import { Protocol } from 'pmtiles';
import { addProtocol, setWorkerUrl, type StyleSpecification } from 'maplibre-gl';
import { layers, LIGHT, type Flavor } from '@protomaps/basemaps';
import { clusterSizeTier, type ClusterSizeTier } from '@/src/lib/harita-cluster';

// Protomaps'in nötr 'light' paletinin sıcak, krem tonlu bir varyantı — Google Maps'in
// gri-mavi taban haritasından ayrışmak ve marka renklerimizle (bkz. tokens.css
// --yd-color-card-alt/--yd-color-primary-soft) hizalanmak için. Etiket/sınır/POI
// renkleri LIGHT'tan devralınıyor, sadece zemin/yol/bina/su tonları değişti.
const YEEDOY_FLAVOR: Flavor = {
  ...LIGHT,
  background: '#f6efe4',
  earth: '#f6efe4',
  buildings: '#ece1cf',
  water: '#c9dadd',
  park_a: '#dde7d3',
  park_b: '#cfdcc4',
  wood_a: '#d3e0c8',
  wood_b: '#c6d6ba',
  scrub_a: '#e6dfc7',
  scrub_b: '#dad2b5',
  pedestrian: '#f1e8d8',
  sand: '#efe0bf',
  beach: '#f0e2c4',
  major: '#fffbf3',
  major_casing_early: '#e7d8bf',
  major_casing_late: '#e7d8bf',
  highway: '#ffffff',
  highway_casing_early: '#eec39f',
  highway_casing_late: '#eec39f',
  minor_a: '#fdf8ee',
  minor_b: '#fdf8ee',
  minor_casing: '#e7dac2',
  link: '#fdf8ee',
  link_casing: '#e7dac2',
  minor_service: '#fdf8ee',
  minor_service_casing: '#e7dac2',
};

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
  const geomLayers = layers('protomaps', YEEDOY_FLAVOR);
  // lang:'tr' → name:tr etiketi varsa onu, yoksa yerel OSM adını (Türkiye'de zaten
  // çoğunlukla Türkçe) kullanır; script otomatik 'Latin' (dil-script eşleşme tablosu).
  const labelLayers = (
    layers('protomaps', YEEDOY_FLAVOR, { lang: 'tr', labelsOnly: true }) as StyleSpecification['layers']
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
export function buildRichMarkerEl(
  name: string,
  logoUrl?: string | null,
  opts?: { isVerified?: boolean; avgRating?: number | null; isOpenNow?: boolean | null },
): HTMLDivElement {
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
    opts?.isVerified
      ? 'box-shadow:0 0 0 3px rgba(220,38,38,0.22),0 3px 9px rgba(0,0,0,0.28)'
      : 'box-shadow:0 2px 8px rgba(0,0,0,0.28)',
    'overflow:hidden', 'background:#7F1D1D',
    'display:flex', 'align-items:center', 'justify-content:center',
    'flex-shrink:0', 'position:relative',
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

  if (opts?.avgRating != null && opts.avgRating > 0) {
    const ratingBadge = document.createElement('div');
    ratingBadge.textContent = opts.avgRating.toFixed(1);
    ratingBadge.style.cssText = [
      'position:absolute', 'bottom:-4px', 'right:-4px',
      'background:white', 'color:#111',
      'border-radius:999px', 'padding:1px 5px',
      'font-size:9px', 'font-weight:800',
      'font-family:system-ui,sans-serif',
      'box-shadow:0 1px 4px rgba(0,0,0,0.25)',
      'border:1.5px solid #fbbf24',
    ].join(';');
    pin.appendChild(ratingBadge);
  }

  if (opts?.isOpenNow != null) {
    const statusDot = document.createElement('div');
    statusDot.style.cssText = [
      'position:absolute', 'bottom:-2px', 'left:-2px',
      'width:11px', 'height:11px', 'border-radius:50%',
      `background:${opts.isOpenNow ? '#15803d' : '#9aa4af'}`,
      'border:2px solid white',
    ].join(';');
    pin.appendChild(statusDot);
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
    'background:linear-gradient(135deg,#7F1D1D,#DC2626)',
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
