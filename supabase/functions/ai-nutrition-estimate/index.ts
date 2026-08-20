import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// _shared/rate-limit.ts relative import'u tek-fonksiyon deploy paketinde
// bundler tarafından çözülemiyor (bkz. ai-allergen-detect) — inline edildi.
async function enforceRateLimit(
  userId: string,
  fnName: string,
  max = 20,
  window = "01:00:00",
): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return;

  const admin = createClient(supabaseUrl, serviceKey);
  const key = `rl:${fnName}:${userId}`;

  const { data: allowed, error } = await admin.rpc("check_rate_limit_v1", {
    p_key: key,
    p_max: max,
    p_window: window,
  });

  if (error) return;

  if (!allowed) {
    throw new Response(
      JSON.stringify({ ok: false, error: "rate_limit_exceeded" }),
      { status: 429, headers: { "Content-Type": "application/json", "Retry-After": "3600" } },
    );
  }
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ─── USDA FoodData Central ───────────────────────────────────────────────────

interface UsdaNutrient {
  nutrientId: number;
  nutrientName: string;
  value: number;
  unitName: string;
}

interface UsdaFood {
  fdcId: number;
  description: string;
  foodNutrients: UsdaNutrient[];
}

interface UsdaNutritionSummary {
  fdcId: number;
  description: string;
  kcal: number | null;
  protein_g: number | null;
  fat_g: number | null;
  carbs_g: number | null;
}

async function queryUsda(apiKey: string, query: string): Promise<UsdaNutritionSummary[]> {
  const url = new URL("https://api.nal.usda.gov/fdc/v1/foods/search");
  url.searchParams.set("query", query);
  url.searchParams.set("api_key", apiKey);
  url.searchParams.set("dataType", "SR Legacy,Survey (FNDDS),Foundation");
  url.searchParams.set("pageSize", "3");

  try {
    const res = await fetch(url.toString(), { signal: AbortSignal.timeout(15_000) });
    if (!res.ok) return [];
    const data = await res.json() as { foods?: UsdaFood[] };
    return (data.foods ?? []).slice(0, 3).map((f) => {
      const get = (id: number) => f.foodNutrients.find((n) => n.nutrientId === id)?.value ?? null;
      return {
        fdcId: f.fdcId,
        description: f.description,
        kcal: get(1008),
        protein_g: get(1003),
        fat_g: get(1004),
        carbs_g: get(1005),
      };
    });
  } catch {
    return [];
  }
}

// Yemeği tek bir isim olarak aramak yerine, MÜMKÜNSE her malzemeyi ayrı ayrı
// USDA'da arıyoruz — "Adana Kebap" gibi tek bir sorgudan çok, "kıyma",
// "soğan", "biber" gibi malzeme bazlı eşleşmeler AI'a çok daha somut bir
// zemin veriyor. Yemek adı da ayrıca aranır (hazır USDA/FNDDS eşleşmesi
// varsa — örn. survey verisinde "Kebab, lamb or mutton" gibi — en güçlü
// sinyal odur).
async function gatherUsdaContext(
  apiKey: string,
  itemName: string,
  ingredients: string[],
): Promise<{ context: string; fdcIds: number[]; matchedIngredientCount: number }> {
  const dishResults = await queryUsda(apiKey, itemName);

  const cappedIngredients = ingredients.slice(0, 8);
  const ingredientResults = await Promise.all(
    cappedIngredients.map((ing) => queryUsda(apiKey, ing)),
  );

  const lines: string[] = [];
  const fdcIds: number[] = [];

  if (dishResults.length > 0) {
    lines.push("Whole-dish matches (per 100g):");
    for (const r of dishResults) {
      lines.push(`- ${r.description}: ${r.kcal ?? "?"}kcal, protein ${r.protein_g ?? "?"}g, fat ${r.fat_g ?? "?"}g, carbs ${r.carbs_g ?? "?"}g`);
      fdcIds.push(r.fdcId);
    }
  }

  let matchedIngredientCount = 0;
  for (let i = 0; i < cappedIngredients.length; i++) {
    const results = ingredientResults[i];
    if (results.length === 0) continue;
    matchedIngredientCount++;
    const best = results[0];
    lines.push(`- Ingredient "${cappedIngredients[i]}" ≈ ${best.description}: ${best.kcal ?? "?"}kcal, protein ${best.protein_g ?? "?"}g, fat ${best.fat_g ?? "?"}g, carbs ${best.carbs_g ?? "?"}g (per 100g)`);
    fdcIds.push(best.fdcId);
  }

  return { context: lines.join("\n"), fdcIds, matchedIngredientCount };
}

// ─── Gemma prompt ─────────────────────────────────────────────────────────────

function buildNutritionPrompt(
  itemName: string,
  description: string,
  usdaContext: string,
  portionGrams: number | null,
): string {
  const portionInstruction = portionGrams
    ? `The ACTUAL serving weight for this dish is exactly ${portionGrams}g (provided by the restaurant owner) — scale your nutrition estimate precisely to this weight, do not guess a different serving size.`
    : `No exact serving weight was provided — estimate a typical Turkish restaurant serving weight yourself.`;

  return `You are a certified nutrition expert specializing in Turkish and Mediterranean cuisine. Estimate the nutritional values for a standard restaurant serving.

Food item: "${itemName}"${description ? `\nDescription: "${description}"` : ""}

USDA reference data (per 100g portions of the dish itself and/or its individual ingredients):
${usdaContext || "No USDA data available — use general knowledge."}

Instructions:
- ${portionInstruction}
- Provide MIN–MAX ranges to account for recipe and portion variations — never give exact single values
- If ingredient-level USDA data is given, use it to build up the estimate from the ingredients rather than guessing the whole dish blindly
- Return ONLY valid JSON, no explanation, no markdown

{
  "serving_est_g": <integer: serving weight in grams — must equal the provided value if one was given>,
  "calorie_min": <integer>,
  "calorie_max": <integer>,
  "protein_min_g": <number with 1 decimal>,
  "protein_max_g": <number with 1 decimal>,
  "fat_min_g": <number with 1 decimal>,
  "fat_max_g": <number with 1 decimal>,
  "carbs_min_g": <number with 1 decimal>,
  "carbs_max_g": <number with 1 decimal>
}`;
}

