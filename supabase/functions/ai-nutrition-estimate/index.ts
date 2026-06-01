import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { enforceRateLimit } from "../_shared/rate-limit.ts";

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

async function queryUsda(
  apiKey: string,
  query: string,
): Promise<UsdaNutritionSummary[]> {
  const url = new URL("https://api.nal.usda.gov/fdc/v1/foods/search");
  url.searchParams.set("query", query);
  url.searchParams.set("api_key", apiKey);
  url.searchParams.set("dataType", "SR Legacy,Survey (FNDDS),Foundation");
  url.searchParams.set("pageSize", "5");

  try {
    const res = await fetch(url.toString(), {
      signal: AbortSignal.timeout(15_000),
    });
    if (!res.ok) return [];
    const data = await res.json() as { foods?: UsdaFood[] };
    return (data.foods ?? []).slice(0, 5).map((f) => {
      const get = (id: number) =>
        f.foodNutrients.find((n) => n.nutrientId === id)?.value ?? null;
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

// ─── Gemma prompt (sadece item_name/description/usda_context değişir) ────────

function buildNutritionPrompt(
  itemName: string,
  description: string,
  usdaContext: string,
): string {
  return `You are a certified nutrition expert specializing in Turkish and Mediterranean cuisine. Estimate the nutritional values for a standard restaurant serving.

Food item: "${itemName}"${description ? `\nDescription: "${description}"` : ""}

USDA reference data for similar foods (per 100g):
${usdaContext || "No USDA data available — use general knowledge."}

Instructions:
- Estimate for a TYPICAL TURKISH RESTAURANT SERVING (not per 100g)
- Provide MIN–MAX ranges to account for recipe and portion variations
- Never give exact values — always ranges
- Return ONLY valid JSON, no explanation, no markdown

{
  "serving_est_g": <integer: estimated serving weight in grams>,
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
): Promise<NutritionEstimate> {
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "google/gemma-4-26b-a4b-it:free",
      max_tokens: 256,
      temperature: 0.3,
      messages: [
        {
          role: "user",
          content: buildNutritionPrompt(itemName, description, usdaContext),
        },
      ],
    }),
    signal: AbortSignal.timeout(45_000),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`openrouter_error: ${res.status} ${err}`);
  }

  const data = await res.json() as {
    choices: Array<{ message: { content: string } }>;
  };
  const raw = (data.choices?.[0]?.message?.content ?? "").trim();

  // Extract JSON (may be wrapped in markdown)
  const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) ??
    raw.match(/(\{[\s\S]*\})/);
  const jsonText = (jsonMatch?.[1] ?? raw).trim();

  const parsed = JSON.parse(jsonText) as Record<string, unknown>;

  const num = (k: string) => Math.max(0, Number(parsed[k] ?? 0));
  return {
    serving_est_g: Math.round(num("serving_est_g")) || 200,
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

  // Auth check
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

  if (itemName.length < 2) return json({ ok: false, error: "item_name_too_short" }, 400);

  try {
    // Step 1: USDA lookup (best-effort)
    let usdaContext = "";
    let usdaFdcIds: number[] = [];
    if (USDA_API_KEY) {
      const usdaResults = await queryUsda(USDA_API_KEY, itemName);
      usdaFdcIds = usdaResults.map((r) => r.fdcId);
      if (usdaResults.length > 0) {
        usdaContext = usdaResults.map((r) =>
          `- ${r.description}: ${r.kcal ?? "?"}kcal, protein ${r.protein_g ?? "?"}g, fat ${r.fat_g ?? "?"}g, carbs ${r.carbs_g ?? "?"}g`
        ).join("\n");
      }
    }

    // Step 2: Gemma estimation
    const estimate = await estimateWithGemma(
      OPENROUTER_API_KEY,
      itemName,
      description,
      usdaContext,
    );

    const source = USDA_API_KEY ? "usda+ai" : "ai_estimated";

    return json({
      ok: true,
      is_approximate: true,
      source,
      usda_fdc_ids: usdaFdcIds.length > 0 ? usdaFdcIds : null,
      ...estimate,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return json({ ok: false, error: "estimation_failed", detail: msg }, 500);
  }
});
