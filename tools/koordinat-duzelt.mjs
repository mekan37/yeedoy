/**
 * koordinat-duzelt.mjs
 *
 * ilce-koordinatlari.json'daki yanlış/eksik koordinatları Overpass admin
 * boundary sorgusuyla düzeltir.
 *
 * Strateji: Her il için Overpass'tan admin_level=6 boundary relationları
 * tek sorguda çeker; JSON'daki her ilçeyi OSM adıyla eşleştirir ve bbox +
 * center'ı günceller. İlerleme dosyasıyla kaldığı yerden devam eder.
 *
 * Kullanım:
 *   node tools/koordinat-duzelt.mjs
 *   node tools/koordinat-duzelt.mjs --reset
 *   node tools/koordinat-duzelt.mjs --dry-run   (yazmadan göster)
 */

import fs from 'fs';

const ILCE_JSON = './veri_json/ilce-koordinatlari.json';
const OUTPUT_JSON = './veri_json/ilce-koordinatlari-duzeltilmis.json';
const PROGRESS_FILE = './veri_json/.koordinat-duzelt-progress.json';
const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';
const DELAY_MS = 3000;
const OVERPASS_TIMEOUT = 60;

const resetFlag = process.argv.includes('--reset');
const dryRun = process.argv.includes('--dry-run');

// ── Türkçe normalize (büyük/küçük harf, aksan) ───────────────────────────────

const TR_LOWER = { 'İ': 'i', 'I': 'ı', 'Ğ': 'ğ', 'Ü': 'ü', 'Ş': 'ş', 'Ö': 'ö', 'Ç': 'ç' };
const TR_UPPER = { 'i': 'İ', 'ı': 'I', 'ğ': 'Ğ', 'ü': 'Ü', 'ş': 'Ş', 'ö': 'Ö', 'ç': 'Ç' };

function trLower(s) {
  return (s ?? '').split('').map(c => TR_LOWER[c] ?? c.toLowerCase()).join('');
}

function normName(s) {
  return trLower(s ?? '').replace(/\s+/g, ' ').trim();
}

// İl adının OSM'deki karşılığı (bazı iller JSON'da ve OSM'de farklı yazılıyor)
const IL_OSM_ADI = {
  'AFYONKARAHİSAR': 'Afyonkarahisar',
  'KAHRAMANMARAŞ': 'Kahramanmaraş',
  'K.MARAŞ': 'Kahramanmaraş',
  'ŞANLIURFA': 'Şanlıurfa',
  'İSTANBUL': 'İstanbul',
  'ÇANAKKALE': 'Çanakkale',
  'ERZURUM': 'Erzurum',
};

function ilOsmAdi(sehir_adi) {
  if (IL_OSM_ADI[sehir_adi]) return IL_OSM_ADI[sehir_adi];
  // Titlecase TR
  return sehir_adi.split(' ')
    .map(w => (TR_UPPER[w[0]] ?? w[0].toUpperCase()) + trLower(w.slice(1)))
    .join(' ');
}

function ilceOsmAdi(ilce_adi) {
  return ilce_adi.split(' ')
    .map(w => (TR_UPPER[w[0]] ?? w[0].toUpperCase()) + trLower(w.slice(1)))
    .join(' ');
}

// ── Overpass ──────────────────────────────────────────────────────────────────

