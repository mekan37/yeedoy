'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function approveClaim(claimId: string) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  const { error } = await (supabase as any).rpc('admin_decide_owner_claim_v1', {
    p_claim_id: claimId,
    p_decision: 'approved',
    p_note: null,
  });
  if (error) {
    throw new Error('Sahiplenme talebi onaylanamadı.');
  }
  revalidatePath('/yonetici/itirazlar');
}

export async function rejectClaim(claimId: string, note?: string | null) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  const { error } = await (supabase as any).rpc('admin_decide_owner_claim_v1', {
    p_claim_id: claimId,
    p_decision: 'rejected',
    p_note: note ?? null,
  });
  if (error) {
    throw new Error('Sahiplenme talebi reddedilemedi.');
  }
  revalidatePath('/yonetici/itirazlar');
}
