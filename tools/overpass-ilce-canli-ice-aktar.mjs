/**
 * overpass-ilce-canli-ice-aktar.mjs
 *
 * ilce-koordinatlari.json'daki her ilçe için Overpass API'den canlı veri çeker,
 * mevcut kayıtları günceller (source+source_id upsert), yeni olanları ekler.
 * İlerleme veri_json/.overpass-ilce-progress.json dosyasına kaydedilir;
 * script tekrar çalıştırıldığında kaldığı yerden devam eder.
 *
 * Kullanım:
 *   DISTRICTS_PER_RUN=20 node tools/overpass-ilce-canli-ice-aktar.mjs
 *   DISTRICTS_PER_RUN=20 node tools/overpass-ilce-canli-ice-aktar.mjs --reset   (ilerlemeyi sıfırla)
 *
 * .env gereksinimleri: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 */

import 'dotenv/config';
import fs from 'fs';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

// ── config ────────────────────────────────────────────────────────────────────

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const ILCE_JSON = process.env.ILCE_JSON || './veri_json/ilce-koordinatlari.json';
const PROGRESS_FILE = './veri_json/.overpass-ilce-progress.json';
const DISTRICTS_PER_RUN = parseInt(process.env.DISTRICTS_PER_RUN || '20', 10);
const REQUEST_DELAY_MS = parseInt(process.env.REQUEST_DELAY_MS || '2500', 10);
const OVERPASS_TIMEOUT_S = 30;
const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY .env dosyasında eksik');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const ALLOWED_CATEGORIES = new Set(['Kafe', 'Restoran', 'Tatlıcı', 'Kahvaltı', 'Balık / Et', 'Mekan']);

// ── string helpers ────────────────────────────────────────────────────────────

function normStr(s) { return (s ?? '').toString().trim(); }
function normalizeName(n) { return normStr(n).toLowerCase().replace(/\s+/g, ' '); }

function roundCoord(x, p = 4) {
  const n = Number(x);
  return Number.isFinite(n) ? Math.round(n * 10 ** p) / 10 ** p : null;
}

function titleCaseTr(s) {
  return normStr(s).split(' ').filter(Boolean)
    .map(w => w.charAt(0).toLocaleUpperCase('tr-TR') + w.slice(1).toLocaleLowerCase('tr-TR'))
    .join(' ');
}

// ── fingerprint / category / address ─────────────────────────────────────────

function makeFingerprint({ name, lat, lng, city, district, category }) {
  const key = [
    normalizeName(name),
    category ?? '',
    normStr(city).toLowerCase(),
    normStr(district).toLowerCase(),
    String(roundCoord(lat) ?? ''),
    String(roundCoord(lng) ?? ''),
  ].join('|');
  return crypto.createHash('sha1').update(key).digest('hex');
}

function getLatLng(el) {
  return { lat: el.lat ?? el.center?.lat, lng: el.lon ?? el.center?.lon };
}

function buildAddress(tags = {}) {
  const street = normStr(tags['addr:street']);
  const no = normStr(tags['addr:housenumber']);
  const neigh = normStr(tags['addr:neighbourhood']);
  const parts = [street && no ? `${street} ${no}` : street, neigh].filter(Boolean);
  return parts.join(', ') || null;
}

function pickPhone(tags = {}) {
  return normStr(tags.phone || tags['contact:phone']) || null;
}

function pickCategory(tags = {}) {
  const amenity = normStr(tags.amenity);
  const shop = normStr(tags.shop);
  const cuisine = normStr(tags.cuisine).toLowerCase();
  const liveMusic = normStr(tags.live_music).toLowerCase();
  const breakfast = normStr(tags.breakfast).toLowerCase();
  const name = normStr(tags.name).toLowerCase();

  if (['bar', 'pub', 'nightclub'].includes(amenity) || liveMusic === 'yes') return 'Mekan';

  if (
    amenity === 'ice_cream' ||
    shop === 'confectionery' ||
    /dessert|ice_cream|patisserie/.test(cuisine) ||
    /tatl|pasta|baklava|dondurma/.test(name)
  ) return 'Tatlıcı';

  if (
    breakfast === 'yes' ||
    /breakfast|brunch/.test(cuisine) ||
    /kahvalt|serpme|brunch/.test(name)
  ) return 'Kahvaltı';

  if (
    /seafood|fish|steak|kebab|bbq|barbecue|meat/.test(cuisine) ||
    /balık|ocakbaşı|steak|et lokantası/.test(name)
  ) return 'Balık / Et';

  if (amenity === 'cafe') return 'Kafe';
  if (amenity === 'restaurant') return 'Restoran';
  if (['fast_food', 'food_court'].includes(amenity)) return 'Restoran';
  if (['food', 'bakery', 'deli'].includes(shop)) return 'Restoran';

  return null;
}

