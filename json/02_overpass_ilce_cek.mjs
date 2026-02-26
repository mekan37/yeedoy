import fs from "node:fs/promises";
import path from "node:path";

const COORDS_FILE = "./ilce_kordinatlar.json";
const OUT_DIR = "./out_overpass";

const OVERPASS_ENDPOINTS = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
  "https://overpass.nchc.org.tw/api/interpreter",
];

const USER_AGENT = "yeedoy-overpass/1.1 (contact: mustafa@baskentgrupecza.com.tr)";

// Overpass nazik kullanÄ±m
const BASE_DELAY_MS = 1300;

// Retry ayarlarÄ±
const MAX_TRIES_PER_ENDPOINT = 3;

// EÄŸer bbox Ã§ok bÃ¼yÃ¼kse bunu uygula (km)
const MAX_BBOX_AREA_DEG2 = 0.20; // yaklaÅŸÄ±k eÅŸik (bÃ¼yÃ¼k ilÃ§elerde patlÄ±yor)
const SHRINK_RADIUS_KM = 15;     // centerâ€™dan 15km bbox yap

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function safeSlug(s) {
  return String(s)
    .toLowerCase()
    .replaceAll("Ä±", "i")
    .replaceAll("ÄŸ", "g")
    .replaceAll("Ã¼", "u")
    .replaceAll("ÅŸ", "s")
    .replaceAll("Ã¶", "o")
    .replaceAll("Ã§", "c")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

function bboxAreaDeg2(b) {
  const w = Math.abs(b.east - b.west);
  const h = Math.abs(b.north - b.south);
  return w * h;
}

// km -> derece yaklaÅŸÄ±k (lat iÃ§in)
function kmToLatDeg(km) {
  return km / 111.0;
}

// km -> derece yaklaÅŸÄ±k (lon iÃ§in, latitudeâ€™a gÃ¶re)
function kmToLonDeg(km, lat) {
  const rad = (lat * Math.PI) / 180;
  const kmPerDeg = 111.320 * Math.cos(rad);
  return km / Math.max(kmPerDeg, 1e-6);
}

function shrinkBboxAroundCenter(original, center, radiusKm) {
  const dLat = kmToLatDeg(radiusKm);
  const dLon = kmToLonDeg(radiusKm, center.lat);
  return {
    south: center.lat - dLat,
    north: center.lat + dLat,
    west: center.lon - dLon,
    east: center.lon + dLon,
  };
}

function buildOverpassQuery(bbox) {
  const { south, west, north, east } = bbox;

  // timeoutâ€™u yÃ¼kselttim: 180
  return `[out:json][timeout:180];
(
  nwr(${south},${west},${north},${east})["amenity"~"^(restaurant|cafe|bar|pub|nightclub|ice_cream)$"];
  nwr(${south},${west},${north},${east})["shop"="confectionery"];
  nwr(${south},${west},${north},${east})["amenity"="restaurant"]["cuisine"~"seafood|fish|steak|kebab|bbq|barbecue|meat|breakfast|brunch|dessert",i];
  nwr(${south},${west},${north},${east})["amenity"="cafe"]["cuisine"~"breakfast|brunch|dessert|patisserie",i];
  nwr(${south},${west},${north},${east})["live_music"="yes"];
);
out center tags;`;
}

async function postOverpass(endpoint, query) {
  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
      "User-Agent": USER_AGENT,
    },
    body: new URLSearchParams({ data: query }).toString(),
  });

  // Overpass bazen HTML hata basÄ±yor; text alÄ±p kontrol edelim
  const text = await res.text();

  if (!res.ok) {
    // 504 vs: textâ€™i kÄ±saltÄ±p hata ver
    throw new Error(`HTTP ${res.status} ${res.statusText} :: ${text.slice(0, 250)}`);
  }

  // JSON parse
  try {
    return JSON.parse(text);
  } catch (e) {
    throw new Error(`Invalid JSON from Overpass (${endpoint}) :: ${text.slice(0, 250)}`);
  }
}

