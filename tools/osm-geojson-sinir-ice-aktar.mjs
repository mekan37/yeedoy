/**
 * osm-geojson-sinir-ice-aktar.mjs
 * Türkiye OSM idari sınırlarını (il/ilçe/mahalle) Supabase'e aktarır.
 *
 * Kullanım:
 *   node tools/osm-geojson-sinir-ice-aktar.mjs --dosya=turkey-sinirlar.geojsonl
 *   node tools/osm-geojson-sinir-ice-aktar.mjs --dosya=turkey-sinirlar.geojsonl --level=6
 *   node tools/osm-geojson-sinir-ice-aktar.mjs --dosya=turkey-sinirlar.geojsonl --dry-run
 *   node tools/osm-geojson-sinir-ice-aktar.mjs --link-parents   (hiyerarşi kur)
 *   node tools/osm-geojson-sinir-ice-aktar.mjs --assign-businesses (işletkelere sınır ata)
 *
 * Osmium preprocessing:
 *   osmium tags-filter turkey-260514.osm.pbf \
 *     r/admin_level=4 r/admin_level=6 r/admin_level=8 \
 *     -o turkey-sinirlar.osm.pbf
 *   osmium export turkey-sinirlar.osm.pbf \
 *     --output-format=geojsonseq \
 *     -o turkey-sinirlar.geojsonl
 */

import 'dotenv/config';
import { createReadStream, existsSync, writeFileSync, readFileSync } from 'fs';
import { createInterface } from 'readline';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

// ── Ortam değişkenleri ────────────────────────────────────────────────────
const SUPABASE_URL              = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ .env içinde SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY gerekli.');
  process.exit(1);
}

// ── CLI argümanları ───────────────────────────────────────────────────────
const ARGS = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => { const [k, v] = a.slice(2).split('='); return [k, v ?? 'true']; })
);

const DOSYA            = ARGS.dosya || ARGS.file || './turkey-sinirlar.geojsonl';
const DRY_RUN          = ARGS['dry-run']          === 'true';
const LINK_PARENTS     = ARGS['link-parents']     === 'true';
const ASSIGN_BUSINESSES = ARGS['assign-businesses'] === 'true';
const BATCH_SIZE       = parseInt(ARGS.batch || '10');   // sınır geometrileri büyük
const LEVEL_FILTER     = ARGS.level ? parseInt(ARGS.level) : null; // sadece bu level
const STATE_FILE       = '.osm-sinir-state.json';

// ── Admin level filtreleme ────────────────────────────────────────────────
const ALLOWED_LEVELS = new Set([4, 6, 8]);

// ── Yardımcı ─────────────────────────────────────────────────────────────
function norm(v) { return (v ?? '').toString().trim(); }

function osmIdFromProps(props) {
  // osmium varsayılanda @id dahil etmez; config ile etkinleştirilmişse gelir
  const raw = norm(props['@id'] || props['@osmId'] || props.osm_id || '');
  if (!raw) return null;
  const parts = raw.split('/');
  const id = parseInt(parts[parts.length - 1], 10);
  return Number.isFinite(id) && id > 0 ? id : null;
}

function nameHashId(adminLevel, name) {
  // @id yoksa (osmium config eksik): admin_level+name'den deterministik negatif BIGINT
  const h = crypto.createHash('sha1').update(`${adminLevel}|${name}`).digest();
  const n = h.readUInt32BE(0);
  return -(n % 999999989); // negatif, gerçek OSM ID'lerle çakışmaz (pozitif)
}

function extractAdminLevel(props) {
  const raw = parseInt(norm(props.admin_level || props['admin_level']), 10);
  return Number.isFinite(raw) ? raw : null;
}

function featureToBoundaryRow(feature) {
  const props = feature.properties || {};
  const geom  = feature.geometry;

  const adminLevel = extractAdminLevel(props);
  if (!adminLevel || !ALLOWED_LEVELS.has(adminLevel)) return null;
  if (LEVEL_FILTER !== null && adminLevel !== LEVEL_FILTER) return null;

  const name = norm(props.name || props['name:tr']);
  if (!name) return null;

  const realOsmId = osmIdFromProps(props);
  // @id yoksa name+level hash kullan (negatif = hash tabanlı, gerçek OSM ID'den ayırt edilir)
  const osmId = realOsmId ?? nameHashId(adminLevel, name);

  // Geometri: GeoJSON string olarak sakla (import_osm_boundaries_batch_v1 çevirir)
  let geojsonStr = null;
  if (geom && (geom.type === 'Polygon' || geom.type === 'MultiPolygon')) {
    geojsonStr = JSON.stringify(geom);
  }

  const properties = {};
  const keepKeys = [
    'name:tr','name:en','name:ar','name:ku','ISO3166-2',
    'ref','boundary','type','wikidata','wikipedia',
    'addr:city','addr:district','population',
  ];
  for (const k of keepKeys) {
    if (props[k]) properties[k] = props[k];
  }

  return {
    osm_id:      osmId,
    admin_level: adminLevel,
    name,
    name_en:     norm(props['name:en']) || null,
    geojson:     geojsonStr,
    properties,
  };
}