// ── overpass ──────────────────────────────────────────────────────────────────

// bbox alanı bu eşiğin altındaysa koordinatlar büyük ihtimalle yanlış;
// merkez noktadan radius sorgusu kullanılır
const SMALL_BBOX_THRESHOLD = 0.04; // derece²

function buildOverpassQuery(d) {
  const { bbox, center } = d;
  const area = (bbox.north - bbox.south) * (bbox.east - bbox.west);

  const amenityFilters = [
    'restaurant', 'cafe', 'fast_food', 'food_court',
    'bar', 'pub', 'ice_cream',
  ].map(a => `[amenity=${a}]`);
  const shopFilters = ['food', 'bakery', 'confectionery', 'deli'].map(s => `[shop=${s}]`);

  if (area < SMALL_BBOX_THRESHOLD) {
    // küçük / yanlış bbox → şehir merkezi için 15km radius
    const radius = 15000;
    const around = `(around:${radius},${center.lat},${center.lon})`;
    const lines = [
      ...amenityFilters.map(f => `  nwr${f}${around};`),
      ...shopFilters.map(f => `  nwr${f}${around};`),
    ].join('\n');
    return `[out:json][timeout:${OVERPASS_TIMEOUT_S}];\n(\n${lines}\n);\nout center tags;`;
  }

  // normal bbox sorgusu
  const { south, west, north, east } = bbox;
  return `[out:json][timeout:${OVERPASS_TIMEOUT_S}][bbox:${south},${west},${north},${east}];
(
  nwr[amenity=restaurant];
  nwr[amenity=cafe];
  nwr[amenity=fast_food];
  nwr[amenity=food_court];
  nwr[amenity=bar];
  nwr[amenity=pub];
  nwr[amenity=ice_cream];
  nwr[shop=food];
  nwr[shop=bakery];
  nwr[shop=confectionery];
  nwr[shop=deli];
);
out center tags;`;
}

