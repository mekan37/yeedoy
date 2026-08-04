'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

export type AiDoldurmaSonuc =
  | { error: string }
  | {
      allergens: string[];
      calorieMin: number | null;
      calorieMax: number | null;
    };

export async function aiIleAlerjenKaloriDoldur(
  businessId: string,
  itemName: string,
  description: string,
): Promise<AiDoldurmaSonuc> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
  if (!ownerBusinessIds.includes(businessId)) return { error: 'Bu işletme için yetkiniz yok' };

  const { error: limitError } = (await (supabase as any).rpc('_check_plan_limit_v1', {
    p_business_id: businessId,
    p_feature_key: 'allergen_ai',
  })) as { error: { message: string } | null };
  if (limitError) return { error: 'Bu özellik planınızda yok. Standart kademeye yükseltin.' };

  const [allergenRes, nutritionRes] = await Promise.all([
    supabase.functions.invoke('ai-allergen-detect', {
      body: { item_name: itemName, description },
    }),
    supabase.functions.invoke('ai-nutrition-estimate', {
      body: { item_name: itemName, description },
    }),
  ]);

  if (allergenRes.error) return { error: 'Alerjen tespiti başarısız: ' + allergenRes.error.message };
  if (nutritionRes.error) return { error: 'Kalori tahmini başarısız: ' + nutritionRes.error.message };

  const allergenData = allergenRes.data as { ok: boolean; allergens?: Array<{ allergen: string; risk: string }> };
  const nutritionData = nutritionRes.data as { ok: boolean; calorie_min?: number; calorie_max?: number };

  if (!allergenData.ok || !nutritionData.ok) {
    return { error: 'AI otomasyonu şu an kullanılamıyor.' };
  }

  return {
    allergens: (allergenData.allergens ?? []).map((entry) => entry.allergen),
    calorieMin: nutritionData.calorie_min ?? null,
    calorieMax: nutritionData.calorie_max ?? null,
  };
}

export async function aiIleGorselUret(
  businessId: string,
  itemName: string,
): Promise<{ error: string } | { imageUrl: string }> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
  if (!ownerBusinessIds.includes(businessId)) return { error: 'Bu işletme için yetkiniz yok' };

  const { error: limitError } = (await (supabase as any).rpc('_check_plan_limit_v1', {
    p_business_id: businessId,
    p_feature_key: 'ai_image_gen',
  })) as { error: { message: string } | null };
  if (limitError) return { error: 'Bu özellik yalnızca Pro kademede var.' };

  const { data, error } = await supabase.functions.invoke('ai-menu-image-gen', {
    body: { item_name: itemName },
  });
  if (error) return { error: 'Görsel üretilemedi: ' + error.message };

  const payload = data as { ok: boolean; image_url?: string };
  if (!payload.ok || !payload.image_url) return { error: 'Görsel üretilemedi.' };

  return { imageUrl: payload.image_url };
}
