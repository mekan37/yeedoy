'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

async function requireOwnedBusiness(businessId: string) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false as const, error: 'Oturum bulunamadı' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase as any, user.id);
  if (!ownerBusinessIds.includes(businessId)) {
    return { ok: false as const, error: 'Bu işletme için yetkiniz yok' };
  }
  return { ok: true as const, supabase };
}

export async function ocrTaramasiBaslat(
  businessId: string,
  fileUrl: string,
  fileName: string,
): Promise<{ error: string } | { jobId: string }> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { data, error } = await (context.supabase as any).rpc('create_menu_ocr_job_v1', {
    p_business_id: businessId,
    p_file_url: fileUrl,
    p_file_name: fileName,
  }) as { data: string | null; error: { message: string } | null };

  if (error) {
    if (error.message.includes('plan_limit_exceeded')) {
      return { error: 'Bu ay OCR tarama limitinize ulaştınız. Planınızı yükseltin.' };
    }
    return { error: error.message };
  }

  const { error: invokeError } = await context.supabase.functions.invoke('ai-menu-analyze', {
    body: { job_id: data },
  });
  if (invokeError) return { error: 'Tarama başlatılamadı: ' + invokeError.message };

  return { jobId: data as string };
}

export async function ocrTaramaDurumu(
  businessId: string,
  jobId: string,
): Promise<
  | { error: string }
  | {
      status: string;
      itemCount: number | null;
      errorMessage: string | null;
      analizler: Array<{
        id: string;
        sourceText: string;
        normalizedText: string | null;
        allergens: string[];
        calorieMin: number | null;
        calorieMax: number | null;
        confidence: number;
        status: string;
      }>;
    }
> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { data: jobs, error: jobError } = await (context.supabase as any).rpc('list_menu_ocr_jobs_v1', {
    p_business_id: businessId,
    p_limit: 50,
    p_offset: 0,
  }) as { data: Array<{ id: string; status: string; item_count: number | null; error_message: string | null }> | null; error: { message: string } | null };

  if (jobError) return { error: jobError.message };
  const job = (jobs ?? []).find((j) => j.id === jobId);
  if (!job) return { error: 'Tarama bulunamadı' };

  const { data: analizler, error: analizError } = await (context.supabase as any).rpc('list_menu_ai_analysis_v1', {
    p_business_id: businessId,
    p_ocr_job_id: jobId,
    p_status: 'pending_review',
    p_limit: 100,
    p_offset: 0,
  }) as {
    data: Array<{
      id: string;
      source_text: string;
      normalized_text: string | null;
      allergens_json: string[];
      calorie_min: number | null;
      calorie_max: number | null;
      confidence: number;
      status: string;
    }> | null;
    error: { message: string } | null;
  };

  if (analizError) return { error: analizError.message };

  return {
    status: job.status,
    itemCount: job.item_count,
    errorMessage: job.error_message,
    analizler: (analizler ?? []).map((a) => ({
      id: a.id,
      sourceText: a.source_text,
      normalizedText: a.normalized_text,
      allergens: a.allergens_json ?? [],
      calorieMin: a.calorie_min,
      calorieMax: a.calorie_max,
      confidence: a.confidence,
      status: a.status,
    })),
  };
}

export async function ocrOnerisiniMenuyeEkle(
  businessId: string,
  analysisId: string,
  sectionId: string,
): Promise<{ error: string } | { itemId: string }> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { data, error } = await (context.supabase as any).rpc('apply_menu_ai_analysis_v1', {
    p_analysis_id: analysisId,
    p_section_id: sectionId,
  }) as { data: string | null; error: { message: string } | null };

  if (error) {
    if (error.message.includes('plan_limit_exceeded')) {
      return { error: 'Ürün limitine ulaştınız. Planınızı yükseltin.' };
    }
    return { error: error.message };
  }

  revalidatePath('/sahip/menuler');
  return { itemId: data as string };
}

export async function ocrOnerisiniReddet(
  businessId: string,
  analysisId: string,
): Promise<{ error: string } | null> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { error } = await (context.supabase as any).rpc('reject_menu_ai_analysis_v1', {
    p_analysis_id: analysisId,
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  return null;
}
