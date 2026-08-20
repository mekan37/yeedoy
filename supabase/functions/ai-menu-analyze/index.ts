import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Image } from "https://deno.land/x/imagescript@1.2.17/mod.ts";

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

// ─── Görsel ön işleme: EXIF orientation düzeltme + boyut/sıkıştırma ──────────
// OCR.Space Free API tek dosyada 1 MB sınırı koyuyor; telefon fotoğrafları
// (genelde 4-8 MB) bunun çok üzerinde. Ayrıca telefon kameraları fiziksel
// pikselleri hep aynı yönde kaydedip EXIF Orientation etiketiyle "nasıl
// döndürülmesi gerektiğini" ayrıca belirtir — bu etiket uygulanmazsa OCR
// motoruna yan/baş aşağı bir görüntü gider.

function getJpegExifOrientation(bytes: Uint8Array): number {
  // JPEG değilse ya da EXIF/Orientation etiketi yoksa 1 (normal) varsay.
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return 1;

  let offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] !== 0xff) break;
    const marker = bytes[offset + 1];
    if (marker === 0xd8 || marker === 0xd9) { offset += 2; continue; }
    const segmentLength = (bytes[offset + 2] << 8) + bytes[offset + 3];
    if (marker === 0xe1) {
      // APP1 — EXIF segmenti
      const exifStart = offset + 4;
      if (
        bytes[exifStart] === 0x45 && bytes[exifStart + 1] === 0x78 &&
        bytes[exifStart + 2] === 0x69 && bytes[exifStart + 3] === 0x66
      ) {
        const tiffStart = exifStart + 6;
        const little = bytes[tiffStart] === 0x49; // "II" little-endian, "MM" big-endian
        const readU16 = (p: number) => little ? bytes[p] | (bytes[p + 1] << 8) : (bytes[p] << 8) | bytes[p + 1];
        const readU32 = (p: number) => little
          ? (bytes[p] | (bytes[p + 1] << 8) | (bytes[p + 2] << 16) | (bytes[p + 3] << 24)) >>> 0
          : ((bytes[p] << 24) | (bytes[p + 1] << 16) | (bytes[p + 2] << 8) | bytes[p + 3]) >>> 0;

        const ifdOffset = tiffStart + readU32(tiffStart + 4);
        const entryCount = readU16(ifdOffset);
        for (let i = 0; i < entryCount; i++) {
          const entryOffset = ifdOffset + 2 + i * 12;
          const tag = readU16(entryOffset);
          if (tag === 0x0112) return readU16(entryOffset + 8);
        }
      }
      return 1;
    }
    offset += 2 + segmentLength;
  }
  return 1;
}

async function correctOrientation(bytes: Uint8Array): Promise<Uint8Array> {
  const orientation = getJpegExifOrientation(bytes);
  // Sadece saf döndürme gerektiren değerleri düzeltiyoruz (3/6/8 — telefon
  // fotoğraflarının neredeyse tamamı bu kümede). 2/4/5/7 aynalama gerektirir,
  // ImageScript'te güvenilir bir flip API'si olmadığından atlanıyor —
  // pratikte bu değerler tarayıcı/tarama cihazlarından gelir, telefon
  // kamerasından değil.
  if (orientation !== 3 && orientation !== 6 && orientation !== 8) return bytes;

  try {
    const img = await Image.decode(bytes);
    const degrees = orientation === 3 ? 180 : orientation === 6 ? 90 : 270;
    img.rotate(degrees);
    return await img.encodeJPEG(90);
  } catch (err) {
    console.warn("EXIF orientation correction failed, using original bytes:", err);
    return bytes;
  }
}

const OCR_SPACE_MAX_BYTES = 1_000_000;

async function fetchImageBytes(url: string): Promise<Uint8Array | null> {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(20_000) });
    if (!res.ok) return null;
    return new Uint8Array(await res.arrayBuffer());
  } catch {
    return null;
  }
}

async function ensureUnderSizeLimit(bytes: Uint8Array): Promise<Uint8Array> {
  if (bytes.length <= OCR_SPACE_MAX_BYTES) return bytes;

  try {
    const img = await Image.decode(bytes);
    const maxDimension = 1600;
    if (img.width > maxDimension || img.height > maxDimension) {
      if (img.width >= img.height) {
        img.resize(maxDimension, Image.RESIZE_AUTO);
      } else {
        img.resize(Image.RESIZE_AUTO, maxDimension);
      }
    }

    let quality = 85;
    let encoded = await img.encodeJPEG(quality);
    while (encoded.length > OCR_SPACE_MAX_BYTES && quality > 40) {
      quality -= 15;
      encoded = await img.encodeJPEG(quality);
    }
    return encoded;
  } catch (err) {
    console.warn("Image resize failed, sending original bytes:", err);
    return bytes;
  }
}

