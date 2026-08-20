import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// _shared/rate-limit.ts relative import'u tek-fonksiyon deploy paketinde
// bundler tarafından çözülemiyor (Module not found) — bu fonksiyon için
// inline edildi. Diğer fonksiyonlar (ai-nutrition-estimate vb.) hâlâ
// paylaşılan dosyayı kullanıyor, sadece bu dosyanın deploy şekli farklı.
async function enforceRateLimit(
  userId: string,
  fnName: string,
  max = 20,
  window = "01:00:00",
): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return; // fail open if env not set

  const admin = createClient(supabaseUrl, serviceKey);
  const key = `rl:${fnName}:${userId}`;

  const { data: allowed, error } = await admin.rpc("check_rate_limit_v1", {
    p_key: key,
    p_max: max,
    p_window: window,
  });

  if (error) return; // fail open on DB error

  if (!allowed) {
    throw new Response(
      JSON.stringify({ ok: false, error: "rate_limit_exceeded" }),
      {
        status: 429,
        headers: {
          "Content-Type": "application/json",
          "Retry-After": "3600",
        },
      },
    );
  }
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ─── Prompt sanitization (prompt-injection koruması) ──────────────────────────

function sanitizeForPrompt(input: string, maxLen = 200): string {
  return input
    .replace(/["""''`]/g, "'")
    .replace(/\n+/g, " ")
    .substring(0, maxLen)
    .replace(/ignore\s+(all\s+)?previous\s+instructions?/gi, "[REDACTED]")
    .replace(/you\s+are\s+now\s+(?!going|about|ready)/gi, "[REDACTED] ");
}

// ─── Aşama 1: LLM SADECE malzemeleri normalize eder + genel mutfak bilgisiyle
// "olası" risk işaret eder. Hangi malzemenin hangi alerjene karşılık geldiğine
// LLM KARAR VERMEZ — bu, aşağıdaki deterministik kural motorunun işi. ─────────

interface IngredientExtraction {
  ingredients: string[];
  possibleRisks: Array<{ code: string; reason: string }>;
}

function buildIngredientPrompt(itemName: string, description: string, validCodes: string[]): string {
  const safeName = sanitizeForPrompt(itemName, 150);
  const safeDesc = sanitizeForPrompt(description, 300);
  return `You are a Turkish/Mediterranean cuisine expert. Analyze this menu item and do TWO things:

1. List the distinct, normalized food ingredients used (in Turkish, base/singular form, lowercase — e.g. "tereyağı" not "Tereyağlı" or "tereyağlarından").
2. Separately, based on general recipe knowledge (NOT from an explicit ingredient list), flag any of these 14 allergen codes that could plausibly be present even though not explicitly stated (e.g. breadcrumbs in a köfte recipe): ${validCodes.join(", ")}. Only include genuinely plausible hedges, not every possible allergen.

Food item: "${safeName}"${safeDesc ? `\nDescription: "${safeDesc}"` : ""}

Return ONLY valid JSON, no explanation, no markdown:
{
  "ingredients": ["<normalized Turkish ingredient>", ...],
  "possibleRisks": [{ "code": "<one of the 14 codes>", "reason": "<short Turkish reason>" }]
}`;
}

function extractJson<T>(raw: string): T | null {
  const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) ?? raw.match(/(\{[\s\S]*\})/);
  const jsonText = (jsonMatch?.[1] ?? raw).trim();
  try {
    return JSON.parse(jsonText) as T;
  } catch {
    return null;
  }
}

async function extractWithGemini(
  apiKey: string,
  itemName: string,
  description: string,
  validCodes: string[],
): Promise<IngredientExtraction | null> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: buildIngredientPrompt(itemName, description, validCodes) }] }],
          generationConfig: { temperature: 0.1, maxOutputTokens: 500, responseMimeType: "application/json" },
        }),
        signal: AbortSignal.timeout(20_000),
      },
    );
    if (!res.ok) return null;
    const data = await res.json() as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
    const raw = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!raw) return null;
    return extractJson<IngredientExtraction>(raw);
  } catch {
    return null;
  }
}

async function extractWithGemma(
  apiKey: string,
  itemName: string,
  description: string,
  validCodes: string[],
): Promise<IngredientExtraction | null> {
  try {
    const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemma-4-26b-a4b-it:free",
        max_tokens: 500,
        temperature: 0.1,
        messages: [{ role: "user", content: buildIngredientPrompt(itemName, description, validCodes) }],
      }),
      signal: AbortSignal.timeout(45_000),
    });
    if (!res.ok) return null;
    const data = await res.json() as { choices?: Array<{ message?: { content?: string } }> };
    const raw = data.choices?.[0]?.message?.content?.trim();
    if (!raw) return null;
    return extractJson<IngredientExtraction>(raw);
  } catch {
    return null;
  }
}

// PRIMARY: Gemini Flash-Lite (ücretsiz kota) — FALLBACK: OpenRouter Gemma (ücretsiz,
// ama günlük istek sınırı düşük olduğu için ana motor yapılmadı).
async function extractIngredients(
  itemName: string,
  description: string,
  validCodes: string[],
): Promise<{ result: IngredientExtraction; engine: "gemini" | "gemma" } | null> {
  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  if (geminiKey) {
    const result = await extractWithGemini(geminiKey, itemName, description, validCodes);
    if (result) return { result, engine: "gemini" };
  }

  const openrouterKey = Deno.env.get("OPENROUTER_API_KEY");
  if (openrouterKey) {
    const result = await extractWithGemma(openrouterKey, itemName, description, validCodes);
    if (result) return { result, engine: "gemma" };
  }

  return null;
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

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }
  if (!Deno.env.get("GEMINI_API_KEY") && !Deno.env.get("OPENROUTER_API_KEY")) {
    return json({ ok: false, error: "no_allergen_engine_configured" }, 500);
  }

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
  const businessId = String(body.business_id ?? "").trim();

  if (itemName.length < 2) {
    return json({ ok: false, error: "item_name_too_short" }, 400);
  }
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

  // Geçerli 14 alerjen kodu (DB'den — owner panelinin gerçekte kullandığı kodlarla
  // aynı kaynak, kod tabanında iki ayrı liste tutup uyuşmazlık riski almıyoruz).
  const { data: allergenRows } = await userClient.from("allergens").select("code");
  const validCodes = ((allergenRows ?? []) as Array<{ code: string }>).map((r) => r.code);
  if (validCodes.length === 0) {
    return json({ ok: false, error: "allergen_catalog_empty" }, 500);
  }

  const extraction = await extractIngredients(itemName, description, validCodes);
  if (!extraction) {
    return json({ ok: false, error: "detection_failed", detail: "no_engine_responded" }, 502);
  }

  const normalizedIngredients = Array.from(
    new Set((extraction.result.ingredients ?? []).map((i) => i.trim().toLowerCase()).filter(Boolean)),
  );

  // ── Aşama 2: deterministik kural motoru — hangi malzeme hangi alerjene karşılık
  // geliyor, AI değil bu sözlük belirler. ────────────────────────────────────
  let matchedAllergens: Array<{ code: string; status: "confirmed" | "possible"; evidence: string }> = [];
  let unmatchedIngredients: string[] = [];

  if (normalizedIngredients.length > 0) {
    const { data: aliasRows } = await userClient
      .from("allergen_ingredient_aliases")
      .select("ingredient, allergen_code")
      .in("ingredient", normalizedIngredients);

    const aliasMap = new Map<string, string[]>(); // ingredient -> allergen codes
    for (const row of (aliasRows ?? []) as Array<{ ingredient: string; allergen_code: string }>) {
      const existing = aliasMap.get(row.ingredient) ?? [];
      existing.push(row.allergen_code);
      aliasMap.set(row.ingredient, existing);
    }

    const confirmedByCode = new Map<string, string>(); // code -> evidence (first match wins)
    for (const ingredient of normalizedIngredients) {
      const codes = aliasMap.get(ingredient);
      if (!codes || codes.length === 0) {
        unmatchedIngredients.push(ingredient);
        continue;
      }
      for (const code of codes) {
        if (!confirmedByCode.has(code)) confirmedByCode.set(code, ingredient);
      }
    }

    matchedAllergens = Array.from(confirmedByCode.entries()).map(([code, evidence]) => ({
      code,
      status: "confirmed" as const,
      evidence,
    }));
  }

  // LLM'in hedge ettiği "possible" riskler — sadece geçerli kodlardan, ve
  // zaten "confirmed" olan bir kodu ezmez (confirmed her zaman kazanır).
  const confirmedCodes = new Set(matchedAllergens.map((a) => a.code));
  for (const risk of extraction.result.possibleRisks ?? []) {
    if (!validCodes.includes(risk.code)) continue;
    if (confirmedCodes.has(risk.code)) continue;
    matchedAllergens.push({ code: risk.code, status: "possible", evidence: risk.reason || "AI genel mutfak bilgisiyle işaretledi" });
  }

  const requiresBusinessConfirmation =
    matchedAllergens.some((a) => a.status === "possible") || unmatchedIngredients.length > 0;

  return json({
    ok: true,
    allergens: matchedAllergens,
    unmatchedIngredients,
    requiresBusinessConfirmation,
    engine: extraction.engine,
  });
});
