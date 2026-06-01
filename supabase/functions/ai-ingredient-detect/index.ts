import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { enforceRateLimit } from "../_shared/rate-limit.ts";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ─── Valid categories & confidence levels ─────────────────────────────────────

const VALID_CONFIDENCE = new Set(["certain", "likely", "uncertain"]);
const VALID_CATEGORIES = new Set([
  "meat", "poultry", "seafood", "dairy", "egg",
  "vegetable", "fruit", "grain", "legume",
  "fat_oil", "spice", "sauce", "nut", "other",
]);

// ─── Prompt ───────────────────────────────────────────────────────────────────

function buildIngredientPrompt(itemName: string, description: string): string {
  return `You are a Turkish cuisine expert and nutritionist. Analyze the menu item below and produce a detailed ingredient list with dietary classification.

Food item: "${itemName}"${description ? `\nDescription: "${description}"` : ""}

Confidence levels:
- "certain": this ingredient is definitely in every version of this dish (core component)
- "likely": commonly found in this dish but may vary by restaurant or recipe
- "uncertain": may appear in some versions, optional, or you are not sure

Categories: meat, poultry, seafood, dairy, egg, vegetable, fruit, grain, legume, fat_oil, spice, sauce, nut, other

Diet rules for the summary:
- is_vegan: true only if NO meat/poultry/seafood/dairy/egg ingredients at any confidence level
- is_vegetarian: true if no meat/poultry/seafood (dairy and egg are ok)
- is_gluten_free: true if no wheat/barley/rye/oats (grain category with gluten)
- is_dairy_free: true if no dairy category ingredients
- Use null (JSON null) when you cannot determine with reasonable confidence

Instructions:
- Use Turkish ingredient names
- List ingredients from most to least certain
- Be specific (e.g., "Kırmızı mercimek" not just "Baklagil")
- Include cooking fats, spices, and stock if typically used
- Return ONLY valid JSON, no explanation, no markdown

{
  "ingredients": [
    { "name": "...", "confidence": "certain|likely|uncertain", "category": "..." }
  ],
  "diet": {
    "is_vegan": true|false|null,
    "is_vegetarian": true|false|null,
    "is_gluten_free": true|false|null,
    "is_dairy_free": true|false|null
  }
}`;
}

interface IngredientEntry {
  name: string;
  confidence: string;
  category: string;
}

interface DietSummary {
  is_vegan: boolean | null;
  is_vegetarian: boolean | null;
  is_gluten_free: boolean | null;
  is_dairy_free: boolean | null;
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return json({ ok: false, error: "missing_jwt" }, 401);
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
  const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY");

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }
  if (!OPENROUTER_API_KEY) {
    return json({ ok: false, error: "missing_openrouter_key" }, 500);
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) {
    return json({ ok: false, error: "not_authenticated" }, 401);
  }

  try { await enforceRateLimit(userRes.user.id, "ai-ingredient-detect", 20); }
  catch (r) { return r as Response; }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, error: "invalid_json" }, 400);
  }

  const itemName = String(body.item_name ?? "").trim();
  const description = String(body.description ?? "").trim();

  if (itemName.length < 2) {
    return json({ ok: false, error: "item_name_too_short" }, 400);
  }

  try {
    const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemma-4-26b-a4b-it:free",
        max_tokens: 1024,
        temperature: 0.2,
        messages: [
          { role: "user", content: buildIngredientPrompt(itemName, description) },
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

    const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) ??
      raw.match(/(\{[\s\S]*\})/);
    const jsonText = (jsonMatch?.[1] ?? raw).trim();
    const parsed = JSON.parse(jsonText) as {
      ingredients?: IngredientEntry[];
      diet?: Partial<DietSummary>;
    };

    // Sanitize ingredients
    const ingredients: IngredientEntry[] = (parsed.ingredients ?? [])
      .filter((i) => i.name && i.name.trim().length > 0)
      .map((i) => ({
        name: i.name.trim(),
        confidence: VALID_CONFIDENCE.has(i.confidence) ? i.confidence : "likely",
        category: VALID_CATEGORIES.has(i.category) ? i.category : "other",
      }));

    // Sanitize diet
    const rawDiet = parsed.diet ?? {};
    const boolOrNull = (v: unknown): boolean | null =>
      v === true ? true : v === false ? false : null;

    const diet: DietSummary = {
      is_vegan: boolOrNull(rawDiet.is_vegan),
      is_vegetarian: boolOrNull(rawDiet.is_vegetarian),
      is_gluten_free: boolOrNull(rawDiet.is_gluten_free),
      is_dairy_free: boolOrNull(rawDiet.is_dairy_free),
    };

    return json({ ok: true, ingredients, diet });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return json({ ok: false, error: "detection_failed", detail: msg }, 500);
  }
});
