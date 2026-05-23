/**
 * osm-geojson-poi-ice-aktar.mjs
 * GeoJSONL dosyasından yemek/içecek POI'larını Supabase'e aktarır.
 *
 * Kullanım:
 *   node tools/osm-geojson-poi-ice-aktar.mjs --dosya=turkey-poi-yemek.geojsonl
 *   node tools/osm-geojson-poi-ice-aktar.mjs --dosya=turkey-poi-yemek.geojsonl --dry-run
 *
 * Girdi formatı: GeoJSONL (osmium export çıktısı, satır başına bir Feature)
 * veya FeatureCollection JSON.
 */

import 'dotenv/config';
import { createReadStream, existsSync, writeFileSync, readFileSync } from 'fs';
import { createInterface } from 'readline';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

// ── Ortam değişkenleri ───────────────────────────────────────────────────
const SUPABASE_URL             = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ .env içinde SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY gerekli.');
  process.exit(1);
}

// ── CLI argümanları ──────────────────────────────────────────────────────
const ARGS = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => { const [k, v] = a.slice(2).split('='); return [k, v ?? 'true']; })
);

const DOSYA      = ARGS.dosya || ARGS.file || './turkey-poi-yemek.geojsonl';
const DRY_RUN    = ARGS['dry-run'] === 'true';
const BATCH_SIZE = parseInt(ARGS.batch  || '50');
const STATE_FILE = ARGS.state || '.osm-poi-state.json';

// ── Sabitler ─────────────────────────────────────────────────────────────
const ALLOWED_CATEGORIES = new Set([
  'Kafe', 'Restoran', 'Tatlıcı', 'Kahvaltı', 'Balık / Et', 'Mekan',
]);

const GENERIC_NAMES = new Set([
  'restaurant', 'cafe', 'bar', 'pub', 'nightclub', 'fast food',
]);

// ── Kategori eşleme ───────────────────────────────────────────────────────
function pickCategory(props) {
  const amenity    = norm(props.amenity);
  const shop       = norm(props.shop);
  const cuisine    = norm(props.cuisine).toLowerCase();
  const liveMusic  = norm(props.live_music).toLowerCase();
  const breakfast  = norm(props.breakfast).toLowerCase();
  const name       = norm(props.name).toLowerCase();

  if (['bar','pub','nightclub'].includes(amenity) || liveMusic === 'yes') return 'Mekan';

  if (amenity === 'ice_cream' || shop === 'confectionery' ||
      /dessert|ice_cream|patisserie/.test(cuisine) ||
      /tatl|pasta|baklava|dondurma/.test(name)) return 'Tatlıcı';

  if (breakfast === 'yes' || /breakfast|brunch/.test(cuisine) ||
      /kahvalt|serpme|brunch/.test(name)) return 'Kahvaltı';

  if (/seafood|fish|steak|kebab|bbq|barbecue|meat/.test(cuisine) ||
      /balık|ocakbaşı|steak|et /.test(name)) return 'Balık / Et';

  if (amenity === 'cafe')       return 'Kafe';
  if (amenity === 'restaurant') return 'Restoran';
  if (amenity === 'fast_food')  return 'Restoran';
  if (amenity === 'food_court') return 'Restoran';

  return null;
}

// ── Yardımcı fonksiyonlar ─────────────────────────────────────────────────
function norm(v) { return (v ?? '').toString().trim(); }

function buildAddress(props) {
  const street = norm(props['addr:street']);
  const no     = norm(props['addr:housenumber']);
  const neigh  = norm(props['addr:neighbourhood']);
  const parts  = [street && no ? `${street} ${no}` : street, neigh].filter(Boolean);
  return parts.join(', ') || null;
}

function round4(x) {
  if (x == null) return null;
  const n = Number(x);
  return Number.isFinite(n) ? Math.round(n * 10000) / 10000 : null;
}