async function fetchWithFailover(query) {
  let lastErr;

  for (const endpoint of OVERPASS_ENDPOINTS) {
    for (let attempt = 1; attempt <= MAX_TRIES_PER_ENDPOINT; attempt++) {
      try {
        return { endpoint, data: await postOverpass(endpoint, query) };
      } catch (e) {
        lastErr = e;

        const msg = String(e.message || e);
        const isRetryable =
          msg.includes("HTTP 504") ||
          msg.includes("HTTP 429") ||
          msg.includes("HTTP 502") ||
          msg.includes("HTTP 503") ||
          msg.includes("timeout") ||
          msg.includes("Invalid JSON");

        if (!isRetryable) throw e;

        // backoff
        const wait = 1200 * Math.pow(2, attempt - 1);
        console.log(`  ! retry (${endpoint}) attempt ${attempt}/${MAX_TRIES_PER_ENDPOINT} â†’ ${wait}ms`);
        await sleep(wait);
      }
    }

    console.log(`  ! endpoint deÄŸiÅŸtiriliyor â†’ ${endpoint} baÅŸarÄ±sÄ±z`);
    await sleep(1500);
  }

  throw lastErr;
}

async function run() {
  await fs.mkdir(OUT_DIR, { recursive: true });

  const coords = JSON.parse(await fs.readFile(COORDS_FILE, "utf8"));
  const districts = coords.out || [];
  const index = [];

  for (const d of districts) {
    const { sehir_id, sehir_adi, ilce_id, ilce_adi, bbox, center } = d;
    if (!bbox) continue;

    // bbox Ã§ok bÃ¼yÃ¼kse kÃ¼Ã§Ã¼lt
    let bboxToUse = bbox;
    const area = bboxAreaDeg2(bbox);
    if (area > MAX_BBOX_AREA_DEG2 && center?.lat && center?.lon) {
      bboxToUse = shrinkBboxAroundCenter(bbox, { lat: center.lat, lon: center.lon }, SHRINK_RADIUS_KM);
      console.log(`\nâ–¶ Overpass: ${sehir_adi} / ${ilce_adi} (BBOX shrink: area=${area.toFixed(3)} â†’ radius=${SHRINK_RADIUS_KM}km)`);
    } else {
      console.log(`\nâ–¶ Overpass: ${sehir_adi} / ${ilce_adi}`);
    }

    const query = buildOverpassQuery(bboxToUse);

    try {
      const { endpoint, data } = await fetchWithFailover(query);

      const base = `${safeSlug(sehir_adi)}__${safeSlug(ilce_adi)}__${sehir_id}_${ilce_id}`;
      const outFile = path.join(OUT_DIR, `${base}.json`);

      const wrapped = {
        meta: {
          sehir_id, sehir_adi, ilce_id, ilce_adi,
          bbox_used: bboxToUse,
          bbox_original: bbox,
          fetchedAt: new Date().toISOString(),
          endpoint,
          elementsCount: data?.elements?.length ?? 0,
        },
        overpass: data,
      };

      await fs.writeFile(outFile, JSON.stringify(wrapped, null, 2), "utf8");
      console.log(`  âœ“ ${wrapped.meta.elementsCount} element â†’ ${outFile}`);

      index.push({ ...wrapped.meta, file: outFile });
    } catch (e) {
      console.log(`  âŒ baÅŸarÄ±sÄ±z: ${String(e.message || e).slice(0, 200)}`);
      index.push({
        sehir_id, sehir_adi, ilce_id, ilce_adi,
        ok: false,
        error: String(e.message || e),
        fetchedAt: new Date().toISOString(),
      });
    }

    await sleep(BASE_DELAY_MS);
  }

  await fs.writeFile(path.join(OUT_DIR, `_index.json`), JSON.stringify(index, null, 2), "utf8");
  console.log(`\nâœ… Bitti. Index: ${path.join(OUT_DIR, `_index.json`)}`);
}

run().catch((e) => {
  console.error("âŒ", e);
  process.exit(1);
});

