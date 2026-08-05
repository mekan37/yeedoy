import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { enforceRateLimit } from "../_shared/rate-limit.ts";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ─── Sabit prompt şablonu — sadece {item_name} değişir ─────────────────────
function buildPrompt(itemName: string): string {
  return `You are a professional food photography expert. Generate a concise image generation prompt for the following Turkish food item.

Food item: "${itemName}"

Requirements:
- Write ONLY the image prompt, nothing else
- Write in English
- Under 40 words
- Style: professional restaurant menu photo, soft natural lighting, shallow depth of field, white or neutral background, elegant plating, garnish visible
- Do NOT include any explanation or commentary`;
}

// ─── OpenRouter Gemma çağrısı ───────────────────────────────────────────────
async function generateImagePrompt(
  apiKey: string,
  itemName: string,
): Promise<string> {
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "google/gemma-4-26b-a4b-it:free",
      max_tokens: 120,
      temperature: 0.7,
      messages: [
        {
          role: "user",
          content: buildPrompt(itemName),
        },
      ],
    }),
    signal: AbortSignal.timeout(30_000),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`openrouter_error: ${res.status} ${err}`);
  }

  const data = await res.json() as {
    choices: Array<{ message: { content: string } }>;
  };
  const raw = (data.choices?.[0]?.message?.content ?? "").trim();
  // Strip any surrounding quotes the model might add
  return raw.replace(/^["']|["']$/g, "").trim();
}

// ─── Pollinations.ai görsel URL'si ─────────────────────────────────────────
function buildImageUrl(prompt: string, seed?: number): string {
  const encoded = encodeURIComponent(prompt);
  const s = seed ?? Math.floor(Math.random() * 999999);
  return `https://image.pollinations.ai/prompt/${encoded}?width=512&height=512&nologo=true&model=flux-realism&seed=${s}`;
}

// ─── Handler ───────────────────────────────────────────────────────────────
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
    await enforceRateLimit(userRes.user.id, "ai-menu-image-gen", 20);
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
  const businessId = String(body.business_id ?? "").trim();

  if (itemName.length < 2) {
    return json({ ok: false, error: "item_name_too_short" }, 400);
  }
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(businessId)) {
    return json({ ok: false, error: "invalid_business_id" }, 400);
  }

  const { error: limitError } = await userClient.rpc("_check_plan_limit_v1", {
    p_business_id: businessId,
    p_feature_key: "ai_image_gen",
  });
  if (limitError) {
    const unauthorized = limitError.message.includes("unauthorized");
    return json(
      { ok: false, error: unauthorized ? "unauthorized" : "plan_limit_exceeded" },
      unauthorized ? 403 : 402,
    );
  }

  try {
    // Step 1: Gemma → detailed food photo prompt
    const imagePrompt = await generateImagePrompt(OPENROUTER_API_KEY, itemName);

    // Step 2: Pollinations.ai → image URL (no API key needed)
    const imageUrl = buildImageUrl(imagePrompt);

    return json({
      ok: true,
      image_url: imageUrl,
      prompt: imagePrompt,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return json({ ok: false, error: "generation_failed", detail: msg }, 500);
  }
});
