import process from "node:process";
import { createClient } from "@supabase/supabase-js";

async function ensureBusiness(supabase, row) {
  const { data: existing, error: findError } = await supabase
    .from("businesses")
    .select("id,name,city,district")
    .eq("name", row.name)
    .eq("city", row.city)
    .eq("district", row.district)
    .limit(1);

  if (findError) {
    throw new Error(`find business failed: ${findError.message}`);
  }
  if (existing && existing.length > 0) return existing[0].id;

  const { data, error } = await supabase
    .from("businesses")
    .insert(row)
    .select("id")
    .single();
  if (error) throw new Error(`insert business failed: ${error.message}`);
  return data.id;
}

async function main() {
  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error("Missing env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY");
    process.exit(1);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const rows = [
    {
      name: "Yeedoy Test Kafe",
      category: "Kafe",
      city: "İstanbul",
      district: "Kadıköy",
      address: "Moda Caddesi 12",
      lat: 40.9822,
      lng: 29.0263,
      is_active: true,
    },
    {
      name: "Yeedoy Test Kebap",
      category: "Kebap",
      city: "İstanbul",
      district: "Beşiktaş",
      address: "Çarşı Sokak 7",
      lat: 41.0439,
      lng: 29.0094,
      is_active: true,
    },
    {
      name: "Yeedoy Test Kahvaltı",
      category: "Kahvaltı",
      city: "İzmir",
      district: "Konak",
      address: "Kıbrıs Şehitleri 55",
      lat: 38.4322,
      lng: 27.1384,
      is_active: true,
    },
  ];

  const ids = [];
  for (const row of rows) {
    const id = await ensureBusiness(supabase, row);
    ids.push(id);
  }

  console.log(`Seed complete: businesses=${ids.length}`);
}

main().catch((e) => {
  console.error("Seed failed:", e);
  process.exit(1);
});
