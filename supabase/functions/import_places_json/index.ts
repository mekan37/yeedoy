// supabase/functions/import_places_json/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function normStr(v: unknown) {
  return (v ?? "").toString().trim();
}
function slugTr(s: string) {
  return s
    .trim()
    .toLowerCase()
    .replaceAll("ç", "c").replaceAll("ğ", "g").replaceAll("ı", "i")
    .replaceAll("ö", "o").replaceAll("ş", "s").replaceAll("ü", "u")
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}
function roundCoord(x: number, p = 4) {
  const m = 10 ** p;
  return Math.round(x * m) / m;
}
async function sha1(input: string) {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest("SHA-1", data);
  return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, "0")).join("");
}

const ALLOWED = new Set(["Kafe", "Restoran", "Tatlıcı", "Kahvaltı", "Balık / Et", "Mekan"]);

function pickCategory(tags: Record<string, any>) {
  const amenity = normStr(tags.amenity);
  const shop = normStr(tags.shop);
  const cuisine = normStr(tags.cuisine).toLowerCase();
  const liveMusic = normStr(tags.live_music).toLowerCase();
  const breakfast = normStr(tags.breakfast).toLowerCase();
  const name = normStr(tags.name).toLowerCase();

  // priority: Mekan > Tatlıcı > Kahvaltı > Balık/Et > Kafe > Restoran
  if (["bar", "pub", "nightclub"].includes(amenity) || liveMusic === "yes") return "Mekan";

  if (
    amenity === "ice_cream" ||
    shop === "confectionery" ||
    /dessert|ice_cream|patisserie/.test(cuisine) ||
    /tatl|pasta|baklava|dondurma/.test(name)
  ) return "Tatlıcı";

  if (
    breakfast === "yes" ||
    /breakfast|brunch/.test(cuisine) ||
    /kahvalt|serpme|brunch/.test(name)
  ) return "Kahvaltı";

  if (
    /seafood|fish|steak|kebab|bbq|barbecue|meat/.test(cuisine) ||
    /balık|ocakbaşı|steak|et/.test(name)
  ) return "Balık / Et";

  if (amenity === "cafe") return "Kafe";
  if (amenity === "restaurant") return "Restoran";

  return null;
}

function getLatLng(el: any) {
  const lat = el.lat ?? el.center?.lat;
  const lng = el.lon ?? el.center?.lon;
  return { lat, lng };
}

function buildAddress(tags: Record<string, any>) {
  const street = normStr(tags["addr:street"]);
  const no = normStr(tags["addr:housenumber"]);
  const neigh = normStr(tags["addr:neighbourhood"]);
  const txt = [street && no ? `${street} ${no}` : street, neigh].filter(Boolean).join(", ");
  return txt || null;
}

function pickPhone(tags: Record<string, any>) {
  return normStr(tags.phone || tags["contact:phone"]) || null;
}

const ALLOWED_ORIGINS = [
  "https://yeedoy.com",
  "https://panel.yeedoy.com",
  "http://localhost:3000",
  "http://localhost:3001",
];

function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") ?? "";
  const headers: Record<string, string> = {
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Vary": "Origin",
  };
  if (ALLOWED_ORIGINS.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  // Non-allowed origins receive no Access-Control-Allow-Origin header
  return headers;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(req) });
  }

  // ── Auth: require valid JWT + is_admin ─────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "content-type": "application/json", ...corsHeaders(req) },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: userErr } = await callerClient.auth.getUser();
  if (userErr || !user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "content-type": "application/json", ...corsHeaders(req) },
    });
  }

  const { data: isAdmin } = await callerClient.rpc("is_admin");
  if (!isAdmin) {
    return new Response(JSON.stringify({ error: "forbidden" }), {
      status: 403,
      headers: { "content-type": "application/json", ...corsHeaders(req) },
    });
  }
  // ── End auth ───────────────────────────────────────────────────────────────

  try {
    const form = await req.formData();
    const file = form.get("file");
    const city = normStr(form.get("city"));
    const district = normStr(form.get("district"));

    if (!(file instanceof File)) {
      return new Response(JSON.stringify({ error: "file_missing" }), { status: 400 });
    }

    const text = await file.text();
    const json = JSON.parse(text);

    // supports both: { elements: [...] } or { overpass: { elements: [...] } }
    const elements: any[] = json?.overpass?.elements || json?.elements || [];
    if (!Array.isArray(elements) || elements.length === 0) {
      return new Response(JSON.stringify({ ok: true, inserted: 0, skipped: 0, note: "no_elements" }), {
        headers: { "content-type": "application/json", ...corsHeaders(req) },
      });
    }

    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    const rows: any[] = [];
    let skipped = 0;

    for (const el of elements) {
      const tags = el.tags || {};

      const name = normStr(tags.name);
      if (!name) { skipped++; continue; }

      const { lat, lng } = getLatLng(el);
      if (lat == null || lng == null) { skipped++; continue; }

      const category = pickCategory(tags);
      if (!category || !ALLOWED.has(category)) { skipped++; continue; }

      const c = city || normStr(tags["addr:city"]);
      const d = district || normStr(tags["addr:district"]);

      const fpKey = [
        slugTr(name),
        category,
        slugTr(c),
        slugTr(d),
        String(roundCoord(Number(lat), 4)),
        String(roundCoord(Number(lng), 4)),
      ].join("|");

      const fingerprint = await sha1(fpKey);

      rows.push({
        name,
        category,
        description: null,
        phone: pickPhone(tags),
        address: buildAddress(tags),
        city: c || null,
        district: d || null,
        lat: Number(lat),
        lng: Number(lng),
        is_active: true,
        fingerprint,
      });
    }

    // upsert by fingerprint (duplicate şişirme yok)
    // batch
    const batchSize = 500;
    let upserted = 0;

    for (let i = 0; i < rows.length; i += batchSize) {
      const chunk = rows.slice(i, i + batchSize);
      const { error } = await supabase.from("businesses").upsert(chunk, { onConflict: "fingerprint" });
      if (error) throw error;
      upserted += chunk.length;
    }

    return new Response(JSON.stringify({
      ok: true,
      total_elements: elements.length,
      prepared: rows.length,
      upserted,
      skipped,
      file: file.name,
      city: city || null,
      district: district || null,
    }), {
      headers: { "content-type": "application/json", ...corsHeaders(req) },
    });

  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { "content-type": "application/json", ...corsHeaders(req) },
    });
  }
});