// ─── OCR.Space — Engine 1/3 router ───────────────────────────────────────────
// Replicate/DeepSeek-OCR'ın yerini aldı: tek senkron istek, Türkçe dil desteği,
// şeffaf ücretsiz kota (25K istek/ay, IP başına 500/gün). Engine 2 Türkçeyi
// desteklemiyor, hiç kullanılmıyor. Engine 3'ün ayrı ve daha dar bir kotası
// var (2.500 dönüşüm/ay) — bu yüzden körlemesine hep Engine 3 yerine önce
// hızlı/sınırsıza yakın Engine 1 deneniyor, sonucu yetersizse (boş/çok kısa —
// karmaşık font, tablo veya el yazısına işaret eder) Engine 3'e geçiliyor.

async function callOcrSpace(apiKey: string, bytes: Uint8Array, filename: string, engine: 1 | 3): Promise<string | null> {
  try {
    const form = new FormData();
    form.append("file", new Blob([bytes], { type: "image/jpeg" }), filename || "menu.jpg");
    form.append("language", "tur");
    form.append("OCREngine", String(engine));
    form.append("scale", "true");
    form.append("isTable", "true");

    const res = await fetch("https://api.ocr.space/parse/image", {
      method: "POST",
      headers: { apikey: apiKey },
      body: form,
      signal: AbortSignal.timeout(60_000),
    });

    if (!res.ok) {
      console.error(`OCR.Space HTTP error (engine ${engine}): ${res.status}`);
      return null;
    }

    const data = await res.json() as {
      IsErroredOnProcessing?: boolean;
      ErrorMessage?: string[] | string;
      ParsedResults?: Array<{ ParsedText?: string }>;
    };

    if (data.IsErroredOnProcessing) {
      console.warn(`OCR.Space processing error (engine ${engine}):`, data.ErrorMessage);
      return null;
    }

    const text = (data.ParsedResults ?? []).map((r) => r.ParsedText ?? "").join("\n").trim();
    return text || null;
  } catch (err) {
    console.error(`OCR.Space call failed (engine ${engine}):`, err);
    return null;
  }
}

// Bir menü fotoğrafında makul şekilde birkaç ürün satırı beklenir; sonuç bu
// eşiğin altında kalırsa Engine 1 muhtemelen metni okuyamamıştır.
const MIN_ACCEPTABLE_TEXT_LENGTH = 20;

async function runOcrSpaceRouter(apiKey: string, bytes: Uint8Array, filename: string): Promise<{ text: string; engine: "ocr-space" | "ocr-space-e3" } | null> {
  const engine1Text = await callOcrSpace(apiKey, bytes, filename, 1);
  if (engine1Text && engine1Text.length >= MIN_ACCEPTABLE_TEXT_LENGTH) {
    return { text: engine1Text, engine: "ocr-space" };
  }

  const engine3Text = await callOcrSpace(apiKey, bytes, filename, 3);
  if (engine3Text) return { text: engine3Text, engine: "ocr-space-e3" };

  // Engine 3 de başarısız olduysa Engine 1'in (varsa) kısa sonucunu kullan —
  // hiç bulunamamaktan iyidir.
  return engine1Text ? { text: engine1Text, engine: "ocr-space" } : null;
}

// ─── Aşama 2: Gemini ile yapılandırma — SADECE isim/açıklama/fiyat/kategori ──
// Alerjen ve kalori tahmini artık burada YAPILMIYOR — bunlar bağımsız,
// deterministik kural motoruna dayanan ai-allergen-detect/ai-nutrition-estimate
// fonksiyonlarının işi (sahip, oluşturulan ürün üzerinde ayrıca "AI ile
// doldur" ile tetikler). OCR'ın tek görevi metni gerçek menü yapısına
// (kategori → ürün → fiyat) dönüştürmek; metinde olmayan bilgi UYDURULMAZ.

interface StructuredItem {
  source_text: string;
  normalized_text: string;
  description: string | null;
  category_name: string | null;
  price_cents: number | null;
  currency: string;
  confidence: number;
  requires_review: boolean;
}

function buildStructurePrompt(rawText: string): string {
  return `Convert this OCR output from a Turkish restaurant menu into structured JSON. Do NOT invent information that is not in the text. Missing fields must be null. Do NOT alter prices. Preserve category groupings as they appear in the text.

OCR text:
${rawText}

Return ONLY valid JSON, no markdown, with this exact structure:
{
  "categories": [
    {
      "name": "category name as it appears (e.g. Çorbalar) — null if the text has no categories",
      "items": [
        {
          "source_text": "the original OCR line for this item",
          "name": "cleaned product name",
          "description": "any descriptive text after the name, null if none",
          "price": 120.00,
          "currency": "TRY",
          "confidence": 0.87
        }
      ]
    }
  ]
}`;
}

