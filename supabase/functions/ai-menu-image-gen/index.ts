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

// ─── Aşama 1: Prompt — önce cache, sonra şablon, AÇIKLAMA VARSA Gemini ────────
// Basit bir isimden şablon zaten iyi bir sonuç verir; AI çağrısı sadece
// şablonun yakalayamayacağı detayları (sahibin yazdığı açıklama) olan
// ürünler için harcanıyor. Üretilen prompt normalized_food_name+language
// bazında kalıcı cache'leniyor — aynı ürün adı bir daha hiç AI'a gitmez.

function normalizeFoodName(name: string): string {
  // Türkçe İ/i büyük/küçük harf dönüşümü locale-aware olmalı (aksi halde
  // "İskender" gibi isimler yanlış normalize olur — bu projede daha önce
  // tam bu sınıfta bir bug bulunmuştu).
  return name.trim().toLocaleLowerCase("tr-TR").replace(/\s+/g, " ");
}

function buildTemplatePrompt(itemName: string): string {
  return `${itemName}, authentic Turkish restaurant food photography, realistic presentation, served on restaurant tableware, natural appetizing colors, 45 degree camera angle, soft restaurant lighting, shallow depth of field, professional food photography, no text, no logo, no people`;
}

async function generatePromptWithGemini(apiKey: string, itemName: string, description: string): Promise<string | null> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `You are a professional food photography expert. Write a concise English image-generation prompt for this Turkish restaurant menu item, using the description to capture details a generic prompt would miss.

Food item: "${itemName}"
Description: "${description}"

Requirements:
- Under 40 words, English only
- Style: authentic Turkish restaurant food photography, realistic presentation, served on restaurant tableware, natural appetizing colors, 45 degree camera angle, soft restaurant lighting, shallow depth of field, no text, no logo, no people
- Return ONLY the prompt text, nothing else`,
            }],
          }],
          generationConfig: { temperature: 0.4, maxOutputTokens: 150 },
        }),
        signal: AbortSignal.timeout(15_000),
      },
    );
    if (!res.ok) return null;
    const data = await res.json() as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    return text ? text.replace(/^["']|["']$/g, "").trim() : null;
  } catch {
    return null;
  }
}

async function getOrCreatePrompt(
  adminClient: ReturnType<typeof createClient>,
  itemName: string,
  description: string,
): Promise<{ prompt: string; cached: boolean; model: string }> {
  const normalized = normalizeFoodName(itemName);

  const { data: cached } = await adminClient
    .from("food_image_prompts")
    .select("prompt, model")
    .eq("normalized_food_name", normalized)
    .eq("language", "tr")
    .maybeSingle();
  if (cached?.prompt) {
    return { prompt: cached.prompt as string, cached: true, model: (cached.model as string) ?? "cache" };
  }

  let prompt: string;
  let model: string;
  const geminiKey = Deno.env.get("GEMINI_API_KEY");

  if (description.trim().length > 0 && geminiKey) {
    const generated = await generatePromptWithGemini(geminiKey, itemName, description);
    if (generated) {
      prompt = generated;
      model = "gemini-2.5-flash-lite";
    } else {
      prompt = buildTemplatePrompt(itemName);
      model = "template";
    }
  } else {
    prompt = buildTemplatePrompt(itemName);
    model = "template";
  }

  await adminClient
    .from("food_image_prompts")
    .upsert({ normalized_food_name: normalized, language: "tr", prompt, model }, { onConflict: "normalized_food_name,language" });

  return { prompt, cached: false, model };
}

// ─── Aşama 2: Görsel üretimi — PRIMARY Cloudflare Workers AI FLUX.1 Schnell,
// FALLBACK Pollinations.ai (artık sınırsız ücretsiz değil — Pollen tükenirse
// veya key yoksa best-effort olarak denenir). ─────────────────────────────

interface GeneratedImage {
  bytes: Uint8Array;
  contentType: string;
  engine: "cloudflare" | "pollinations";
}

async function generateWithCloudflare(accountId: string, apiToken: string, prompt: string): Promise<GeneratedImage | null> {
  try {
    const res = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/run/@cf/black-forest-labs/flux-1-schnell`,
      {
        method: "POST",
        headers: { "Authorization": `Bearer ${apiToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({ prompt, steps: 4 }),
        signal: AbortSignal.timeout(30_000),
      },
    );
    if (!res.ok) return null;
    const data = await res.json() as { result?: { image?: string }; success?: boolean };
    const b64 = data.result?.image;
    if (!b64) return null;
    const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
    return { bytes, contentType: "image/png", engine: "cloudflare" };
  } catch {
    return null;
  }
}

async function generateWithPollinations(prompt: string, apiKey: string | undefined): Promise<GeneratedImage | null> {
  try {
    const encoded = encodeURIComponent(prompt);
    const seed = Math.floor(Math.random() * 999999);
    const url = `https://image.pollinations.ai/prompt/${encoded}?width=512&height=512&nologo=true&model=flux-realism&seed=${seed}`;
    const headers: Record<string, string> = {};
    if (apiKey) headers["Authorization"] = `Bearer ${apiKey}`;

    const res = await fetch(url, { headers, signal: AbortSignal.timeout(30_000) });
    if (!res.ok) return null;
    const contentType = res.headers.get("content-type") ?? "image/jpeg";
    const bytes = new Uint8Array(await res.arrayBuffer());
    if (bytes.length === 0) return null;
    return { bytes, contentType: contentType.startsWith("image/") ? contentType : "image/jpeg", engine: "pollinations" };
  } catch {
    return null;
  }
}

async function generateImage(prompt: string): Promise<GeneratedImage | null> {
  const cfAccountId = Deno.env.get("CLOUDFLARE_ACCOUNT_ID");
  const cfApiToken = Deno.env.get("CLOUDFLARE_API_TOKEN");
  if (cfAccountId && cfApiToken) {
    const result = await generateWithCloudflare(cfAccountId, cfApiToken, prompt);
    if (result) return result;
  }

  const pollinationsKey = Deno.env.get("POLLINATIONS_API_KEY");
  return await generateWithPollinations(prompt, pollinationsKey);
}

function extFromContentType(contentType: string): string {
  if (contentType.includes("png")) return "png";
  if (contentType.includes("webp")) return "webp";
  return "jpg";
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
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

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
  const description = String(body.description ?? "").trim();
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
    const { prompt, cached, model } = await getOrCreatePrompt(adminClient, itemName, description);

    const image = await generateImage(prompt);
    if (!image) {
      return json({ ok: false, error: "generation_failed", detail: "no_engine_responded" }, 502);
    }

    const now = new Date();
    const yyyy = String(now.getUTCFullYear()).padStart(4, "0");
    const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
    const ext = extFromContentType(image.contentType);
    const objectPath = `ai-generated/business/${businessId}/${yyyy}/${mm}/${crypto.randomUUID()}.${ext}`;

    const { error: uploadErr } = await adminClient.storage
      .from("menu-media")
      .upload(objectPath, image.bytes, { contentType: image.contentType, upsert: false });
    if (uploadErr) {
      return json({ ok: false, error: "storage_upload_failed", detail: uploadErr.message }, 500);
    }

    const { data: pub } = adminClient.storage.from("menu-media").getPublicUrl(objectPath);

    return json({
      ok: true,
      image_url: pub.publicUrl,
      prompt,
      prompt_cached: cached,
      prompt_model: model,
      image_engine: image.engine,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return json({ ok: false, error: "generation_failed", detail: msg }, 500);
  }
});
