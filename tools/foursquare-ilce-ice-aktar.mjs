/**
 * foursquare-ilce-ice-aktar.mjs
 *
 * ilce-koordinatlari.json'daki her ilçe için Foursquare Places API v3'ten
 * yemek/içecek mekanlarını çeker ve Supabase'e aktarır.
 *
 * OSM ile tamamlayıcı çalışır: OSM'de veri olmayan ilçeleri kapatır.
 * Mevcut kayıtlar source,source_id üzerinden güncellenir (upsert).
 *
 * Kullanım:
 *   node tools/foursquare-ilce-ice-aktar.mjs
 *   node tools/foursquare-ilce-ice-aktar.mjs --photos
 *   PHOTOS_PER_RUN=100 node tools/foursquare-ilce-ice-aktar.mjs --photos
 *   DISTRICTS_PER_RUN=30 node tools/foursquare-ilce-ice-aktar.mjs
 *   node tools/foursquare-ilce-ice-aktar.mjs --reset
 *
 * .env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FOURSQUARE_API_KEY
 */

import 'dotenv/config';
import fs from 'fs';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

// ── Config ────────────────────────────────────────────────────────────────────

const SUPABASE_URL             = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const FSQ_API_KEY              = process.env.FOURSQUARE_API_KEY;

const ILCE_JSON         = process.env.ILCE_JSON || './veri_json/ilce-koordinatlari.json';
const PROGRESS_FILE     = './veri_json/.foursquare-ilce-progress.json';
const DISTRICTS_PER_RUN = parseInt(process.env.DISTRICTS_PER_RUN || '25', 10);
const PHOTOS_PER_RUN    = parseInt(process.env.PHOTOS_PER_RUN    || '50', 10);
const PHOTOS_PER_PLACE  = parseInt(process.env.PHOTOS_PER_PLACE  || '5', 10);
const REQUEST_DELAY_MS  = parseInt(process.env.REQUEST_DELAY_MS  || '1200', 10);
const LIMIT_PER_QUERY   = 50;   // FSQ v3 max
const FSQ_MAX_RADIUS    = 100000;

// Foursquare yeni API'de kategori ID'leri BSON formatına değişti.
// Sunucu tarafı filtreleme yerine tüm yerleri çekip istemci tarafında filtrele.

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY eksik');
  process.exit(1);
}
if (!FSQ_API_KEY) {
  console.error('❌ FOURSQUARE_API_KEY eksik');
  console.error('   .env dosyasına ekleyin: FOURSQUARE_API_KEY=fsq3...');
  console.error('   https://location.foursquare.com/developer → Projects → API Keys → Service API Key');
  process.exit(1);
}

console.log(`🔑 FSQ API Key: ${FSQ_API_KEY.slice(0, 8)}... (v3 Places API)`);

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const resetFlag = process.argv.includes('--reset');
const diagnoseFlag = process.argv.includes('--diagnose');
const photosFlag = process.argv.includes('--photos');

// ── Kategori eşleme ───────────────────────────────────────────────────────────

function getFsqCategory(categories = []) {
  // Önce yemek/içecek yeri mi diye kontrol et
  // Icon URL'de /food/ veya /nightlife/ varsa → yemek/içecek yeri
  const isFoodOrDrink = categories.some(c => {
    const icon = c.icon?.prefix ?? '';
    return icon.includes('/food/') || icon.includes('/nightlife/') ||
           icon.includes('/coffee/') || icon.includes('/drinks/');
  });
  if (!isFoodOrDrink) return null; // Müze, otel, alışveriş vb. → atla

  for (const cat of categories) {
    const name = (cat.name ?? '').toLowerCase();
    if (/bar|pub|lounge|nightclub|tavern|meyhane|birahane|gece/i.test(name)) return 'Mekan';
    if (/ice cream|frozen yogurt|dessert|patisserie|dondurma|tatlı|baklava|pastane/i.test(name)) return 'Tatlıcı';
    if (/breakfast|brunch|kahvaltı/i.test(name)) return 'Kahvaltı';
    if (/seafood|fish|balık|steakhouse|steak|kebab|bbq|barbecue|ocakbaşı/i.test(name)) return 'Balık / Et';
    if (/café|cafe|coffee|kahve|tea|çay|nargile/i.test(name)) return 'Kafe';
  }
  return 'Restoran';
}

