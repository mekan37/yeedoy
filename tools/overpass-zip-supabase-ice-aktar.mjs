import 'dotenv/config';
import AdmZip from 'adm-zip';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const ZIP_PATH = process.env.ZIP_PATH || './overpass-ciktilari.zip';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const ALLOWED = new Set(['Kafe', 'Restoran', 'Tatlıcı', 'Kahvaltı', 'Balık / Et', 'Mekan']);

// Optional: skip very generic OSM names which are not useful
const GENERIC_NAMES = new Set(['restaurant', 'cafe', 'bar', 'pub', 'nightclub']);

function normStr(s) {
  return (s ?? '').toString().trim();
}

function normalizeName(name) {
  // basic normalize (TR chars ok)
  return normStr(name).toLowerCase().replace(/\s+/g, ' ');
}

function roundCoord(x, p = 4) {
  // 4 decimals ~ 11m precision. Good for dedupe.
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

  // priority: Mekan > Tatlıcı > Kahvaltı > Balık/Et > Kafe > Restoran
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

function parseCityDistrictFromEntry(entryName) {
  // Example: overpass-ciktilari/ankara__yeni-mahalle__6_1723.json
  // city__district__...
  const base = entryName.split('/').pop() || entryName;
  const parts = base.replace('.json', '').split('__');
  const city = (parts[0] || '').replace(/-/g, ' ');
  const district = (parts[1] || '').replace(/-/g, ' ');
  return {
    city: city ? titleCaseTr(city) : null,
    district: district ? titleCaseTr(district) : null,
  };
}

function titleCaseTr(s) {
  // very simple: first char upper, rest lower per word
  return s
    .split(' ')
    .filter(Boolean)
    .map(w => w.charAt(0).toLocaleUpperCase('tr-TR') + w.slice(1).toLocaleLowerCase('tr-TR'))
    .join(' ');
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

async function main() {
  const zip = new AdmZip(ZIP_PATH);
  const entries = zip.getEntries()
    .filter(e => !e.isDirectory && e.entryName.endsWith('.json') && e.entryName.includes('overpass-ciktilari/'));

  console.log('JSON files found:', entries.length);

  const stageRows = [];
  const businessRows = [];

  for (const entry of entries) {
    const { city, district } = parseCityDistrictFromEntry(entry.entryName);

    const rawText = entry.getData().toString('utf8');
    let json;
    try {
      json = JSON.parse(rawText);
    } catch {
      console.warn('Skip invalid JSON:', entry.entryName);
      continue;
    }

    // Senin dosya formatında overpass elemanları şurada olabilir:
    const elements = json?.overpass?.elements || json?.elements || [];
    if (!Array.isArray(elements) || elements.length === 0) continue;

    for (const el of elements) {
      const tags = el.tags || {};

      // ✅ name yoksa / boşsa direkt atla
      const name = (tags.name ?? '').toString().trim();
      if (!name || name.length < 2) continue;

      // Opsiyonel: çok generic/önemsiz isimleri atla
      if (GENERIC_NAMES.has(name.toLowerCase())) continue;

      const { lat, lng } = getLatLng(el);
      if (lat == null || lng == null) continue;

      const category = pickCategory(tags);
      if (!category || !ALLOWED.has(category)) continue;

      const source = 'osm';
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

      // businesses şeman: name, category, description, phone, address, city, district, lat, lng, is_active
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
  }

  console.log('\nStage rows:', stageRows.length);

  // ---------------------------
  // DEDUPE (CRITICAL)
  // ---------------------------

  // 1) stage: source|source_id tekilleştir
  {
    const m = new Map();
    for (const r of stageRows) {
      const k = `${r.source}|${r.source_id}`;
      m.set(k, r); // aynı key gelirse sonuncuyu tutar
    }
    stageRows.length = 0;
    stageRows.push(...m.values());
  }

  // 2) businesses: source|source_id tekilleştir
  {
    const m = new Map();
    for (const r of businessRows) {
      const k = `${r.source}|${r.source_id}`;
      m.set(k, r);
    }
    businessRows.length = 0;
    businessRows.push(...m.values());
  }

  // 3) businesses: fingerprint tekilleştir (veri şişmesin diye)
  {
    const seen = new Set();
    const filtered = [];
    for (const r of businessRows) {
      const fp = r.fingerprint;
      if (!fp) continue;
      if (seen.has(fp)) continue; // aynı fingerprint -> atla
      seen.add(fp);
      filtered.push(r);
    }
    businessRows.length = 0;
    businessRows.push(...filtered);
  }

  console.log('\nAfter dedupe => Stage:', stageRows.length, 'Businesses:', businessRows.length);

  console.log('Business rows:', businessRows.length);

  if (!stageRows.length) {
    console.log('No rows to import. Done.');
    return;
  }

  // 1) stage upsert (source,source_id)
  await upsertInBatches('import_places_stage', stageRows, 'source,source_id', 800);

  // 2) businesses upsert
  // Önce source_id ile upsert (kesin)
  // Ayrıca fingerprint unique olduğu için aynı yere tekrar basınca çakışma olmaz.
  await upsertInBatches('businesses', businessRows, 'source,source_id', 500);

  console.log('\n✅ Import completed.');
}

main().catch((e) => {
  console.error('\n❌ Import failed:', e);
  process.exit(1);
});
