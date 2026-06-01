import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { enforceRateLimit } from "../_shared/rate-limit.ts";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ─── Valid allergen codes (14 EU allergens) ───────────────────────────────────

const VALID_ALLERGENS = new Set([
  "gluten",
  "crustaceans",
  "egg",
  "fish",
  "peanuts",
  "soy",
  "milk",
  "treenuts",
  "celery",
  "mustard",
  "sesame",
  "sulfur_dioxide",
  "lupin",
  "molluscs",
]);

// ─── Gemma prompt ─────────────────────────────────────────────────────────────

function sanitizeForPrompt(input: string, maxLen = 200): string {
  return input
    .replace(/["""''`]/g, "'")
    .replace(/\n+/g, " ")
    .substring(0, maxLen)
    .replace(/ignore\s+(all\s+)?previous\s+instructions?/gi, "[REDACTED]")
    .replace(/you\s+are\s+now\s+(?!going|about|ready)/gi, "[REDACTED] ");
}

function buildAllergenPrompt(itemName: string, description: string): string {
  const safeName = sanitizeForPrompt(itemName, 150);
  const safeDesc = sanitizeForPrompt(description, 300);
  return `You are a food allergen expert specializing in Turkish and Mediterranean cuisine.

Analyze the following menu item and identify which of the 14 EU-regulated allergens it contains or may contain.

Food item: "${safeName}"${safeDesc ? `\nDescription: "${safeDesc}"` : ""}

The 14 allergens and their codes:
- gluten (wheat, rye, barley, oats)
- crustaceans (shrimp, crab, lobster)
- egg
- fish
- peanuts
- soy (soybean)
- milk (dairy, lactose)
- treenuts (almond, hazelnut, walnut, cashew, pistachio, etc.)
- celery
- mustard
- sesame
- sulfur_dioxide (sulfites, SO2, preservatives E220-E228)
- lupin (lupine flour/seeds)
- molluscs (oyster, squid, snail, mussel, clam)

Instructions:
- "contains": the ingredient is a primary component of this dish
- "may_contain": possible due to recipe variation or cross-contamination risk
- Only include allergens that are realistic for this food item
- Return ONLY valid JSON, no explanation, no markdown

{
  "allergens": [
    { "allergen": "<code>", "risk": "contains" },
    { "allergen": "<code>", "risk": "may_contain" }
  ]
}`;
}

interface AllergenEntry {
  allergen: string;
  risk: string;
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

  // Auth check
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) {
    return json({ ok: false, error: "not_authenticated" }, 401);
  }

  try {
    await enforceRateLimit(userRes.user.id, "ai-allergen-detect", 20);
  } catch (rateLimitResponse) {
    return rateLimitResponse as Response;
  }

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
        max_tokens: 512,
        temperature: 0.1,
        messages: [
          {
            role: "user",
            content: buildAllergenPrompt(itemName, description),
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

    // Extract JSON
    const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) ??
      raw.match(/(\{[\s\S]*\})/);
    const jsonText = (jsonMatch?.[1] ?? raw).trim();
    const parsed = JSON.parse(jsonText) as { allergens?: AllergenEntry[] };

    // Validate and sanitize
    const allergens: AllergenEntry[] = (parsed.allergens ?? [])
      .filter((a) => VALID_ALLERGENS.has(a.allergen))
      .map((a) => ({
        allergen: a.allergen,
        risk: a.risk === "may_contain" ? "may_contain" : "contains",
      }));

    return json({ ok: true, allergens });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return json({ ok: false, error: "detection_failed", detail: msg }, 500);
  }
});
