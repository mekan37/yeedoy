import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import AdmZip from 'adm-zip';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const ZIP_PATH = process.env.ZIP_PATH || './overpass-ciktilari.zip';
const EXTRA_DIR = process.env.EXTRA_DIR || './ek_json';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const ALLOWED = new Set(['Kafe', 'Restoran', 'Tatlıcı', 'Kahvaltı', 'Balık / Et', 'Mekan']);

function normStr(s) { return (s ?? '').toString().trim(); }
function normalizeName(name) { return normStr(name).toLowerCase().replace(/\s+/g, ' '); }

function roundCoord(x, p = 4) {
  if (x == null) return null;
  const n = Number(x);
  if (!Number.isFinite(n)) return null;
  const m = 10 ** p;
  return Math.round(n * m) / m;
}

function makeFingerprint({ name, lat, lng, city, district, category }) {
  const key = [
    normalizeName(name),
    category ?? '',
    normStr(city).toLowerCase(),
    normStr(district).toLowerCase(),
    String(roundCoord(lat, 4) ?? ''),
    String(roundCoord(lng, 4) ?? ''),
  ].join('|');
  return crypto.createHash('sha1').update(key).digest('hex');
}

function getLatLng(el) {
  const lat = el.lat ?? el.center?.lat;
  const lng = el.lon ?? el.center?.lon;
  return { lat, lng };
}

function buildAddress(tags = {}) {
  const street = normStr(tags['addr:street']);
  const no = normStr(tags['addr:housenumber']);
  const neigh = normStr(tags['addr:neighbourhood']);
  const txt = [street && no ? `${street} ${no}` : street, neigh].filter(Boolean).join(', ');
  return txt || null;
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

  if (/seafood|fish|steak|kebab|bbq|barbecue|meat/.test(cuisine) || /balık|ocakbaşı|steak|et/.test(name)) {
    return 'Balık / Et';
  }

  if (amenity === 'cafe') return 'Kafe';
  if (amenity === 'restaurant') return 'Restoran';

  return null;
}

function titleCaseTr(s) {
  return s
    .split(' ')
    .filter(Boolean)
    .map(w => w.charAt(0).toLocaleUpperCase('tr-TR') + w.slice(1).toLocaleLowerCase('tr-TR'))
    .join(' ');
}

function parseCityDistrictFromFileName(fileName) {
  // expects: city__district__anything.json
  const base = path.basename(fileName).replace('.json', '');
  const parts = base.split('__');
  const city = (parts[0] || '').replace(/-/g, ' ');
  const district = (parts[1] || '').replace(/-/g, ' ');
  return {
    city: city ? titleCaseTr(city) : null,
    district: district ? titleCaseTr(district) : null,
  };
}

async function upsertInBatches(table, rows, onConflict, batchSize = 500) {
  for (let i = 0; i < rows.length; i += batchSize) {
    const chunk = rows.slice(i, i + batchSize);
    const { error } = await supabase.from(table).upsert(chunk, { onConflict });
    if (error) throw error;
    process.stdout.write(`\r${table}: ${Math.min(i + batchSize, rows.length)}/${rows.length}`);
  }
  process.stdout.write('\n');
}

function extractElements(json) {
  // supports both formats:
  // { overpass: { elements: [...] } } or { elements: [...] }
  return json?.overpass?.elements || json?.elements || [];
}

function collectFromElements(elements, { city, district }, sourceLabel = 'osm') {
  const stageRows = [];
  const businessRows = [];

  for (const el of elements) {
    const tags = el.tags || {};

    // ✅ name yoksa atla
    const name = normStr(tags.name);
    if (!name) continue;

    const { lat, lng } = getLatLng(el);
    if (lat == null || lng == null) continue;

    const category = pickCategory(tags);
    if (!category || !ALLOWED.has(category)) continue;

    const source = sourceLabel; // 'osm'
    const sourceId = `${el.type}/${el.id}`;

    const row = {
      source,
      source_id: sourceId,
      name,
      category,
      phone: pickPhone(tags),
      address: buildAddress(tags),
      city: city || normStr(tags['addr:city']) || null,
      district: district || normStr(tags['addr:district']) || null,
      lat,
      lng,
    };

    const fingerprint = makeFingerprint(row);

    stageRows.push({
      ...row,
      fingerprint,
      raw: { ...tags, osm_type: el.type, osm_id: el.id },
    });

    businessRows.push({
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
      source,
      source_id: sourceId,
      fingerprint,
    });
  }

  return { stageRows, businessRows };
}

async function main() {
  const allStage = [];
  const allBiz = [];

  // 1) ZIP json files
  const zip = new AdmZip(ZIP_PATH);
  const zipEntries = zip.getEntries().filter(e => !e.isDirectory && e.entryName.endsWith('.json'));
  console.log('ZIP json files:', zipEntries.length);

  for (const entry of zipEntries) {
    const { city, district } = parseCityDistrictFromFileName(entry.entryName);
    let json;
    try {
      json = JSON.parse(entry.getData().toString('utf8'));
    } catch {
      continue;
    }
    const elements = extractElements(json);
    if (!Array.isArray(elements) || elements.length === 0) continue;

    const { stageRows, businessRows } = collectFromElements(elements, { city, district }, 'osm');
    allStage.push(...stageRows);
    allBiz.push(...businessRows);
  }

  // 2) EXTRA_DIR json files
  if (fs.existsSync(EXTRA_DIR)) {
    const files = fs.readdirSync(EXTRA_DIR).filter(f => f.endsWith('.json'));
    console.log('Extra json files:', files.length);

    for (const f of files) {
      const full = path.join(EXTRA_DIR, f);
      const { city, district } = parseCityDistrictFromFileName(f);
      let json;
      try {
        json = JSON.parse(fs.readFileSync(full, 'utf8'));
      } catch {
        console.warn('Skip invalid extra JSON:', f);
        continue;
      }
      const elements = extractElements(json);
      if (!Array.isArray(elements) || elements.length === 0) {
        console.warn('Empty extra JSON:', f);
        continue;
      }

      const { stageRows, businessRows } = collectFromElements(elements, { city, district }, 'osm');
      allStage.push(...stageRows);
      allBiz.push(...businessRows);
    }
  } else {
    console.log('Extra dir not found, skipped:', EXTRA_DIR);
  }

  console.log('\nCollected stage rows:', allStage.length);
  console.log('Collected business rows:', allBiz.length);

  if (!allStage.length) {
    console.log('Nothing to import.');
    return;
  }

  // Dedup in-memory by source+source_id (fast)
  const seen = new Set();
  const stageDedup = [];
  const bizDedup = [];
  for (let i = 0; i < allStage.length; i++) {
    const k = `${allStage[i].source}::${allStage[i].source_id}`;
    if (seen.has(k)) continue;
    seen.add(k);
    stageDedup.push(allStage[i]);
    bizDedup.push(allBiz[i]);
  }

  console.log(`After in-memory dedupe => Stage: ${stageDedup.length} Businesses: ${bizDedup.length}`);

  await upsertInBatches('import_places_stage', stageDedup, 'source,source_id', 800);
  await upsertInBatches('businesses', bizDedup, 'source,source_id', 500);

  console.log('\n✅ Import completed.');
}

main().catch((e) => {
  console.error('\n❌ Import failed:', e);
  process.exit(1);
});
