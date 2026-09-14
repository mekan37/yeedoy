'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';

export async function decideAppeal(appealId: string, decision: 'approved' | 'rejected') {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;
  // RPC zaten is_admin() ile korunuyor — burada page:itirazlar kontrolü
  // savunma-derinliği için ekleniyor (withAdminAuth hiç kullanılmayan bir
  // sarmalayıcıydı, server action'lar bu ikinci katmandan tamamen yoksundu).
  if (!(await hasPermission('page:itirazlar'))) return;

  // Doğrudan tablo yazması hem ikinci katman yetki kontrolü içermiyordu
  // (yalnızca RLS'e güveniyordu — admin_users/community_mod olmayan biri
  // için sessizce 0 satır güncellenirdi) hem de hata hiç kontrol
  // edilmiyordu. Zaten var olan, guard'lı ve gerçek satır kontrolü yapan
  // RPC'ye taşındı.
  const { data, error } = await (supabase).rpc('admin_decide_moderation_appeal_v1', {
    p_appeal_id: appealId,
    p_decision: decision,
  }) as { data: { ok: boolean; error?: string } | null; error: { message: string } | null };

  if (error || !data?.ok) {
    throw new Error('İtiraz kararı kaydedilemedi.');
  }

  revalidatePath('/yonetici/itirazlar');
}

export async function setAppealReview(appealId: string, inReview: boolean) {
  const supabase = await createSupabaseServerClient();
  if (!(await hasPermission('page:itirazlar'))) return;
  const { data, error } = await (supabase).rpc('admin_set_appeal_review_v1', {
    p_appeal_id: appealId,
    p_in_review: inReview,
  }) as { data: { ok: boolean } | null; error: { message: string } | null };
  if (error || !data?.ok) throw new Error('İşlem gerçekleştirilemedi.');
  revalidatePath('/yonetici/itirazlar');
}