// ── Yardımcı ──────────────────────────────────────────────────────────────────

function normStr(s) { return (s ?? '').toString().trim(); }

function roundCoord(x, p = 4) {
  const n = Number(x);
  return Number.isFinite(n) ? Math.round(n * 10 ** p) / 10 ** p : null;
}

function makeFingerprint({ name, lat, lng, city, district, category }) {
  const key = [
    normStr(name).toLowerCase().replace(/\s+/g, ' '),
    category ?? '',
    normStr(city).toLowerCase(),
    normStr(district).toLowerCase(),
    String(roundCoord(lat) ?? ''),
    String(roundCoord(lng) ?? ''),
  ].join('|');
  return crypto.createHash('sha1').update(key).digest('hex');
}

function titleCaseTr(s) {
  const TR = { i: 'İ', ı: 'I', ğ: 'Ğ', ü: 'Ü', ş: 'Ş', ö: 'Ö', ç: 'Ç' };
  return normStr(s).split(' ').filter(Boolean)
    .map(w => (TR[w[0]] ?? w[0].toUpperCase()) + w.slice(1).toLowerCase())
    .join(' ');
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// FSQ photos: prefix + WxH + suffix formatı
// Örn: "https://fastly.4sqi.net/img/general/" + "800x600" + "/abc.jpg"
function fsqPhotoUrl(photo, size = '800x600') {
  if (!photo?.prefix || !photo?.suffix) return null;
  return `${photo.prefix}${size}${photo.suffix}`;
}

function businessMediaRowsFromPhotos(businessId, photos) {
  return photos
    .map((photo, index) => ({
      business_id: businessId,
      kind: index === 0 ? 'logo' : 'venue',
      url: fsqPhotoUrl(photo, '800x600'),
      url_large: fsqPhotoUrl(photo, '1200x900'),
      url_thumb: fsqPhotoUrl(photo, '300x300'),
      provider: 'foursquare',
      width: Number.isFinite(photo?.width) ? photo.width : null,
      height: Number.isFinite(photo?.height) ? photo.height : null,
      status: 'approved',
      is_hidden: false,
      is_shadow: false,
    }))
    .filter(row => row.url);
}

function calcRadius(bbox, center) {
  const latKm = (bbox.north - bbox.south) * 111;
  const cosLat = Math.cos((center.lat * Math.PI) / 180);
  const lonKm  = (bbox.east - bbox.west) * 111 * cosLat;
  const radiusKm = Math.sqrt((latKm / 2) ** 2 + (lonKm / 2) ** 2) * 1.2;
  return Math.min(Math.round(radiusKm * 1000), FSQ_MAX_RADIUS);
}

function buildGridCells(bbox, center, radiusM) {
  const CELL_RADIUS_M = 14000;
  if (radiusM <= CELL_RADIUS_M) return [{ lat: center.lat, lon: center.lon }];

  const latKm = (bbox.north - bbox.south) * 111;
  const cosLat = Math.cos((center.lat * Math.PI) / 180);
  const lonKm  = (bbox.east - bbox.west) * 111 * cosLat;
  const nx = Math.min(Math.ceil(lonKm / 28), 3);
  const ny = Math.min(Math.ceil(latKm / 28), 3);

  const cells = [];
  const latStep = (bbox.north - bbox.south) / ny;
  const lonStep = (bbox.east - bbox.west) / nx;

  for (let i = 0; i < ny; i++) {
    for (let j = 0; j < nx; j++) {
      cells.push({
        lat: bbox.south + latStep * (i + 0.5),
        lon: bbox.west  + lonStep * (j + 0.5),
      });
    }
  }
  return cells;
}

// ── Foursquare v3 API ─────────────────────────────────────────────────────────

const FSQ_V3_BASE   = 'https://places-api.foursquare.com/places/search';
const FSQ_PHOTOS_BASE = 'https://places-api.foursquare.com/places';
const FSQ_FIELDS    = 'fsq_place_id,name,latitude,longitude,location,tel,categories,photos';
const FSQ_VERSION_H = '2025-06-17';

// Kota/rate-limit takibi
let consecutiveRateLimits = 0;
const QUOTA_ABORT_THRESHOLD = 3; // 3 ardışık 429 → dur
let burstRemaining = 150; // x-ratelimit-burst-remaining'den güncellenir

class QuotaExhaustedError extends Error {
  constructor(msg, detail = null) {
    super(msg || 'FSQ quota/rate-limit aşıldı');
    this.name = 'QuotaExhaustedError';
    this.detail = detail;
  }
}

function collectRateLimitHeaders(headers) {
  const out = {};
  for (const [key, value] of headers.entries()) {
    if (/rate|limit|quota|retry|remaining|reset|usage|request|trace/i.test(key)) {
      out[key] = value;
    }
  }
  return out;
}

function formatRateLimitDetail(detail) {
  if (!detail) return '';
  const lines = [];
  if (detail.status) lines.push(`   HTTP: ${detail.status}`);
  if (detail.headers && Object.keys(detail.headers).length > 0) {
    lines.push('   Headerlar:');
    for (const [key, value] of Object.entries(detail.headers)) {
      lines.push(`     ${key}: ${value}`);
    }
  }
  if (detail.body) lines.push(`   Yanıt: ${detail.body}`);
  lines.push('   Foursquare Developer Console > Places API Usage ekranında günlük/aylık kullanım ve billing durumunu kontrol edin.');
  return `\n${lines.join('\n')}`;
}

async function fsqFetch(url, headers) {
  // Burst çok azsa bekle
  if (burstRemaining <= 10) {
    const wait = burstRemaining <= 3 ? 30000 : 5000;
    process.stdout.write(`⏳ burst düşük (${burstRemaining}), ${wait/1000}s bekleniyor... `);
    await sleep(wait);
  }

  const res = await fetch(url, { headers, signal: AbortSignal.timeout(20000) });

  // Header'lardan burst remaining'i güncelle
  const br = res.headers.get('x-ratelimit-burst-remaining');
  if (br !== null) burstRemaining = parseInt(br, 10);

  return res;
}

async function fetchFoursquareV3(lat, lon, radiusMeters, limitOverride) {
  const params = new URLSearchParams({
    ll:     `${lat},${lon}`,
    radius: String(radiusMeters),
    limit:  String(limitOverride ?? LIMIT_PER_QUERY),
    fields: FSQ_FIELDS,
    sort:   'DISTANCE',
  });
  const headers = {
    Authorization:          `Bearer ${FSQ_API_KEY}`,
    Accept:                 'application/json',
    'X-Places-Api-Version': FSQ_VERSION_H,
  };

  for (let attempt = 1; attempt <= 3; attempt++) {
    if (consecutiveRateLimits >= QUOTA_ABORT_THRESHOLD) throw new QuotaExhaustedError();

    try {
      const res = await fsqFetch(`${FSQ_V3_BASE}?${params}`, headers);

      if (res.status === 429) {
        consecutiveRateLimits++;
        const body = await res.text().catch(() => '');
        const detail = {
          status: `${res.status} ${res.statusText}`,
          headers: collectRateLimitHeaders(res.headers),
          body: body.slice(0, 500),
        };
        if (consecutiveRateLimits >= QUOTA_ABORT_THRESHOLD) {
          throw new QuotaExhaustedError(
            'FSQ 429 devam ediyor — bu genelde kısa bekleme değil, proje/key kotası veya billing/plan limitidir',
            detail,
          );
        }
        const retryAfter = Number.parseInt(res.headers.get('retry-after') ?? '', 10);
        const wait = Number.isFinite(retryAfter) && retryAfter > 0
          ? retryAfter * 1000
          : attempt * 20000;
        process.stdout.write(`⏳ 429 (${consecutiveRateLimits}/${QUOTA_ABORT_THRESHOLD}), ${Math.round(wait/1000)}s bekleniyor... `);
        if (attempt === 1) {
          process.stdout.write(`\n   429 detay: ${body.slice(0, 220) || 'yanıt gövdesi boş'}\n`);
        }
        await sleep(wait);
        continue;
      }

      if (!res.ok) {
        const body = await res.text().catch(() => '');
        throw new Error(`FSQ ${res.status}: ${body.slice(0, 120)}`);
      }

      consecutiveRateLimits = 0;
      const json = await res.json();
      return json.results ?? [];
    } catch (err) {
      if (err instanceof QuotaExhaustedError) throw err;
      if (attempt === 3) throw err;
      await sleep(5000 * attempt);
    }
  }
  return [];
}

async function fetchFoursquarePhotos(fsqId, limitOverride) {
  const params = new URLSearchParams({
    limit: String(limitOverride ?? PHOTOS_PER_PLACE),
  });
  const headers = {
    Authorization: `Bearer ${FSQ_API_KEY}`,
    Accept: 'application/json',
    'X-Places-Api-Version': FSQ_VERSION_H,
  };
  const safeId = encodeURIComponent(fsqId);

  for (let attempt = 1; attempt <= 3; attempt++) {
    if (consecutiveRateLimits >= QUOTA_ABORT_THRESHOLD) throw new QuotaExhaustedError();

    try {
      const res = await fsqFetch(`${FSQ_PHOTOS_BASE}/${safeId}/photos?${params}`, headers);

      if (res.status === 429) {
        consecutiveRateLimits++;
        const body = await res.text().catch(() => '');
        const detail = {
          status: `${res.status} ${res.statusText}`,
          headers: collectRateLimitHeaders(res.headers),
          body: body.slice(0, 500),
        };
        if (consecutiveRateLimits >= QUOTA_ABORT_THRESHOLD) {
          throw new QuotaExhaustedError(
            'FSQ photos 429 devam ediyor — fotoğraf endpoint kotası veya billing/plan limiti',
            detail,
          );
        }
        const retryAfter = Number.parseInt(res.headers.get('retry-after') ?? '', 10);
        const wait = Number.isFinite(retryAfter) && retryAfter > 0
          ? retryAfter * 1000
          : attempt * 20000;
        process.stdout.write(`⏳ photos 429 (${consecutiveRateLimits}/${QUOTA_ABORT_THRESHOLD}), ${Math.round(wait/1000)}s bekleniyor... `);
        if (attempt === 1) {
          process.stdout.write(`\n   429 detay: ${body.slice(0, 220) || 'yanıt gövdesi boş'}\n`);
        }
        await sleep(wait);
        continue;
      }

      if (!res.ok) {
        const body = await res.text().catch(() => '');
        throw new Error(`FSQ photos ${res.status}: ${body.slice(0, 160)}`);
      }

      consecutiveRateLimits = 0;
      const json = await res.json();
      return Array.isArray(json) ? json : (json.results ?? []);
    } catch (err) {
      if (err instanceof QuotaExhaustedError) throw err;
      if (attempt === 3) throw err;
      await sleep(5000 * attempt);
    }
  }
  return [];
}

async function testFoursquareAuth() {
  try {
    // limit=1 — tek sonuç yeterli, burst harcamayı minimumda tut
    const results = await fetchFoursquareV3(41.0082, 28.9784, 2000, 1);
    if (results.length === 0 && consecutiveRateLimits > 0) {
      return { ok: false, msg: `FSQ rate-limit aktif (burst kalan: ${burstRemaining}) — birkaç dakika bekleyin` };
    }
    return { ok: true, count: results.length };
  } catch (e) {
    return { ok: false, msg: e.message, detail: e.detail };
  }
}

async function diagnoseFoursquareApi() {
  const params = new URLSearchParams({
    ll: '41.0082,28.9784',
    radius: '2000',
    limit: '1',
    fields: FSQ_FIELDS,
    sort: 'DISTANCE',
  });
  const headers = {
    Authorization:          `Bearer ${FSQ_API_KEY}`,
    Accept:                 'application/json',
    'X-Places-Api-Version': FSQ_VERSION_H,
  };

  const res = await fetch(`${FSQ_V3_BASE}?${params}`, {
    headers,
    signal: AbortSignal.timeout(20000),
  });
  const body = await res.text().catch(() => '');

  console.log(`HTTP: ${res.status} ${res.statusText}`);
  const rateHeaders = collectRateLimitHeaders(res.headers);
  if (Object.keys(rateHeaders).length > 0) {
    console.log('Headerlar:');
    for (const [key, value] of Object.entries(rateHeaders)) {
      console.log(`  ${key}: ${value}`);
    }
  } else {
    console.log('Headerlar: rate/quota/retry header bulunamadı');
  }
  console.log(`Yanıt: ${body.slice(0, 1000) || '(boş)'}`);
}

async function fetchAllFoursquare(district) {
  const { center, bbox } = district;
  const radiusM = calcRadius(bbox, center);
  const cells   = buildGridCells(bbox, center, radiusM);
  const cellRadius = Math.min(14000, radiusM);

  const allById = new Map();
  for (let ci = 0; ci < cells.length; ci++) {
    const cell = cells[ci];
    const results = await fetchFoursquareV3(cell.lat, cell.lon, cellRadius);
    for (const r of results) {
      const id = r.fsq_place_id ?? r.fsq_id;
      if (id && !allById.has(id)) allById.set(id, r);
    }
    if (ci < cells.length - 1) await sleep(1000);
  }

  return { places: Array.from(allById.values()), cells: cells.length, radiusM };
}

// ── Veri dönüşümü ─────────────────────────────────────────────────────────────

const GENERIC_NAMES = new Set(['restaurant', 'cafe', 'bar', 'food', 'restoran', 'kafe']);

function placesToRows(places, cityName, districtName) {
  const byFsqId = new Map();

  for (const p of places) {
    const name = normStr(p.name);
    if (!name || name.length < 2) continue;
    if (GENERIC_NAMES.has(name.toLowerCase())) continue;

    // Yeni API: top-level latitude/longitude (eski: geocodes.main.latitude)
    const lat = p.latitude  ?? p.geocodes?.main?.latitude;
    const lng = p.longitude ?? p.geocodes?.main?.longitude;
    if (lat == null || lng == null) continue;

    const category = getFsqCategory(p.categories ?? []);
    if (!category) continue;

    // Yeni API: fsq_place_id (eski: fsq_id)
    const fsqId = p.fsq_place_id ?? p.fsq_id;
    if (!fsqId || byFsqId.has(fsqId)) continue;

    const loc       = p.location ?? {};
    const addrParts = [loc.address, loc.cross_street].filter(Boolean);

    // Foto: ilk indoor/food fotoğrafı logo, ikincisi cover olarak al
    const photos = p.photos ?? [];
    const logoPhoto  = photos[0] ?? null;
    const coverPhoto = photos[1] ?? photos[0] ?? null;

    const row = {
      source:    'foursquare',
      source_id: fsqId,
      name,
      category,
      phone:    normStr(p.tel) || null,
      address:  addrParts.join(', ') || null,
      // FSQ locality güvenilmez (telefon, adres dönebilir) — ilce-koordinatlari.json
      // kaynaklı cityName kullan; sadece 2-30 karakter, rakam içermeyen değerlere fall back et
      city: (() => {
        const fsqCity = normStr(loc.locality || loc.region);
        const isClean = fsqCity.length >= 2 && fsqCity.length <= 30 && !/\d/.test(fsqCity) && !/[,/\\+@]/.test(fsqCity);
        return isClean ? fsqCity : cityName;
      })(),
      district: districtName,
      neighborhood: normStr(loc.neighborhood?.[0]) || null,
      lat,
      lng,
      reservation_url: normStr(p.website) || null,
      logo_url:  fsqPhotoUrl(logoPhoto,  '500x500') || null,
      cover_url: fsqPhotoUrl(coverPhoto, '1200x600') || null,
    };
    row.fingerprint = makeFingerprint(row);
    byFsqId.set(fsqId, row);
  }

  // fingerprint dedup
  const seen = new Map();
  const rows = [];
  for (const row of byFsqId.values()) {
    if (!seen.has(row.fingerprint)) {
      seen.set(row.fingerprint, true);
      rows.push(row);
    }
  }
  return rows;
}

// ── Supabase: import RPC kullan (trigger-safe, timeout-free) ──────────────────

async function upsertBatch(rows) {
  const { error } = await supabase.rpc('import_osm_businesses_batch_v1', {
    p_rows: rows,
  });
  if (error) throw new Error(`RPC upsert hatası: ${error.message}`);
}

async function upsertInBatches(rows, batchSize = 50) {
  for (let i = 0; i < rows.length; i += batchSize) {
    await upsertBatch(rows.slice(i, i + batchSize));
  }
}

// ── Supabase: Foursquare fotoğraf import ──────────────────────────────────────

async function loadFoursquarePhotoTargets() {
  const { data, error } = await supabase
    .from('businesses')
    .select('id,name,source_id,logo_url,cover_url')
    .eq('source', 'foursquare')
    .not('source_id', 'is', null)
    .or('logo_url.is.null,cover_url.is.null')
    .order('created_at', { ascending: true })
    .limit(PHOTOS_PER_RUN);

  if (error) throw new Error(`Foto hedefleri okunamadı: ${error.message}`);
  return data ?? [];
}

async function loadExistingMediaUrls(businessId) {
  const { data, error } = await supabase
    .from('business_media')
    .select('url')
    .eq('business_id', businessId)
    .eq('provider', 'foursquare');

  if (error) throw new Error(`Mevcut medya okunamadı: ${error.message}`);
  return new Set((data ?? []).map(row => row.url).filter(Boolean));
}

async function insertBusinessMediaRows(rows) {
  if (rows.length === 0) return 0;
  const { error } = await supabase
    .from('business_media')
    .insert(rows);

  if (error) throw new Error(`business_media insert hatası: ${error.message}`);
  return rows.length;
}

async function updateBusinessPhotoColumns(business, mediaRows) {
  const patch = {};
  if (!business.logo_url && mediaRows[0]?.url_thumb) {
    patch.logo_url = mediaRows[0].url_thumb;
    patch.logo_provider = 'foursquare';
  }
  if (!business.cover_url) {
    patch.cover_url = mediaRows[1]?.url_large ?? mediaRows[0]?.url_large ?? mediaRows[0]?.url ?? null;
    if (patch.cover_url) patch.cover_provider = 'foursquare';
  }

  if (Object.keys(patch).length === 0) return false;

  const { error } = await supabase
    .from('businesses')
    .update(patch)
    .eq('id', business.id);

  if (error) throw new Error(`businesses foto alanı güncellenemedi: ${error.message}`);
  return true;
}

async function importFoursquarePhotos() {
  console.log('🖼️ Foursquare fotoğraf import modu');
  console.log(`   Hedef: ${PHOTOS_PER_RUN} mekan | mekan başı ${PHOTOS_PER_PLACE} foto`);

  const targets = await loadFoursquarePhotoTargets();
  console.log(`   Fotoğraf bekleyen Foursquare mekan: ${targets.length}`);
  if (targets.length === 0) return;

  let imported = 0;
  let updatedBusinesses = 0;
  let empty = 0;
  let errors = 0;

  for (let i = 0; i < targets.length; i++) {
    const business = targets[i];
    process.stdout.write(`[${i + 1}/${targets.length}] ${business.name} ... `);

    try {
      const photos = await fetchFoursquarePhotos(business.source_id);
      const mediaRows = businessMediaRowsFromPhotos(business.id, photos);
      const existingUrls = await loadExistingMediaUrls(business.id);
      const newRows = mediaRows.filter(row => !existingUrls.has(row.url));

      if (newRows.length === 0) {
        empty++;
        process.stdout.write(`⬜ foto yok/yeni değil (${photos.length})\n`);
      } else {
        imported += await insertBusinessMediaRows(newRows);
        if (await updateBusinessPhotoColumns(business, newRows)) updatedBusinesses++;
        process.stdout.write(`✅ ${newRows.length} foto (${photos.length} FSQ)\n`);
      }
    } catch (err) {
      if (err.name === 'QuotaExhaustedError') {
        process.stdout.write(`\n\n🚫 ${err.message}\n`);
        const detail = formatRateLimitDetail(err.detail);
        if (detail) console.log(detail);
        break;
      }
      errors++;
      process.stdout.write(`❌ ${err.message}\n`);
    }

    if (i < targets.length - 1) await sleep(REQUEST_DELAY_MS);
  }

  console.log('\n─────────────────────────────────────────────────');
  console.log(`📊 Foto import: ${imported} medya | ${updatedBusinesses} mekan logo/cover | ${empty} boş | ${errors} hata`);
}

// ── Progress ──────────────────────────────────────────────────────────────────

function loadProgress() {
  try {
    if (fs.existsSync(PROGRESS_FILE))
      return JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf8'));
  } catch {}
  return { completedIds: [], totalImported: 0, totalEmpty: 0 };
}

function saveProgress(p) {
  fs.mkdirSync('./veri_json', { recursive: true });
  fs.writeFileSync(PROGRESS_FILE, JSON.stringify(p, null, 2));
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🍴 Foursquare v3 → Supabase import başlıyor...');

  if (diagnoseFlag) {
    console.log('🔎 Foursquare tek istek diagnostik modu');
    await diagnoseFoursquareApi();
    return;
  }

  if (photosFlag) {
    await importFoursquarePhotos();
    return;
  }

  process.stdout.write('🔌 Foursquare API test ediliyor... ');
  const authTest = await testFoursquareAuth();
  if (!authTest.ok) {
    console.error(`\n❌ ${authTest.msg}`);
    const detail = formatRateLimitDetail(authTest.detail);
    if (detail) console.error(detail);
    process.exit(1);
  }
  console.log(`✅ bağlandı (${authTest.count} test sonucu)\n`);

  const ilceData     = JSON.parse(fs.readFileSync(ILCE_JSON, 'utf8'));
  const allDistricts = ilceData.out;
  console.log(`📍 Toplam ilçe: ${allDistricts.length}`);

  if (resetFlag && fs.existsSync(PROGRESS_FILE)) {
    fs.unlinkSync(PROGRESS_FILE);
    console.log('🔄 İlerleme sıfırlandı.');
  }

  const progress    = loadProgress();
  const completedSet = new Set(progress.completedIds);
  const pending      = allDistricts.filter(d => !completedSet.has(d.ilce_id));

  console.log(`✅ Tamamlanan: ${completedSet.size} | ⏳ Bekleyen: ${pending.length}`);
  if (pending.length === 0) {
    console.log('\n🎉 Tüm ilçeler zaten işlendi!');
    console.log(`   Toplam aktarılan: ${progress.totalImported}`);
    return;
  }

  const batch = pending.slice(0, DISTRICTS_PER_RUN);
  console.log(`\n🔄 Bu çalışmada işlenecek: ${batch.length} ilçe\n`);

  let runImported = 0;
  let runEmpty    = 0;
  let runErrors   = 0;

  for (let i = 0; i < batch.length; i++) {
    const d          = batch[i];
    const cityName   = titleCaseTr(d.sehir_adi);
    const districtName = titleCaseTr(d.ilce_adi);

    process.stdout.write(`[${i + 1}/${batch.length}] ${cityName} / ${districtName} ... `);

    try {
      const { places, cells, radiusM } = await fetchAllFoursquare(d);
      const rows = placesToRows(places, cityName, districtName);

      if (rows.length > 0) {
        await upsertInBatches(rows);
        runImported += rows.length;
        process.stdout.write(`✅ ${rows.length} kayıt (${places.length} FSQ, ${cells} hücre, ${(radiusM/1000).toFixed(1)}km)\n`);
      } else {
        runEmpty++;
        process.stdout.write(`⬜ bulunamadı (${places.length} FSQ, ${cells} hücre)\n`);
      }

      progress.completedIds.push(d.ilce_id);
      saveProgress(progress);
    } catch (err) {
      if (err.name === 'QuotaExhaustedError') {
        process.stdout.write(`\n\n🚫 ${err.message}\n`);
        const detail = formatRateLimitDetail(err.detail);
        if (detail) console.log(detail);
        console.log(`   Bugüne kadar işlenen: ${progress.completedIds.length}/${allDistricts.length} ilçe`);
        console.log('   İlerleme kaydedildi. Console usage/billing düzeldikten sonra tekrar çalıştırın:');
        console.log('   node tools/foursquare-ilce-ice-aktar.mjs');
        break;
      }
      runErrors++;
      process.stdout.write(`❌ ${err.message}\n`);
    }

    if (i < batch.length - 1) await sleep(REQUEST_DELAY_MS);
  }

  progress.totalImported = (progress.totalImported || 0) + runImported;
  progress.totalEmpty    = (progress.totalEmpty    || 0) + runEmpty;
  saveProgress(progress);

  const remaining = pending.length - batch.length;
  console.log('\n─────────────────────────────────────────────────');
  console.log(`📊 Bu çalışma : ${runImported} kayıt | ${runEmpty} boş | ${runErrors} hata`);
  console.log(`📊 Genel      : ${progress.completedIds.length}/${allDistricts.length} ilçe`);
  console.log(`📊 Toplam DB  : ${progress.totalImported} kayıt`);

  if (remaining > 0) {
    console.log(`\n⏩ Kalan ${remaining} ilçe için tekrar çalıştır:`);
    console.log('   node tools/foursquare-ilce-ice-aktar.mjs');
  } else {
    console.log('\n🎉 Tüm ilçeler tamamlandı!');
  }
}

main().catch(err => {
  console.error('\n❌ Script hatası:', err.message);
  process.exit(1);
});