async function structureWithGemini(apiKey: string, rawText: string): Promise<StructuredItem[]> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: buildStructurePrompt(rawText) }] }],
        generationConfig: { temperature: 0.1, maxOutputTokens: 4096, responseMimeType: "application/json" },
      }),
      signal: AbortSignal.timeout(30_000),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`gemini_api_error: ${res.status} ${err}`);
  }

  const data = await res.json() as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
  const raw = data.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  const jsonMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/) ?? raw.match(/(\{[\s\S]*\})/);
  const jsonText = (jsonMatch?.[1] ?? raw).trim();
  const parsed = JSON.parse(jsonText) as { categories?: unknown[] };

  const results: StructuredItem[] = [];
  for (const cat of parsed.categories ?? []) {
    const c = cat as Record<string, unknown>;
    const categoryName = typeof c.name === "string" && c.name.trim() ? c.name.trim() : null;
    const items = Array.isArray(c.items) ? c.items : [];
    for (const it of items) {
      const i = it as Record<string, unknown>;
      const priceRaw = typeof i.price === "number" ? i.price : null;
      results.push({
        source_text: String(i.source_text ?? ""),
        normalized_text: String(i.name ?? i.source_text ?? "").trim(),
        description: typeof i.description === "string" && i.description.trim() ? i.description.trim() : null,
        category_name: categoryName,
        price_cents: priceRaw !== null ? Math.round(priceRaw * 100) : null,
        currency: typeof i.currency === "string" && i.currency.trim() ? i.currency.trim() : "TRY",
        confidence: Math.min(1, Math.max(0, Number(i.confidence ?? 0))),
        requires_review: Number(i.confidence ?? 0) < 0.85,
      });
    }
  }
  return results.filter((r) => r.normalized_text.length > 0);
}

// ─── main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ ok: false, error: "missing_jwt" }, 401);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
  // OCR.Space — optional; job zaten bir raw_text ile geldiyse (manuel giriş
  // veya önceki bir deneme) o metinle devam edilir.
  const OCR_SPACE_API_KEY = Deno.env.get("OCR_SPACE_API_KEY");

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }
  if (!GEMINI_API_KEY) {
    return json({ ok: false, error: "missing_gemini_key" }, 500);
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) return json({ ok: false, error: "not_authenticated" }, 401);
  const userId = userRes.user.id;

  try { await enforceRateLimit(userId, "ai-menu-analyze", 5); }
  catch (r) { return r as Response; }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, error: "invalid_json" }, 400);
  }

  const jobId = asNonEmptyString(body.job_id);
  if (!jobId) return json({ ok: false, error: "missing_job_id" }, 400);

  const { data: job, error: jobErr } = await adminClient
    .from("menu_ocr_jobs")
    .select("id, business_id, owner_id, file_url, file_name, raw_text, status")
    .eq("id", jobId)
    .maybeSingle();

  if (jobErr || !job) return json({ ok: false, error: "job_not_found" }, 404);
  if (job.owner_id !== userId) return json({ ok: false, error: "forbidden" }, 403);
  if (job.status === "processing") return json({ ok: false, error: "already_processing" }, 409);
  if (job.status === "completed") return json({ ok: false, error: "already_completed" }, 409);

  await adminClient
    .from("menu_ocr_jobs")
    .update({ status: "processing" })
    .eq("id", jobId);

  try {
    // ── Step 1: OCR — OCR.Space (Engine 1 → Engine 3 escalation), raw_text fallback ──
    let rawText: string | null = asNonEmptyString(job.raw_text);

    if (OCR_SPACE_API_KEY) {
      const imageBytes = await fetchImageBytes(job.file_url as string);
      if (imageBytes) {
        const oriented = await correctOrientation(imageBytes);
        const sized = await ensureUnderSizeLimit(oriented);
        const ocrResult = await runOcrSpaceRouter(OCR_SPACE_API_KEY, sized, (job.file_name as string) ?? "menu.jpg");
        if (ocrResult) {
          rawText = ocrResult.text;
          await adminClient
            .from("menu_ocr_jobs")
            .update({ raw_text: ocrResult.text, ocr_engine: ocrResult.engine })
            .eq("id", jobId);
        } else {
          console.warn(`OCR.Space returned no text for job ${jobId}; continuing with existing raw_text`);
        }
      }
    }

    if (!rawText || rawText.trim().length < 3) {
      await adminClient.from("menu_ocr_jobs").update({
        status: "failed",
        error_message: "no_text_extracted",
      }).eq("id", jobId);
      return json({ ok: false, error: "no_text_extracted" }, 422);
    }

    // ── Step 2: Gemini structuring (name/description/price/category only) ──
    const items = await structureWithGemini(GEMINI_API_KEY, rawText);

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
      description_text: item.description,
      category_name: item.category_name,
      price_cents: item.price_cents,
      currency: item.currency,
      confidence: item.confidence,
      requires_review: item.requires_review,
      status: "pending_review",
      ai_model: "gemini-2.5-flash-lite",
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
