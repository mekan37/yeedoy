'use server';

import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { rateLimit } from '@/src/lib/rate-limit';

// ─── Types ─────────────────────────────────────────────────────────────────────

export type Isletme = { id: string; name: string };

export type AnalizOgesi = {
  id: string;
  ocr_job_id: string | null;
  source_text: string;
  normalized_text: string | null;
  ingredients_json: string[] | null;
  allergens_json: string[] | null;
  calorie_min: number | null;
  calorie_max: number | null;
  confidence: number;
  requires_review: boolean;
  status: string;
  ai_model: string | null;
};

export type AnalizGirdisi =
  | { tur: 'gorsel_url'; deger: string }
  | { tur: 'ham_metin'; deger: string };

export type AnalizBaslatSonucu =
  | { basarili: true; job_id: string; ogeler: AnalizOgesi[] }
  | { basarili: false; hata: string };

// ─── Validation ────────────────────────────────────────────────────────────────

const AnalizGirdisiSchema = z.union([
  z.object({ tur: z.literal('gorsel_url'), deger: z.string().url() }),
  z.object({ tur: z.literal('ham_metin'), deger: z.string().min(1).max(50_000) }),
]);

const AnalizBaslatSchema = z.object({
  isletmeId: z.string().uuid(),
  girdi: AnalizGirdisiSchema,
});

// ─── Action: menu_ocr_jobs oluştur + ai-menu-analyze edge function tetikle ────
//
// Kaynak: owner tarafının /api/owner/ai-analyze route.ts + ai-analysis-client.tsx
// mantığı (2026-07-10, daha güncel) — bu action olarak taşındı.
// Edge function: POST /functions/v1/ai-menu-analyze { job_id }
// Auth: Bearer <access_token>
//
// Edge fn dönüş:
//   200 { ok: true,  item_count: number }
//   400 { ok: false, error: "missing_job_id" | "invalid_json" }
//   401 { ok: false, error: "missing_jwt" | "not_authenticated" }
//   403 { ok: false, error: "forbidden" }
//   404 { ok: false, error: "job_not_found" }
//   409 { ok: false, error: "already_processing" | "already_completed" }
//   422 { ok: false, error: "no_text_extracted" | "no_items_detected" }
//   500 { ok: false, error: "missing_openrouter_key" | "analysis_failed" | ... }
export async function analizBaslat(
  isletmeId: string,
  girdi: AnalizGirdisi,
): Promise<AnalizBaslatSonucu> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const rl = rateLimit(`owner-ai-analyze:${user.id}`, 5, 3_600_000);
  if (!rl.ok)
    return { basarili: false, hata: 'Saatlik limit aşıldı. Lütfen daha sonra tekrar deneyin.' };

  const parsed = AnalizBaslatSchema.safeParse({ isletmeId, girdi });
  if (!parsed.success) return { basarili: false, hata: 'Geçersiz istek parametreleri.' };

  const yetkiVar = await hasOwnerBusiness(supabase as any, user.id, isletmeId);
  if (!yetkiVar) return { basarili: false, hata: 'Bu işletme için yetkiniz yok.' };

  // menu_ocr_jobs kaydı oluştur. status alanı 'queued' | 'processing' |
  // 'completed' | 'failed' değerlerini kabul eder (bkz. menu_ocr_jobs CHECK
  // constraint) — yeni kayıt 'queued' ile başlar.
  //
  // BİLİNEN SORUN: file_url kolonu migration'da NOT NULL
  // (supabase/migrations/_archive/20260411000001_ai_menu_analysis_v1.sql).
  // 'ham_metin' girişinde file_url=null gönderiliyor; bu durumda insert
  // DB constraint hatasıyla başarısız olur. Owner'ın orijinal
  // /api/owner/ai-analyze route.ts'inde de aynı sorun vardı — bu taşıma
  // sırasında miras alındı, düzeltmek migration değişikliği gerektirir
  // (kapsam dışı bırakıldı).
  const { data: job, error: jobError } = await (supabase as any)
    .from('menu_ocr_jobs')
    .insert({
      business_id: isletmeId,
      owner_id: user.id,
      file_url: girdi.tur === 'gorsel_url' ? girdi.deger : null,
      raw_text: girdi.tur === 'ham_metin' ? girdi.deger : null,
      status: 'queued',
    })
    .select('id')
    .single();

  if (jobError || !job) {
    return { basarili: false, hata: 'Analiz görevi oluşturulamadı. Lütfen tekrar deneyin.' };
  }

  const jobId = (job as { id: string }).id;

  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session?.access_token)
    return { basarili: false, hata: 'Oturum süresi dolmuş.' };

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  if (!supabaseUrl) return { basarili: false, hata: 'Sistem yapılandırma hatası.' };

  let respStatus: number;
  let respData: Record<string, unknown>;

  try {
    const res = await fetch(`${supabaseUrl}/functions/v1/ai-menu-analyze`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ job_id: jobId }),
      // Edge fn'in DeepSeek OCR poll'u 60s + Replicate ~70s sürebilir
      signal: AbortSignal.timeout(140_000),
    });
    respStatus = res.status;
    respData = (await res.json()) as Record<string, unknown>;
  } catch {
    return { basarili: false, hata: 'Ağ hatası. Lütfen tekrar deneyin.' };
  }

  if (respStatus === 200 && respData.ok === true) {
    const { data: ogeler, error: fetchError } = await (supabase as any)
      .from('menu_item_ai_analysis')
      .select('*')
      .eq('ocr_job_id', jobId);

    if (fetchError) return { basarili: false, hata: 'Sonuçlar alınamadı.' };

    return { basarili: true, job_id: jobId, ogeler: (ogeler ?? []) as AnalizOgesi[] };
  }

  const errCode = String(respData.error ?? '');

  // OPENROUTER_API_KEY eksik — provider adını sızdırma
  if (
    respStatus === 500 &&
    (errCode === 'missing_openrouter_key' ||
      errCode.includes('provider') ||
      errCode.includes('api_key'))
  ) {
    return { basarili: false, hata: 'AI analiz motoru şu an yapılandırılıyor.' };
  }

  if (respStatus === 403) return { basarili: false, hata: 'Bu işletme için yetkiniz yok.' };
  if (respStatus === 404) return { basarili: false, hata: 'Analiz görevi bulunamadı.' };
  if (respStatus === 409 && errCode === 'already_completed')
    return { basarili: false, hata: 'Bu görev zaten tamamlandı.' };
  if (respStatus === 409 && errCode === 'already_processing')
    return { basarili: false, hata: 'Bu görev zaten işleniyor, lütfen bekleyin.' };
  if (respStatus === 422 && errCode === 'no_text_extracted')
    return {
      basarili: false,
      hata: 'Menü görselinden metin çıkarılamadı. Daha net bir fotoğraf yükleyin.',
    };
  if (respStatus === 422 && errCode === 'no_items_detected')
    return {
      basarili: false,
      hata: 'Menüde ürün tespit edilemedi. Ham metni kontrol edin.',
    };

  return { basarili: false, hata: 'Analiz şu an kullanılamıyor. Lütfen tekrar deneyin.' };
}