function makeFingerprint({ name, lat, lng, city, district, category }) {
  const key = [
    name.toLowerCase().replace(/\s+/g, ' ').trim(),
    category ?? '',
    norm(city).toLowerCase(),
    norm(district).toLowerCase(),
    String(round4(lat)  ?? ''),
    String(round4(lng)  ?? ''),
  ].join('|');
  return crypto.createHash('sha1').update(key).digest('hex');
}

function osmIdFromProps(props) {
  // osmium varsayılanda @id dahil etmez; config ile etkinleştirilmişse gelir
  const raw = props['@id'] || props['@osmId'] || props['osm_id'] || '';
  const parts = raw.toString().split('/');
  const id = parts[parts.length - 1];
  return id && id !== '' ? id : null;
}

function osmTypeFromProps(props) {
  const raw = (props['@id'] || props['@osmType'] || '').toString();
  if (raw.startsWith('way/') || raw === 'way')      return 'way';
  if (raw.startsWith('relation/') || raw === 'relation') return 'relation';
  return 'node';
}

// ── Feature → businesses satırı ───────────────────────────────────────────
function featureToRow(feature) {
  const props = feature.properties || {};
  const geom  = feature.geometry   || {};

  const name = norm(props.name || props['name:tr']);
  if (!name || name.length < 2)           return null;
  if (GENERIC_NAMES.has(name.toLowerCase())) return null;

  const category = pickCategory(props);
  if (!category || !ALLOWED_CATEGORIES.has(category)) return null;

  let lat, lng;
  if (geom.type === 'Point' && Array.isArray(geom.coordinates)) {
    [lng, lat] = geom.coordinates;
  } else if (props.lat != null && props.lon != null) {
    lat = Number(props.lat);
    lng = Number(props.lon);
  } else {
    return null;
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;

  const osmId   = osmIdFromProps(props);
  const osmType = osmTypeFromProps(props);
  // @id yoksa fingerprint tabanlı source_id kullan (osmium config eksik)
  const sourceId = osmId ? `${osmType}/${osmId}` : null;

  const city     = norm(props['addr:city']     || props['addr:province']) || null;
  const district = norm(props['addr:district'] || props['addr:suburb'])   || null;

  const row = {
    name,
    category,
    phone:    norm(props.phone || props['contact:phone']) || null,
    address:  buildAddress(props),
    city,
    district,
    neighborhood: norm(props['addr:neighbourhood'] || props['addr:quarter']) || null,
    lat,
    lng,
    is_active: true,
    source:    'osm',
    reservation_url:     norm(props['reservation']) || null,
    order_yemeksepeti_url: null,
    order_trendyolgo_url:  null,
    order_getir_url:       null,
  };

  // fingerprint sonra hesaplanır (source_id fallback için gerekli)
  const fp = makeFingerprint(row);
  row.fingerprint = fp;
  // osmium @id yoksa (varsayılan config) fingerprint tabanlı source_id kullan
  row.source_id = sourceId ?? `fp/${fp}`;
  return row;
}

// ── Supabase upsert: özel bulk import RPC kullanır (trigger-safe, hızlı) ──
async function upsertBatch(supabase, rows) {
  // p_rows: JavaScript array — Supabase JS client JSONB serializasyonunu kendisi yapar
  const { error } = await supabase.rpc('import_osm_businesses_batch_v1', {
    p_rows: rows,
  });
  if (error) throw error;
}

// ── İlerleme kayıt/okuma ──────────────────────────────────────────────────
function loadState() {
  try {
    return JSON.parse(readFileSync(STATE_FILE, 'utf8'));
  } catch {
    return { processed: 0, imported: 0, skipped: 0, errors: 0 };
  }
}

function saveState(state) {
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

// ── Ana fonksiyon ─────────────────────────────────────────────────────────
async function main() {
  if (!existsSync(DOSYA)) {
    console.error(`❌ Dosya bulunamadı: ${DOSYA}`);
    console.error('   osmium ile önce dışa aktarın:');
    console.error('   osmium tags-filter turkey-260514.osm.pbf \\');
    console.error('     n/amenity=restaurant n/amenity=cafe n/amenity=bar \\');
    console.error('     n/amenity=fast_food n/amenity=food_court n/amenity=ice_cream \\');
    console.error('     n/shop=confectionery \\');
    console.error('     -o turkey-poi-yemek.osm.pbf');
    console.error('   osmium export turkey-poi-yemek.osm.pbf \\');
    console.error('     --geometry-types=point --output-format=geojsonseq \\');
    console.error('     -o turkey-poi-yemek.geojsonl');
    process.exit(1);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const state    = loadState();

  console.log(`📂 Dosya: ${DOSYA}`);
  console.log(`🔧 Dry-run: ${DRY_RUN} | Batch: ${BATCH_SIZE}`);
  if (state.processed > 0) {
    console.log(`🔄 Devam: ${state.processed} satır daha önce işlendi.`);
  }

  const rl = createInterface({
    input:     createReadStream(DOSYA),
    crlfDelay: Infinity,
  });

  let lineNo   = 0;
  let batch    = [];
  let seenFp   = new Set();  // in-memory dedup within current run
  let seenSrc  = new Set();

  const flush = async () => {
    if (!batch.length) return;
    if (!DRY_RUN) {
      try {
        await upsertBatch(supabase, batch);
        state.imported += batch.length;
      } catch (err) {
        state.errors += batch.length;
        console.error(`\n⚠️  Upsert hatası: ${err.message}`);
      }
    } else {
      state.imported += batch.length;
    }
    batch = [];
    process.stdout.write(
      `\r✅ İşlendi: ${state.processed.toLocaleString()} | ` +
      `Aktarıldı: ${state.imported.toLocaleString()} | ` +
      `Atlandı: ${state.skipped.toLocaleString()}`
    );
    saveState(state);
  };

  for await (const line of rl) {
    // osmium geojsonseq: her satır \x1e (RFC 7464 Record Separator) ile başlar
    const trimmed = line.replace(/^\x1e\s*/, '').trim();
    if (!trimmed || trimmed === ',' || trimmed === '[' || trimmed === ']') continue;

    // GeoJSONL: her satır bir Feature
    // FeatureCollection: opening/closing braces'i atla
    let feature;
    try {
      let json = trimmed;
      if (json.endsWith(',')) json = json.slice(0, -1);
      const parsed = JSON.parse(json);
      feature = parsed.type === 'Feature' ? parsed
               : parsed.type === 'FeatureCollection' ? null  // skip root
               : null;
    } catch {
      continue;
    }

    if (!feature) continue;
    lineNo++;
    state.processed++;

    const row = featureToRow(feature);
    if (!row) { state.skipped++; continue; }

    // Dedup within batch
    const srcKey = `${row.source}|${row.source_id}`;
    if (seenSrc.has(srcKey)) { state.skipped++; continue; }
    if (row.fingerprint && seenFp.has(row.fingerprint)) { state.skipped++; continue; }

    seenSrc.add(srcKey);
    if (row.fingerprint) seenFp.add(row.fingerprint);
    batch.push(row);

    if (batch.length >= BATCH_SIZE) await flush();
  }

  await flush();
  console.log('\n');
  console.log('─'.repeat(50));
  console.log(`Toplam işlenen satır : ${state.processed.toLocaleString()}`);
  console.log(`Aktarılan işletme    : ${state.imported.toLocaleString()}`);
  console.log(`Atlandı (filtre/dup) : ${state.skipped.toLocaleString()}`);
  console.log(`Hata                 : ${state.errors}`);
  console.log(DRY_RUN ? '🔵 Dry-run tamamlandı (veritabanına yazılmadı)' : '✅ Import tamamlandı!');
  saveState(state);
}

main().catch(err => {
  console.error('\n❌ Kritik hata:', err.message);
  process.exit(1);
});