async function fetchOverpass(query, retries = 3) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), (OVERPASS_TIMEOUT_S + 15) * 1000);
      let res;
      try {
        res = await fetch(OVERPASS_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json, text/json, */*',
            'User-Agent': 'YeedoyImporter/1.0 (https://yeedoy.com)',
          },
          body: `data=${encodeURIComponent(query)}`,
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timer);
      }

      if (res.status === 429 || res.status === 503) {
        const wait = attempt * 15000;
        process.stdout.write(`⏳ rate-limit, ${wait / 1000}s bekleniyor... `);
        await sleep(wait);
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const json = await res.json();
      return json.elements ?? [];
    } catch (err) {
      if (err.name === 'AbortError') {
        if (attempt < retries) { await sleep(5000 * attempt); continue; }
        throw new Error('Overpass timeout');
      }
      if (attempt === retries) throw err;
      await sleep(5000 * attempt);
    }
  }
  return [];
}

// ── db ────────────────────────────────────────────────────────────────────────

async function upsertInBatches(table, rows, onConflict, batchSize = 500) {
  for (let i = 0; i < rows.length; i += batchSize) {
    const chunk = rows.slice(i, i + batchSize);
    let result;
    try {
      result = await supabase.from(table).upsert(chunk, { onConflict });
    } catch (fetchErr) {
      throw new Error(`${table} fetch hatası: ${fetchErr.message} — SUPABASE_URL: ${SUPABASE_URL?.replace(/https?:\/\//, '').slice(0, 30)}...`);
    }
    if (result.error) {
      throw new Error(`${table} upsert hatası: ${result.error.message} (code: ${result.error.code})`);
    }
  }
}

async function testSupabaseConnection() {
  try {
    const { error } = await supabase.from('import_places_stage').select('source').limit(1);
    if (error) throw new Error(error.message);
    return true;
  } catch (e) {
    return e.message;
  }
}

// ── element → rows ────────────────────────────────────────────────────────────

const GENERIC_NAMES = new Set(['restaurant', 'cafe', 'bar', 'pub', 'fast_food', 'food', 'bakery']);

function elementsToRows(elements, cityName, districtName) {
  // source_id bazlı ilk geçiş
  const bySourceId = new Map();

  for (const el of elements) {
    const tags = el.tags || {};
    const name = normStr(tags.name);
    if (!name || name.length < 2) continue;
    if (GENERIC_NAMES.has(name.toLowerCase())) continue;

    const { lat, lng } = getLatLng(el);
    if (lat == null || lng == null) continue;

    const category = pickCategory(tags);
    if (!category || !ALLOWED_CATEGORIES.has(category)) continue;

    const source = 'osm';
    const sourceId = `${el.type}/${el.id}`;
    if (bySourceId.has(sourceId)) continue;

    const row = {
      source,
      source_id: sourceId,
      name,
      category,
      phone: pickPhone(tags),
      address: buildAddress(tags),
      city: normStr(tags['addr:city']) || cityName,
      district: normStr(tags['addr:district']) || districtName,
      lat,
      lng,
    };
    row.fingerprint = makeFingerprint(row);
    bySourceId.set(sourceId, { el, tags, row });
  }

  // fingerprint bazlı dedup — aynı fiziksel mekan hem node hem way olarak gelebilir;
  // node kaydı tercih edilir (daha kesin koordinat), yoksa ilk gelen alınır
  const byFingerprint = new Map();
  for (const { el, tags, row } of bySourceId.values()) {
    const fp = row.fingerprint;
    if (!byFingerprint.has(fp)) {
      byFingerprint.set(fp, { el, tags, row });
    } else if (el.type === 'node' && byFingerprint.get(fp).el.type !== 'node') {
      byFingerprint.set(fp, { el, tags, row });
    }
  }

  const stageRows = [];
  const bizRows = [];

  for (const { el, tags, row } of byFingerprint.values()) {
    stageRows.push({
      ...row,
      raw: { ...tags, osm_type: el.type, osm_id: el.id },
    });

    bizRows.push({
      name: row.name,
      category: row.category,
      description: null,
      phone: row.phone,
      address: row.address,
      city: row.city,
      district: row.district,
      lat: row.lat,
      lng: row.lng,
      is_active: true,
      source: row.source,
      source_id: row.source_id,
      fingerprint: row.fingerprint,
    });
  }

  return { stageRows, bizRows };
}

// ── progress ──────────────────────────────────────────────────────────────────

function loadProgress() {
  try {
    if (fs.existsSync(PROGRESS_FILE)) {
      return JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf8'));
    }
  } catch {}
  return { completedIds: [], totalImported: 0, totalEmpty: 0 };
}

function saveProgress(p) {
  fs.writeFileSync(PROGRESS_FILE, JSON.stringify(p, null, 2));
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ── main ──────────────────────────────────────────────────────────────────────

async function main() {
  const resetFlag = process.argv.includes('--reset');

  // Supabase bağlantı testi
  const maskedUrl = SUPABASE_URL?.replace(/https?:\/\//, '').slice(0, 40) + '...';
  process.stdout.write(`🔌 Supabase bağlantısı test ediliyor (${maskedUrl}) ... `);
  const connResult = await testSupabaseConnection();
  if (connResult !== true) {
    console.error(`\n❌ Supabase bağlantı hatası: ${connResult}`);
    console.error(`   SUPABASE_URL=${SUPABASE_URL}`);
    console.error('   Üretim URL\'si: https://<proje-id>.supabase.co');
    console.error('   Kök dizinde .env dosyanızda SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY olmalı');
    process.exit(1);
  }
  console.log('✅ bağlı\n');

  const ilceData = JSON.parse(fs.readFileSync(ILCE_JSON, 'utf8'));
  const allDistricts = ilceData.out;
  console.log(`📍 Toplam ilçe: ${allDistricts.length}`);

  if (resetFlag) {
    if (fs.existsSync(PROGRESS_FILE)) fs.unlinkSync(PROGRESS_FILE);
    console.log('🔄 İlerleme sıfırlandı.');
  }

  const progress = loadProgress();
  const completedSet = new Set(progress.completedIds);
  const pending = allDistricts.filter(d => !completedSet.has(d.ilce_id));

  console.log(`✅ Tamamlanan: ${completedSet.size} | ⏳ Bekleyen: ${pending.length}`);

  if (pending.length === 0) {
    console.log('\n🎉 Tüm ilçeler zaten işlendi!');
    console.log(`   Toplam içe aktarılan: ${progress.totalImported}`);
    return;
  }

  const batch = pending.slice(0, DISTRICTS_PER_RUN);
  console.log(`\n🔄 Bu çalışmada işlenecek: ${batch.length} ilçe\n`);

  let runImported = 0;
  let runEmpty = 0;
  let runErrors = 0;

  for (let i = 0; i < batch.length; i++) {
    const d = batch[i];
    const cityName = titleCaseTr(d.sehir_adi);
    const districtName = titleCaseTr(d.ilce_adi);
    const label = `[${i + 1}/${batch.length}] ${cityName} / ${districtName}`;

    process.stdout.write(`${label} ... `);

    try {
      const query = buildOverpassQuery(d);
      const elements = await fetchOverpass(query);

      const { stageRows, bizRows } = elementsToRows(elements, cityName, districtName);

      if (bizRows.length > 0) {
        await upsertInBatches('import_places_stage', stageRows, 'source,source_id');

        // Önce bu batch'in source_id'lerine sahip eski kayıtları sil.
        // Gerekçe: fingerprint değişmiş olabilir (ad güncellendi) → eski kayıt
        // hem source_id hem fingerprint constraint'ini kilitler. Silince iki
        // constraint de serbest kalır, fingerprint upsert sağlıklı çalışır.
        const sourceIds = bizRows.map(r => r.source_id);
        for (let s = 0; s < sourceIds.length; s += 500) {
          const chunk = sourceIds.slice(s, s + 500);
          const { error: delErr } = await supabase
            .from('businesses')
            .delete()
            .eq('source', 'osm')
            .in('source_id', chunk);
          if (delErr) throw new Error(`businesses delete hatası: ${delErr.message}`);
        }

        // fingerprint üzerinden upsert: aynı fiziksel mekan farklı osm id ile
        // gelirse güncellenir; source_id conflict artık kalmadı
        await upsertInBatches('businesses', bizRows, 'fingerprint');
        runImported += bizRows.length;
        process.stdout.write(`✅ ${bizRows.length} kayıt\n`);
      } else {
        runEmpty++;
        process.stdout.write(`⬜ OSM'de bulunamadı\n`);
      }

      progress.completedIds.push(d.ilce_id);
      saveProgress(progress);

    } catch (err) {
      runErrors++;
      process.stdout.write(`❌ ${err.message}\n`);
      // ilçeyi tamamlandı olarak işaretlemiyoruz → bir sonraki çalışmada tekrar denenecek
    }

    // son eleman değilse bekle
    if (i < batch.length - 1) {
      await sleep(REQUEST_DELAY_MS);
    }
  }

  progress.totalImported = (progress.totalImported || 0) + runImported;
  progress.totalEmpty = (progress.totalEmpty || 0) + runEmpty;
  saveProgress(progress);

  const remaining = pending.length - batch.length;
  console.log('\n─────────────────────────────────────────');
  console.log(`📊 Bu çalışma : ${runImported} kayıt içe aktarıldı, ${runEmpty} boş ilçe, ${runErrors} hata`);
  console.log(`📊 Genel      : ${progress.completedIds.length}/${allDistricts.length} ilçe tamamlandı`);
  console.log(`📊 Toplam DB  : ${progress.totalImported} kayıt`);

  if (remaining > 0) {
    console.log(`\n⏩ Kalan ${remaining} ilçe için tekrar çalıştırın:`);
    console.log(`   node tools/overpass-ilce-canli-ice-aktar.mjs`);
  } else {
    console.log('\n🎉 Tüm ilçeler tamamlandı!');
  }
}

main().catch(err => {
  console.error('\n❌ Script hatası:', err.message);
  process.exit(1);
});
