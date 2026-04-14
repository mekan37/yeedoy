import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── helpers ───────────────────────────────────────────────────────────────

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function asNonEmptyString(v: unknown): string | null {
  const s = String(v ?? "").trim();
  return s.length > 0 ? s : null;
}

// ─── PaddleOCR service call ─────────────────────────────────────────────────

interface PaddleOcrLine {
  text: string;
  confidence: number;
}

interface PaddleOcrResult {
  ok: boolean;
  raw_text?: string;
  lines?: PaddleOcrLine[];
  error?: string;
}

async function runPaddleOcr(
  serviceUrl: string,
  serviceSecret: string,
  imageUrl: string,
): Promise<string | null> {
  try {
    const res = await fetch(`${serviceUrl}/ocr`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-service-secret": serviceSecret,
      },
      body: JSON.stringify({ image_url: imageUrl }),
      // 45s timeout — PaddleOCR can be slow on first run
      signal: AbortSignal.timeout(45_000),
    });

    if (!res.ok) {
      console.error(`PaddleOCR service error: ${res.status}`);
      return null;
    }

    const data = (await res.json()) as PaddleOcrResult;
    if (!data.ok || !data.raw_text) return null;
    return data.raw_text;
  } catch (err) {
    console.error("PaddleOCR call failed:", err);
    return null;
  }
}

// ─── Claude structured analysis ─────────────────────────────────────────────

const ALLERGEN_CODES = [
  "gluten", "crustaceans", "eggs", "fish", "peanuts",
  "soybeans", "milk", "nuts", "celery", "mustard",
  "sesame", "sulphites", "lupin", "molluscs",
];

const SYSTEM_PROMPT = `You are a food menu analysis assistant. Analyze the given menu text and return a structured JSON response.

RULES:
- Each item must have a confidence score between 0.0 and 1.0
- allergens must only contain codes from this list: ${ALLERGEN_CODES.join(", ")}
- calorie_min and calorie_max must be reasonable estimates in kcal (null if unknown)
- ingredients must be an array of Turkish/English ingredient names
- requires_review must be true when confidence < 0.85
- normalized_text should be the cleaned product name
- Skip lines that are clearly prices, headers, or section separators

Return ONLY valid JSON with this exact structure:
{
  "items": [
    {
      "source_text": "original line from menu",
      "normalized_text": "cleaned product name",
      "ingredients": ["ingredient1", "ingredient2"],
      "allergens": ["gluten", "milk"],
      "calorie_min": 320,
      "calorie_max": 420,
      "confidence": 0.87,
      "requires_review": false
    }
  ]
}`;

interface AnalysisItem {
  source_text: string;
  normalized_text: string;
  ingredients: string[];
  allergens: string[];
  calorie_min: number | null;
  calorie_max: number | null;
  confidence: number;
  requires_review: boolean;
}

async function analyzeWithOpenRouter(
  apiKey: string,
  rawText: string,
): Promise<AnalysisItem[]> {
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: "meta-llama/llama-3.1-8b-instruct:free",
      max_tokens: 4096,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: `Analyze the following menu text extracted by OCR and extract all food items:\n\n${rawText}`,
        },
      ],
    }),
    signal: AbortSignal.timeout(60_000),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`openrouter_api_error: ${res.status} ${err}`);
  }

  const data = await res.json() as {
    choices: Array<{ message: { content: string } }>;
  };
  const text = data.choices?.[0]?.message?.content ?? "";

  // Extract JSON — may be wrapped in markdown code block
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/) ??
    text.match(/(\{[\s\S]*\})/);
  const jsonText = jsonMatch?.[1] ?? text;

  const parsed = JSON.parse(jsonText.trim()) as { items?: unknown[] };
  const items = parsed.items ?? [];

  return items.map((item) => {
    const i = item as Record<string, unknown>;
    return {
      source_text: String(i.source_text ?? ""),
      normalized_text: String(i.normalized_text ?? i.source_text ?? ""),
      ingredients: Array.isArray(i.ingredients)
        ? (i.ingredients as string[]).filter((x) => typeof x === "string")
        : [],
      allergens: Array.isArray(i.allergens)
        ? (i.allergens as string[]).filter((x) => ALLERGEN_CODES.includes(x as string))
        : [],
      calorie_min: typeof i.calorie_min === "number" ? i.calorie_min : null,
      calorie_max: typeof i.calorie_max === "number" ? i.calorie_max : null,
      confidence: Math.min(1, Math.max(0, Number(i.confidence ?? 0))),
      requires_review: Boolean(i.requires_review ?? true),
    };
  });
}

