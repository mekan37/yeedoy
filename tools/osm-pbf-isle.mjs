/**
 * osm-pbf-isle.mjs — OSM PBF import orkestratörü
 *
 * Aşama 1: osmium-tool ile PBF'den POI ve sınır filtreler
 * Aşama 2: Filtrelenmiş GeoJSONL dosyalarını Supabase'e aktarır
 * Aşama 3: Sınır hiyerarşisi ve işletme ataması
 *
 * Kullanım:
 *   node tools/osm-pbf-isle.mjs --pbf=turkey-260514.osm.pbf
 *   node tools/osm-pbf-isle.mjs --pbf=turkey-260514.osm.pbf --sadece=poi
 *   node tools/osm-pbf-isle.mjs --pbf=turkey-260514.osm.pbf --sadece=sinir
 *   node tools/osm-pbf-isle.mjs --sadece=ata-sinir
 *   node tools/osm-pbf-isle.mjs --dry-run --pbf=turkey-260514.osm.pbf
 *
 * Gereksinimler:
 *   - osmium-tool yüklü olmalı (aşağıda kurulum talimatları)
 *   - .env dosyasında SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY
 */

import { execSync, spawnSync } from 'child_process';
import { existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ── CLI argümanları ───────────────────────────────────────────────────────
const ARGS = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => { const [k, v] = a.slice(2).split('='); return [k, v ?? 'true']; })
);

const PBF_DOSYA  = ARGS.pbf   || 'turkey-260514.osm.pbf';
const SADECE     = ARGS.sadece || 'hepsi';   // hepsi | poi | sinir | ata-sinir
const DRY_RUN    = ARGS['dry-run'] === 'true';
const SKIP_OSMIUM = ARGS['skip-osmium'] === 'true'; // osmium adımını atla

// ── Çıktı dosyaları ───────────────────────────────────────────────────────
const POI_PBF       = 'turkey-poi-yemek.osm.pbf';
const POI_GEOJSONL  = 'turkey-poi-yemek.geojsonl';
const SINIR_PBF     = 'turkey-sinirlar.osm.pbf';
const SINIR_GEOJSONL = 'turkey-sinirlar.geojsonl';

// ── osmium kontrolü ───────────────────────────────────────────────────────
function checkOsmium() {
  const result = spawnSync('osmium', ['version'], { encoding: 'utf8' });
  if (result.error || result.status !== 0) {
    console.error('❌ osmium-tool bulunamadı!');
    console.error('');
    console.error('Kurulum talimatları:');
    console.error('  Windows (Chocolatey) : choco install osmium-tool');
    console.error('  Windows (WSL)        : sudo apt install osmium-tool');
    console.error('  macOS                : brew install osmium-tool');
    console.error('  Ubuntu/Debian        : sudo apt install osmium-tool');
    console.error('');
    console.error('Alternatif: Önceden oluşturulmuş GeoJSONL dosyaları varsa');
    console.error('  --skip-osmium bayrağı ile osmium adımını atlayabilirsiniz.');
    process.exit(1);
  }
  const version = (result.stdout || '').trim().split('\n')[0];
  console.log(`✅ osmium-tool: ${version}`);
}

// ── Shell komut çalıştır ──────────────────────────────────────────────────
function run(cmd, desc) {
  console.log(`\n🔧 ${desc}`);
  console.log(`   $ ${cmd}`);
  if (DRY_RUN) {
    console.log('   (dry-run: atlandı)');
    return;
  }
  try {
    execSync(cmd, { stdio: 'inherit' });
  } catch (err) {
    console.error(`❌ Hata: ${desc}`);
    process.exit(1);
  }
}

// ── Node.js script çalıştır ───────────────────────────────────────────────
function runNode(script, args = '') {
  const fullArgs = args + (DRY_RUN ? ' --dry-run' : '');
  run(`node "${resolve(__dirname, script)}" ${fullArgs}`, `${script} ${args}`);
}

