import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { createClient } from "@supabase/supabase-js";

/**
 * Turkish-safe normalize:
 * - lower
 * - İ/ı => i
 * - remove diacritics
 * - keep letters/numbers/spaces
 */
function trLower(s) {
  return s
    .replace(/İ/g, "I")
    .replace(/ı/g, "i")
    .toLowerCase();
}

function stripDiacritics(s) {
  return s.normalize("NFKD").replace(/[\u0300-\u036f]/g, "");
}

function nameNorm(s) {
  return stripDiacritics(trLower(s))
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function slugify(s) {
  return nameNorm(s)
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

async function upsertBatches(supabase, table, rows, onConflict, batchSize = 500) {
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = rows.slice(i, i + batchSize);
    const { error } = await supabase.from(table).upsert(batch, { onConflict });
    if (error) throw new Error(`${table} upsert failed: ${error.message}`);
  }
}

async function main() {
  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error("Missing env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY");
    process.exit(1);
  }

  const jsonPath = process.argv[2] || "/mnt/data/yemek.json";
  const raw = fs.readFileSync(jsonPath, "utf-8");
  const doc = JSON.parse(raw);

  const categories = doc.categories || [];
  if (!Array.isArray(categories) || categories.length === 0) {
    throw new Error("No categories found in yemek.json");
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 1) categories
  const catRows = categories.map((c, idx) => ({
    id: c.id,
    name: c.name,
    sort_order: idx,
  }));
  await upsertBatches(supabase, "food_catalog_categories", catRows, "id", 200);

  // 2) items
  const itemRows = [];
  for (const c of categories) {
    const items = Array.isArray(c.items) ? c.items : [];
    for (const name of items) {
      const slug = slugify(name);
      const norm = nameNorm(name);
      if (!slug || !norm) continue;
      itemRows.push({
        category_id: c.id,
        name,
        name_norm: norm,
        slug,
        popularity: 0,
      });
    }
  }

  // unique: (category_id, slug)
  await upsertBatches(supabase, "food_catalog_items", itemRows, "category_id,slug", 500);

  console.log(`✅ Seed complete: categories=${catRows.length}, items=${itemRows.length}`);
}

main().catch((e) => {
  console.error("❌ Seed failed:", e);
  process.exit(1);
});
