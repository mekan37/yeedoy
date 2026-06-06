'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

// ─── Types ─────────────────────────────────────────────────────────────────────

export type OcrJobDurumu = {
  id: string;
  file_name: string | null;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  item_count: number | null;
  error_message: string | null;
  created_at: string;
  updated_at: string;
};

export type AnalizSonucu = {
  id: string;
  ocr_job_id: string | null;
  source_text: string;
  normalized_text: string | null;
  ingredients_json: string[];
  allergens_json: string[];
  calorie_min: number | null;
  calorie_max: number | null;
  confidence: number;
  requires_review: boolean;
  status: 'pending_review' | 'approved' | 'rejected';
  created_at: string;
};

export type IslemSonucu<T> =
  | { basarili: true; veri: T }
  | { basarili: false; hata: string };

export type AnalizBaslatSonucu =
  | { basarili: true; item_count: number }
  | { basarili: false; hata: string; providerYapılandırılmamış?: boolean };

// ─── Action: list_menu_ocr_jobs_v1 ───────────────────────────────────────────

export async function isleriniListele(
  businessId: string,
): Promise<IslemSonucu<OcrJobDurumu[]>> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const yetkiVar = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!yetkiVar)
    return { basarili: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };

  const { data, error } = await (supabase as any).rpc('list_menu_ocr_jobs_v1', {
    p_business_id: businessId,
    p_limit: 10,
    p_offset: 0,
  });

  if (error) {
    return { basarili: false, hata: 'İş listesi alınamadı.' };
  }

  const rows = (data ?? []) as OcrJobDurumu[];
  return { basarili: true, veri: rows };
}

// ─── Action: create_menu_ocr_job_v1 + trigger edge function ───────────────────

/**
 * Mevcut bir OCR job'ı edge function'a göndererek analizi başlatır.
 * job_id parametresi: daha önce create_menu_ocr_job_v1 ile oluşturulmuş bir kayıt.
 * Edge function: POST /functions/v1/ai-menu-analyze { job_id }
 * Auth: Bearer <access_token>
 *
 * Edge fn dönüş:
 *   200 { ok: true,  item_count: number }
 *   400 { ok: false, error: "missing_job_id" | "invalid_json" }
 *   401 { ok: false, error: "missing_jwt" | "not_authenticated" }
 *   403 { ok: false, error: "forbidden" }
 *   404 { ok: false, error: "job_not_found" }
 *   409 { ok: false, error: "already_processing" | "already_completed" }
 *   422 { ok: false, error: "no_text_extracted" | "no_items_detected" }
 *   500 { ok: false, error: "missing_openrouter_key" | "analysis_failed" | ... }
 */
export async function analizBaslat(
  businessId: string,
  jobId: string,
): Promise<AnalizBaslatSonucu> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  // Defense-in-depth: edge function da kendi owner kontrolünü yapıyor
  const yetkiVar = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!yetkiVar)
    return { basarili: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };

  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session?.access_token)
    return { basarili: false, hata: 'Oturum süresi dolmuş.' };

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl)
    return { basarili: false, hata: 'Sistem yapılandırma hatası.' };

  let respData: Record<string, unknown>;
  let respStatus: number;

  try {
    const res = await fetch(
      `${supabaseUrl}/functions/v1/ai-menu-analyze`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ job_id: jobId }),
        // Edge fn'in DeepSeek OCR poll'u 60s + Replicate ~70s sürebilir
        signal: AbortSignal.timeout(140_000),
      },
    );

    respStatus = res.status;
    respData = (await res.json()) as Record<string, unknown>;
  } catch {
    return { basarili: false, hata: 'Ağ hatası. Lütfen tekrar deneyin.' };
  }

  if (respStatus === 200 && respData.ok === true) {
    const itemCount =
      typeof respData.item_count === 'number' ? respData.item_count : 0;
    return { basarili: true, item_count: itemCount };
  }

  const errCode = String(respData.error ?? '');

  // OPENROUTER_API_KEY eksik — provider adını sızdırma
  if (
    respStatus === 500 &&
    (errCode === 'missing_openrouter_key' ||
      errCode.includes('provider') ||
      errCode.includes('api_key'))
  ) {
    return {
      basarili: false,
      hata: 'AI analiz motoru şu an yapılandırılıyor.',
      providerYapılandırılmamış: true,
    };
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

// ─── Action: list_menu_ai_analysis_v1 ─────────────────────────────────────────

export async function analizSonuclariniGetir(
  businessId: string,
  jobId?: string,
): Promise<IslemSonucu<AnalizSonucu[]>> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const yetkiVar = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!yetkiVar)
    return { basarili: false, hata: 'Bu işletmeye erişim yetkiniz yok.' };

  const { data, error } = await (supabase as any).rpc(
    'list_menu_ai_analysis_v1',
    {
      p_business_id: businessId,
      p_status: null,
      p_ocr_job_id: jobId ?? null,
      p_limit: 50,
      p_offset: 0,
    },
  );

  if (error) {
    return { basarili: false, hata: 'Analiz sonuçları alınamadı.' };
  }

  const rows = (data ?? []) as AnalizSonucu[];
  return { basarili: true, veri: rows };
}

// ─── Action: approve_menu_ai_analysis_v1 ──────────────────────────────────────

export async function analiziOnayla(
  analysisId: string,
): Promise<IslemSonucu<void>> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const { error } = await (supabase as any).rpc(
    'approve_menu_ai_analysis_v1',
    { p_analysis_id: analysisId },
  );

  if (error) {
    return { basarili: false, hata: 'Onaylama başarısız.' };
  }
  return { basarili: true, veri: undefined };
}

// ─── Action: reject_menu_ai_analysis_v1 ───────────────────────────────────────

export async function analiziReddet(
  analysisId: string,
): Promise<IslemSonucu<void>> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { basarili: false, hata: 'Oturum açmanız gerekiyor.' };

  const { error } = await (supabase as any).rpc(
    'reject_menu_ai_analysis_v1',
    { p_analysis_id: analysisId },
  );

  if (error) {
    return { basarili: false, hata: 'Reddetme başarısız.' };
  }
  return { basarili: true, veri: undefined };
}