// ─── main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ ok: false, error: "missing_jwt" }, 401);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY");
  // PaddleOCR service — optional; falls back to raw_text already in DB if unset
  const PADDLE_OCR_URL = Deno.env.get("PADDLE_OCR_URL");
  const PADDLE_OCR_SECRET = Deno.env.get("PADDLE_OCR_SECRET") ?? "";

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }
  if (!OPENROUTER_API_KEY) {
    return json({ ok: false, error: "missing_openrouter_key" }, 500);
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) return json({ ok: false, error: "not_authenticated" }, 401);
  const userId = userRes.user.id;

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, error: "invalid_json" }, 400);
  }

  const jobId = asNonEmptyString(body.job_id);
  if (!jobId) return json({ ok: false, error: "missing_job_id" }, 400);

  // Fetch job
  const { data: job, error: jobErr } = await adminClient
    .from("menu_ocr_jobs")
    .select("id, business_id, owner_id, file_url, raw_text, status")
    .eq("id", jobId)
    .maybeSingle();

  if (jobErr || !job) return json({ ok: false, error: "job_not_found" }, 404);
  if (job.owner_id !== userId) return json({ ok: false, error: "forbidden" }, 403);
  if (job.status === "processing") return json({ ok: false, error: "already_processing" }, 409);
  if (job.status === "completed") return json({ ok: false, error: "already_completed" }, 409);

  // Mark as processing
  await adminClient
    .from("menu_ocr_jobs")
    .update({ status: "processing" })
    .eq("id", jobId);

  try {
    // ── Step 1: OCR — PaddleOCR preferred, fall back to existing raw_text ──
    let rawText: string | null = asNonEmptyString(job.raw_text);

    if (PADDLE_OCR_URL) {
      const paddleText = await runPaddleOcr(
        PADDLE_OCR_URL,
        PADDLE_OCR_SECRET,
        job.file_url as string,
      );
      if (paddleText) {
        rawText = paddleText;
        // Persist OCR output for audit
        await adminClient
          .from("menu_ocr_jobs")
          .update({ raw_text: paddleText, ocr_engine: "paddleocr" })
          .eq("id", jobId);
      } else {
        console.warn(`PaddleOCR returned no text for job ${jobId}; continuing with existing raw_text`);
      }
    }

    if (!rawText || rawText.trim().length < 3) {
      await adminClient.from("menu_ocr_jobs").update({
        status: "failed",
        error_message: "no_text_extracted",
      }).eq("id", jobId);
      return json({ ok: false, error: "no_text_extracted" }, 422);
    }

    // ── Step 2: AI analysis ──
    const items = await analyzeWithOpenRouter(OPENROUTER_API_KEY, rawText);

    if (items.length === 0) {
      await adminClient.from("menu_ocr_jobs").update({
        status: "failed",
        error_message: "no_items_detected",
      }).eq("id", jobId);
      return json({ ok: false, error: "no_items_detected" }, 422);
    }

    // ── Step 3: Store results ──
    const analysisRows = items.map((item) => ({
      ocr_job_id: jobId,
      business_id: job.business_id,
      source_text: item.source_text,
      normalized_text: item.normalized_text,
      ingredients_json: item.ingredients,
      allergens_json: item.allergens,
      calorie_min: item.calorie_min,
      calorie_max: item.calorie_max,
      confidence: item.confidence,
      requires_review: item.requires_review,
      status: "pending_review",
      ai_model: "meta-llama/llama-3.1-8b-instruct:free",
    }));

    const { error: insertErr } = await adminClient
      .from("menu_item_ai_analysis")
      .insert(analysisRows);

    if (insertErr) {
      await adminClient.from("menu_ocr_jobs").update({
        status: "failed",
        error_message: `insert_failed: ${insertErr.message}`,
      }).eq("id", jobId);
      return json({ ok: false, error: "insert_failed", detail: insertErr.message }, 500);
    }

    await adminClient.from("menu_ocr_jobs").update({
      status: "completed",
      item_count: items.length,
      parsed_output: items,
    }).eq("id", jobId);

    return json({ ok: true, item_count: items.length });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    await adminClient.from("menu_ocr_jobs").update({
      status: "failed",
      error_message: msg,
    }).eq("id", jobId);
    return json({ ok: false, error: "analysis_failed", detail: msg }, 500);
  }
});