interface NutritionEstimate {
  serving_est_g: number;
  calorie_min: number;
  calorie_max: number;
  protein_min_g: number;
  protein_max_g: number;
  fat_min_g: number;
  fat_max_g: number;
  carbs_min_g: number;
  carbs_max_g: number;
}

async function estimateWithGemma(
  apiKey: string,
  itemName: string,
  description: string,
  usdaContext: string,
  portionGrams: number | null,
): Promise<NutritionEstimate> {
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "google/gemma-4-26b-a4b-it:free",
      max_tokens: 300,
      temperature: 0.3,
      messages: [
        { role: "user", content: buildNutritionPrompt(itemName, description, usdaContext, portionGrams) },
      ],
    }),
    signal: AbortSignal.timeout(45_000),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`openrouter_error: ${res.status} ${err}`);
  }

  const data = await res.json() as { choices: Array<{ message: { content: string } }> };
  const raw = (data.choices?.[0]?.message?.content ?? "").trim();

  const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) ?? raw.match(/(\{[\s\S]*\})/);
  const jsonText = (jsonMatch?.[1] ?? raw).trim();
  const parsed = JSON.parse(jsonText) as Record<string, unknown>;

  const num = (k: string) => Math.max(0, Number(parsed[k] ?? 0));
  return {
    serving_est_g: portionGrams ?? (Math.round(num("serving_est_g")) || 200),
    calorie_min: Math.round(num("calorie_min")),
    calorie_max: Math.round(num("calorie_max")),
    protein_min_g: Math.round(num("protein_min_g") * 10) / 10,
    protein_max_g: Math.round(num("protein_max_g") * 10) / 10,
    fat_min_g: Math.round(num("fat_min_g") * 10) / 10,
    fat_max_g: Math.round(num("fat_max_g") * 10) / 10,
    carbs_min_g: Math.round(num("carbs_min_g") * 10) / 10,
    carbs_max_g: Math.round(num("carbs_max_g") * 10) / 10,
  };
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ ok: false, error: "missing_jwt" }, 401);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
  const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY");
  const USDA_API_KEY = Deno.env.get("USDA_API_KEY");

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) return json({ ok: false, error: "missing_supabase_env" }, 500);
  if (!OPENROUTER_API_KEY) return json({ ok: false, error: "missing_openrouter_key" }, 500);

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) return json({ ok: false, error: "not_authenticated" }, 401);

  try { await enforceRateLimit(userRes.user.id, "ai-nutrition-estimate", 20); }
  catch (r) { return r as Response; }

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ ok: false, error: "invalid_json" }, 400); }

  const itemName = String(body.item_name ?? "").trim();
  const description = String(body.description ?? "").trim();
  const businessId = String(body.business_id ?? "").trim();
  const ingredients = Array.isArray(body.ingredients)
    ? (body.ingredients as unknown[]).map((i) => String(i).trim()).filter(Boolean).slice(0, 20)
    : [];
  const portionGramsRaw = Number(body.portion_grams);
  const portionGrams = Number.isFinite(portionGramsRaw) && portionGramsRaw > 0 ? Math.round(portionGramsRaw) : null;

  if (itemName.length < 2) return json({ ok: false, error: "item_name_too_short" }, 400);
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(businessId)) {
    return json({ ok: false, error: "invalid_business_id" }, 400);
  }

  const { error: limitError } = await userClient.rpc("_check_plan_limit_v1", {
    p_business_id: businessId,
    p_feature_key: "allergen_ai",
  });
  if (limitError) {
    const unauthorized = limitError.message.includes("unauthorized");
    return json(
      { ok: false, error: unauthorized ? "unauthorized" : "plan_limit_exceeded" },
      unauthorized ? 403 : 402,
    );
  }

  try {
    let usdaContext = "";
    let usdaFdcIds: number[] = [];
    let matchedIngredientCount = 0;

    if (USDA_API_KEY) {
      const gathered = await gatherUsdaContext(USDA_API_KEY, itemName, ingredients);
      usdaContext = gathered.context;
      usdaFdcIds = gathered.fdcIds;
      matchedIngredientCount = gathered.matchedIngredientCount;
    }

    const estimate = await estimateWithGemma(OPENROUTER_API_KEY, itemName, description, usdaContext, portionGrams);

    const source = !USDA_API_KEY
      ? "ai_estimated"
      : matchedIngredientCount > 0
        ? "usda_ingredients+ai"
        : usdaFdcIds.length > 0
          ? "usda_dish+ai"
          : "ai_estimated";

    return json({
      ok: true,
      is_approximate: true,
      source,
      usda_fdc_ids: usdaFdcIds.length > 0 ? usdaFdcIds : null,
      portion_grams: estimate.serving_est_g,
      calories: { min: estimate.calorie_min, max: estimate.calorie_max },
      protein_g: { min: estimate.protein_min_g, max: estimate.protein_max_g },
      fat_g: { min: estimate.fat_min_g, max: estimate.fat_max_g },
      carbs_g: { min: estimate.carbs_min_g, max: estimate.carbs_max_g },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return json({ ok: false, error: "estimation_failed", detail: msg }, 500);
  }
});