// ── Aşama 1: POI filtreleme ───────────────────────────────────────────────
function filterPOIs() {
  if (!existsSync(PBF_DOSYA)) {
    console.error(`❌ PBF dosyası bulunamadı: ${PBF_DOSYA}`);
    console.error('   --pbf=<dosya-yolu> ile belirtin.');
    process.exit(1);
  }

  console.log('\n━━━ Aşama 1: POI Filtreleme ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  run(
    `osmium tags-filter "${PBF_DOSYA}" ` +
    `n/amenity=restaurant n/amenity=cafe n/amenity=bar n/amenity=pub ` +
    `n/amenity=fast_food n/amenity=food_court n/amenity=ice_cream ` +
    `n/amenity=nightclub n/shop=confectionery ` +
    `-o "${POI_PBF}" --overwrite`,
    'POI filtreleme (yemek/içecek node\'ları)'
  );

  run(
    `osmium export "${POI_PBF}" ` +
    `--geometry-types=point --output-format=geojsonseq ` +
    `--config "${resolve(__dirname, 'osmium-export-config.json')}" ` +
    `-o "${POI_GEOJSONL}" --overwrite`,
    'POI → GeoJSONL dönüşümü (ID dahil)'
  );
}

// ── Aşama 2: Sınır filtreleme ─────────────────────────────────────────────
function filterBoundaries() {
  console.log('\n━━━ Aşama 2: Sınır Filtreleme ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  run(
    `osmium tags-filter "${PBF_DOSYA}" ` +
    `r/admin_level=4 r/admin_level=6 r/admin_level=8 ` +
    `-o "${SINIR_PBF}" --overwrite`,
    'İdari sınır filtreleme (il/ilçe/mahalle relations, member way+node dahil)'
  );

  run(
    `osmium export "${SINIR_PBF}" ` +
    `--output-format=geojsonseq ` +
    `--geometry-types=polygon,multipolygon ` +
    `--config "${resolve(__dirname, 'osmium-export-config.json')}" ` +
    `-o "${SINIR_GEOJSONL}" --overwrite`,
    'Sınırlar → GeoJSONL dönüşümü (ID dahil)'
  );
}

// ── Aşama 3: Supabase import ──────────────────────────────────────────────
function importPOIs() {
  console.log('\n━━━ Aşama 3: POI Import ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  runNode('osm-geojson-poi-ice-aktar.mjs', `--dosya="${POI_GEOJSONL}"`);
}

function importBoundaries() {
  console.log('\n━━━ Aşama 3: Sınır Import ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  runNode('osm-geojson-sinir-ice-aktar.mjs', `--dosya="${SINIR_GEOJSONL}"`);
}

function linkAndAssign() {
  console.log('\n━━━ Aşama 4: Hiyerarşi + İşletme Ataması ━━━━━━━━━━━━━━━━━━');
  console.log('   ⚠️  Bu aşama için migration\'ların uygulanmış olması gerekir.');
  console.log('   Migration uygulanmadıysa: supabase db push');
  runNode('osm-geojson-sinir-ice-aktar.mjs', '--link-parents');
  runNode('osm-geojson-sinir-ice-aktar.mjs', '--assign-businesses');
}

// ── Main ──────────────────────────────────────────────────────────────────
async function main() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('   🗺️  Yeedoy OSM PBF İmport Sistemi');
  console.log('═══════════════════════════════════════════════════════════');
  console.log(`PBF dosyası : ${PBF_DOSYA}`);
  console.log(`Mod         : ${SADECE}`);
  console.log(`Dry-run     : ${DRY_RUN}`);
  console.log('');

  if (SADECE === 'ata-sinir') {
    linkAndAssign();
    return;
  }

  if (!SKIP_OSMIUM) checkOsmium();

  if (SADECE === 'poi' || SADECE === 'hepsi') {
    if (!SKIP_OSMIUM) filterPOIs();
    importPOIs();
  }

  if (SADECE === 'sinir' || SADECE === 'hepsi') {
    if (!SKIP_OSMIUM) filterBoundaries();
    importBoundaries();
    linkAndAssign();
  }

  console.log('\n═══════════════════════════════════════════════════════════');
  console.log('   ✅ Tüm aşamalar tamamlandı!');
  console.log('═══════════════════════════════════════════════════════════');
  console.log('');
  console.log('Sonraki adımlar:');
  console.log('  1. Migrationları uygulayın: supabase db push');
  console.log('  2. Yakın arama: supabase.rpc("nearby_businesses_v2", {p_lat, p_lng})');
  console.log('  3. Sınır arama: supabase.rpc("get_businesses_in_boundary_v1", {p_boundary_id})');
  console.log('  4. İstatistik : supabase.rpc("get_boundary_stats_v1", {p_admin_level: 6})');
}

main().catch(err => {
  console.error('\n❌ Kritik hata:', err.message);
  process.exit(1);
});