// ── State management ──────────────────────────────────────────────────────
function loadState() {
  try { return JSON.parse(readFileSync(STATE_FILE, 'utf8')); }
  catch { return { processed: 0, imported: 0, skipped: 0, errors: 0 }; }
}
function saveState(state) {
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

// ── Ana import ────────────────────────────────────────────────────────────
async function importBoundaries(supabase) {
  if (!existsSync(DOSYA)) {
    console.error(`❌ Dosya bulunamadı: ${DOSYA}`);
    console.error('   Önce osmium ile sınırları çıkarın:');
    console.error('   osmium tags-filter turkey-260514.osm.pbf \\');
    console.error('     r/admin_level=4 r/admin_level=6 r/admin_level=8 \\');
    console.error('     -o turkey-sinirlar.osm.pbf');
    console.error('   osmium export turkey-sinirlar.osm.pbf \\');
    console.error('     --output-format=geojsonseq -o turkey-sinirlar.geojsonl');
    process.exit(1);
  }

  const state = loadState();
  console.log(`📂 Dosya: ${DOSYA}`);
  console.log(`🔧 Dry-run: ${DRY_RUN} | Batch: ${BATCH_SIZE}${LEVEL_FILTER ? ` | Level: ${LEVEL_FILTER}` : ''}`);

  const rl = createInterface({
    input:     createReadStream(DOSYA),
    crlfDelay: Infinity,
  });

  let batch = [];

  const flush = async () => {
    if (!batch.length) return;
    if (!DRY_RUN) {
      try {
        const { data, error } = await supabase.rpc('import_osm_boundaries_batch_v1', {
          p_rows: batch,
        });
        if (error) throw error;
        state.imported += batch.length;
      } catch (err) {
        state.errors += batch.length;
        console.error(`\n⚠️  Batch hatası (${batch.length} sınır): ${err.message}`);
        // Her sınırı ayrı ayrı dene
        for (const row of batch) {
          try {
            const { error: e2 } = await supabase.rpc('import_osm_boundaries_batch_v1', {
              p_rows: [row],
            });
            if (e2) {
              console.error(`    Hata: ${row.name} (osm_id=${row.osm_id}): ${e2.message}`);
              state.errors++;
            } else {
              state.imported++;
            }
          } catch (e3) {
            state.errors++;
            console.error(`    Kritik: ${row.name}: ${e3.message}`);
          }
        }
      }
    } else {
      state.imported += batch.length;
    }
    batch = [];
    process.stdout.write(
      `\r✅ İşlendi: ${state.processed} | Aktarıldı: ${state.imported} | Hata: ${state.errors}`
    );
    saveState(state);
  };

  for await (const line of rl) {
    // osmium geojsonseq: her satır \x1e (RFC 7464 Record Separator) ile başlar
    const trimmed = line.replace(/^\x1e\s*/, '').trim();
    if (!trimmed || trimmed === ',' || trimmed === '[' || trimmed === ']') continue;

    let feature;
    try {
      let json = trimmed;
      if (json.endsWith(',')) json = json.slice(0, -1);
      const parsed = JSON.parse(json);
      feature = parsed.type === 'Feature' ? parsed : null;
    } catch {
      continue;
    }

    if (!feature) continue;
    state.processed++;

    const row = featureToBoundaryRow(feature);
    if (!row) { state.skipped++; continue; }

    batch.push(row);
    if (batch.length >= BATCH_SIZE) await flush();
  }

  await flush();
  console.log('\n');
  console.log('─'.repeat(50));
  console.log(`Toplam feature       : ${state.processed.toLocaleString()}`);
  console.log(`Aktarılan sınır      : ${state.imported.toLocaleString()}`);
  console.log(`Atlandı              : ${state.skipped.toLocaleString()}`);
  console.log(`Hata                 : ${state.errors}`);
  console.log(DRY_RUN ? '🔵 Dry-run tamamlandı' : '✅ Sınır import tamamlandı!');
  saveState(state);
}

// ── Ebeveyn bağlantısı ────────────────────────────────────────────────────
async function linkParents(supabase) {
  console.log('🔗 Sınır hiyerarşisi kuruluyor (il→ilçe→mahalle)...');
  const { data, error } = await supabase.rpc('link_osm_boundary_parents_v1');
  if (error) {
    console.error('❌ link_osm_boundary_parents_v1 hatası:', error.message);
    process.exit(1);
  }
  console.log(`✅ ${data} bağlantı kuruldu.`);
}

// ── İşletme sınır ataması ─────────────────────────────────────────────────
async function assignBusinesses(supabase) {
  console.log('🏪 İşletkelere mahalle/ilçe sınırı atanıyor...');
  let total = 0;
  let round = 0;
  while (true) {
    round++;
    const { data, error } = await supabase.rpc('assign_all_businesses_to_boundaries_v1', {
      p_batch: 500,
    });
    if (error) {
      console.error('❌ assign_all_businesses_to_boundaries_v1 hatası:', error.message);
      break;
    }
    total += data || 0;
    process.stdout.write(`\r   Tur ${round}: ${total.toLocaleString()} işletme atandı`);
    if (!data || data === 0) break;
  }
  console.log(`\n✅ Toplam ${total.toLocaleString()} işletmeye sınır atandı.`);
}

// ── Main ──────────────────────────────────────────────────────────────────
async function main() {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  if (LINK_PARENTS) {
    await linkParents(supabase);
    return;
  }

  if (ASSIGN_BUSINESSES) {
    await assignBusinesses(supabase);
    return;
  }

  await importBoundaries(supabase);
}

main().catch(err => {
  console.error('\n❌ Kritik hata:', err.message);
  process.exit(1);
});
