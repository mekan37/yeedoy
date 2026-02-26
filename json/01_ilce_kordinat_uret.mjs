import fs from "node:fs/promises";

const ILCELER_FILE = "./ilceler.json";
const OUT_FILE = "./ilce_kordinatlar.json";

const NOMINATIM_ENDPOINT = "https://nominatim.openstreetmap.org/search";
const USER_AGENT = "yeedoy-ilce-bbox/1.0 (contact: you@example.com)";

const BASE_DELAY_MS = 1300;
const MAX_TRIES_PER_ENDPOINT = 3;

// Bbox Ã§ok bÃ¼yÃ¼kse radius fallback devreye girsin:
const MAX_BBOX_AREA_DEG2 = 0.20;

// 0 element olursa sÄ±rayla bunlarÄ± dene:
const RADIUS_FALLBACK_KM = [15, 25, 40, 60]; // istersen bÃ¼yÃ¼t
// HÃ¢lÃ¢ 0 ise en son orijinal bboxâ€™Ä± dene:
const TRY_ORIGINAL_BBOX_LAST = true;

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

function kmToLatDeg(km) {
  return km / 111.0;
}

function kmToLonDeg(km, lat) {
  const rad = (lat * Math.PI) / 180;
  const kmPerDeg = 111.320 * Math.cos(rad);
  return km / Math.max(kmPerDeg, 1e-6);
}

function bboxAroundCenter(center, radiusKm) {
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

  const text = await res.text();

  if (!res.ok) {
    throw new Error(`HTTP ${res.status} ${res.statusText} :: ${text.slice(0, 250)}`);
  }

  try {
    return JSON.parse(text);
  } catch {
    throw new Error(`Invalid JSON from Overpass (${endpoint}) :: ${text.slice(0, 250)}`);
  }
}

async function fetchWithFailover(query) {
  let lastErr;

  for (const endpoint of OVERPASS_ENDPOINTS) {
    for (let attempt = 1; attempt <= MAX_TRIES_PER_ENDPOINT; attempt++) {
      try {
        const data = await postOverpass(endpoint, query);
        return { endpoint, data };
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

async function tryQueriesForDistrict({ bbox_original, center }) {
  // Strateji:
  // - bbox Ã§ok bÃ¼yÃ¼kse: radius fallbacks
  // - deÄŸilse: direkt original bbox
  const area = bboxAreaDeg2(bbox_original);

  const candidates = [];

  if (center?.lat && center?.lon && area > MAX_BBOX_AREA_DEG2) {
    for (const r of RADIUS_FALLBACK_KM) {
      candidates.push({
        strategy: `radius_${r}km`,
        bbox: bboxAroundCenter({ lat: center.lat, lon: center.lon }, r),
      });
    }
    if (TRY_ORIGINAL_BBOX_LAST) {
      candidates.push({ strategy: "original_bbox", bbox: bbox_original });
    }
  } else {
    // kÃ¼Ã§Ã¼k bbox: Ã¶nce original dene
    candidates.push({ strategy: "original_bbox", bbox: bbox_original });
  }

  // tek tek dene: ilk sonuÃ§ >0 ise dur; hepsi 0 ise sonuncuyu da kaydet
  let last = null;

  for (const c of candidates) {
    const query = buildOverpassQuery(c.bbox);
    const { endpoint, data } = await fetchWithFailover(query);
    const count = data?.elements?.length ?? 0;

    last = { ...c, endpoint, data, count };

    console.log(`  â†’ denendi: ${c.strategy} | elements=${count}`);
    if (count > 0) return last;

    await sleep(600);
  }

  return last; // hepsi 0 ise en son denenen
}

async function run() {
  await fs.mkdir(OUT_DIR, { recursive: true });

  const coords = JSON.parse(await fs.readFile(COORDS_FILE, "utf8"));
  const districts = coords.out || [];
  const index = [];

  for (const d of districts) {
    const { sehir_id, sehir_adi, ilce_id, ilce_adi, bbox: bbox_original, center } = d;
    if (!bbox_original) continue;

    console.log(`\nâ–¶ Overpass: ${sehir_adi} / ${ilce_adi}`);

    try {
      const result = await tryQueriesForDistrict({ bbox_original, center });

      const base = `${safeSlug(sehir_adi)}__${safeSlug(ilce_adi)}__${sehir_id}_${ilce_id}`;
      const outFile = path.join(OUT_DIR, `${base}.json`);

      const wrapped = {
        meta: {
          sehir_id, sehir_adi,
          ilce_id, ilce_adi,
          bbox_used: result.bbox,
          bbox_original,
          strategy: result.strategy,
          endpoint: result.endpoint,
          elementsCount: result.count,
          fetchedAt: new Date().toISOString(),
        },
        overpass: result.data,
      };

      await fs.writeFile(outFile, JSON.stringify(wrapped, null, 2), "utf8");
      console.log(`  âœ“ seÃ§ilen: ${wrapped.meta.strategy} | ${wrapped.meta.elementsCount} element â†’ ${outFile}`);

      index.push({ ...wrapped.meta, file: outFile, ok: true });
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