async function fetchOverpass(query, retries = 3) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const ctrl = new AbortController();
      const t = setTimeout(() => ctrl.abort(), (OVERPASS_TIMEOUT + 15) * 1000);
      let res;
      try {
        res = await fetch(OVERPASS_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json, */*',
            'User-Agent': 'YeedoyKoordinatDuzelt/1.0',
          },
          body: `data=${encodeURIComponent(query)}`,
          signal: ctrl.signal,
        });
      } finally {
        clearTimeout(t);
      }
      if (res.status === 429 || res.status === 503) {
        const wait = attempt * 20000;
        process.stdout.write(`⏳ ${wait / 1000}s... `);
        await sleep(wait);
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      return json.elements ?? [];
    } catch (err) {
      if (err.name === 'AbortError') {
        if (attempt < retries) { await sleep(8000 * attempt); continue; }
        throw new Error('Overpass timeout');
      }
      if (attempt === retries) throw err;
      await sleep(6000 * attempt);
    }
  }
  return [];
}

// İl admin_level=6 sınırlarını çek
async function fetchIlDistricts(ilAdi) {
  const query = `[out:json][timeout:${OVERPASS_TIMEOUT}];
area["name"="${ilAdi}"]["admin_level"="4"]["boundary"="administrative"]->.il;
relation["admin_level"="6"]["boundary"="administrative"](area.il);
out bb tags;`;
  return fetchOverpass(query);
}

// ── İlçe eşleştirme ───────────────────────────────────────────────────────────

function bboxCenter(bb) {
  return {
    lat: (bb.minlat + bb.maxlat) / 2,
    lon: (bb.minlon + bb.maxlon) / 2,
  };
}

function matchDistrict(ilce_adi, osmRelations) {
  const target = normName(ilce_adi);

  // 1) tam eşleşme: tags.name
  for (const rel of osmRelations) {
    const n = normName(rel.tags?.name ?? '');
    if (n === target) return rel;
  }

  // 2) tam eşleşme: tags['name:tr']
  for (const rel of osmRelations) {
    const n = normName(rel.tags?.['name:tr'] ?? '');
    if (n === target) return rel;
  }

  // 3) ilçe adı olmaksızın soyulmuş eşleşme (ör. "Merkez İlçesi" → "merkez")
  const targetStripped = target.replace(/ ilçesi$/, '').replace(/ merkezi$/, '');
  for (const rel of osmRelations) {
    const n = normName(rel.tags?.name ?? '').replace(/ ilçesi$/, '');
    if (n === targetStripped) return rel;
  }

  // 4) starts-with (kısaltma/yazım farkı)
  for (const rel of osmRelations) {
    const n = normName(rel.tags?.name ?? '');
    if (n.startsWith(targetStripped) || targetStripped.startsWith(n)) return rel;
  }

  return null;
}

// ── progress ──────────────────────────────────────────────────────────────────

function loadProgress() {
  try {
    if (fs.existsSync(PROGRESS_FILE)) return JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf8'));
  } catch {}
  return { completedCities: [], cityResults: {} };
}

function saveProgress(p) { fs.writeFileSync(PROGRESS_FILE, JSON.stringify(p, null, 2)); }

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ── main ──────────────────────────────────────────────────────────────────────

async function main() {
  const data = JSON.parse(fs.readFileSync(ILCE_JSON, 'utf8'));
  const districts = data.out;

  if (resetFlag && fs.existsSync(PROGRESS_FILE)) {
    fs.unlinkSync(PROGRESS_FILE);
    console.log('🔄 İlerleme sıfırlandı.\n');
  }

  // İl bazında gruplama
  const bySehir = {};
  for (const d of districts) {
    if (!bySehir[d.sehir_adi]) bySehir[d.sehir_adi] = [];
    bySehir[d.sehir_adi].push(d);
  }
  const sehirler = Object.keys(bySehir);
  console.log(`🏙️  Toplam il: ${sehirler.length} | İlçe: ${districts.length}`);

  const progress = loadProgress();
  const completedSet = new Set(progress.completedCities);
  const pending = sehirler.filter(s => !completedSet.has(s));

  console.log(`✅ Tamamlanan: ${completedSet.size} | ⏳ Bekleyen: ${pending.length}`);

  if (pending.length === 0) {
    console.log('\n🎉 Tüm iller zaten tarandı! Çıktı dosyası oluşturuluyor...');
    buildOutput(data, progress.cityResults);
    return;
  }

  let stats = { fixed: 0, notFound: 0, ok: 0 };

  for (let i = 0; i < pending.length; i++) {
    const sehir = pending[i];
    const osmAdi = ilOsmAdi(sehir);
    process.stdout.write(`[${completedSet.size + i + 1}/${sehirler.length}] ${sehir} (${osmAdi}) ... `);

    try {
      const relations = await fetchIlDistricts(osmAdi);

      if (relations.length === 0) {
        process.stdout.write(`⚠️ OSM'de il bulunamadı (${relations.length} relation)\n`);
        progress.cityResults[sehir] = {};
        progress.completedCities.push(sehir);
        saveProgress(progress);
        await sleep(DELAY_MS);
        continue;
      }

      const cityResult = {};
      const ilceler = bySehir[sehir];

      let fixed = 0, notFound = 0, ok = 0;

      for (const d of ilceler) {
        const rel = matchDistrict(d.ilce_adi, relations);
        if (!rel || !rel.bounds) {
          notFound++;
          cityResult[d.ilce_id] = null; // not found
          continue;
        }

        const newBbox = {
          south: rel.bounds.minlat,
          west: rel.bounds.minlon,
          north: rel.bounds.maxlat,
          east: rel.bounds.maxlon,
        };
        const newCenter = bboxCenter(rel.bounds);
        const newNominatim = {
          display_name: rel.tags?.name ?? d.nominatim?.display_name,
          osm_type: 'relation',
          osm_id: rel.id,
          class: 'boundary',
          type: 'administrative',
        };

        const oldArea = (d.bbox.north - d.bbox.south) * (d.bbox.east - d.bbox.west);
        const newArea = (newBbox.north - newBbox.south) * (newBbox.east - newBbox.west);

        if (Math.abs(newArea - oldArea) / Math.max(oldArea, 0.001) > 0.1) {
          fixed++;
          cityResult[d.ilce_id] = { bbox: newBbox, center: newCenter, nominatim: newNominatim };
        } else {
          ok++;
          cityResult[d.ilce_id] = { bbox: newBbox, center: newCenter, nominatim: newNominatim };
        }
      }

      process.stdout.write(`✅ ${relations.length} rel | düzeltilen: ${fixed} | bulunamayan: ${notFound} | ok: ${ok}\n`);
      stats.fixed += fixed;
      stats.notFound += notFound;
      stats.ok += ok;

      progress.cityResults[sehir] = cityResult;
      progress.completedCities.push(sehir);
      saveProgress(progress);

    } catch (err) {
      process.stdout.write(`❌ ${err.message}\n`);
    }

    if (i < pending.length - 1) await sleep(DELAY_MS);
  }

  // Tüm iller tamamlandıysa çıktı oluştur
  const remaining = pending.length - sehirler.filter(s => !new Set(progress.completedCities).has(s)).length;

  console.log('\n─────────────────────────────────────────');
  console.log(`📊 Düzeltilen: ${stats.fixed} | Bulunamayan: ${stats.notFound} | Onaylanan: ${stats.ok}`);

  if (new Set(progress.completedCities).size >= sehirler.length) {
    buildOutput(data, progress.cityResults);
  } else {
    console.log(`\n⏩ Kalan iller için tekrar çalıştırın.`);
  }
}

function buildOutput(data, cityResults) {
  const updated = JSON.parse(JSON.stringify(data));
  let totalFixed = 0, totalNotFound = 0;

  for (const d of updated.out) {
    const cityRes = cityResults[d.sehir_adi];
    if (!cityRes) continue;
    const entry = cityRes[d.ilce_id];
    if (entry === null) {
      totalNotFound++;
      continue;
    }
    if (!entry) continue;

    const oldArea = (d.bbox.north - d.bbox.south) * (d.bbox.east - d.bbox.west);
    const newArea = (entry.bbox.north - entry.bbox.south) * (entry.bbox.east - entry.bbox.west);

    if (Math.abs(newArea - oldArea) / Math.max(oldArea, 0.001) > 0.05) totalFixed++;

    d.bbox = entry.bbox;
    d.center = entry.center;
    d.nominatim = entry.nominatim;
  }

  if (!dryRun) {
    updated.generatedAt = new Date().toISOString();
    updated.fixedBy = 'koordinat-duzelt.mjs';
    fs.writeFileSync(OUTPUT_JSON, JSON.stringify(updated, null, 2));
    console.log(`\n✅ Çıktı: ${OUTPUT_JSON}`);
    console.log(`   Güncellenen: ${totalFixed} | OSM'de bulunamayan: ${totalNotFound}`);
    console.log('\nKullanıma almak için:');
    console.log('  copy veri_json\\ilce-koordinatlari-duzeltilmis.json veri_json\\ilce-koordinatlari.json');
  } else {
    console.log(`\n[DRY-RUN] Güncellenen: ${totalFixed} | Bulunamayan: ${totalNotFound}`);
    console.log('[DRY-RUN] Dosyaya yazılmadı.');
  }
}

main().catch(err => {
  console.error('\n❌ Script hatası:', err.message);
  process.exit(1);
});
