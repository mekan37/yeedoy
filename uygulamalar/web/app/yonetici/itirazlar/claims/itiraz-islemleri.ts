'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { sendClaimDecisionEmail } from '@/src/lib/email/send-claim-decision-email';

async function loadClaimForNotification(
  supabase: any,
  claimId: string,
): Promise<{ userId: string; businessName: string } | null> {
  const { data } = await supabase
    .from('owner_claims')
    .select('user_id, businesses(name)')
    .eq('id', claimId)
    .maybeSingle();

  if (!data?.user_id) return null;
  const businessName = (data.businesses as { name?: string } | null)?.name ?? 'İşletmeniz';
  return { userId: data.user_id, businessName };
}

export async function approveClaim(claimId: string) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  const claimInfo = await loadClaimForNotification(supabase, claimId);

  const { error } = await (supabase as any).rpc('admin_decide_owner_claim_v1', {
    p_claim_id: claimId,
    p_decision: 'approved',
    p_note: null,
  });
  if (error) {
    throw new Error('Sahiplenme talebi onaylanamadı.');
  }
  revalidatePath('/yonetici/itirazlar');

  if (claimInfo) {
    await sendClaimDecisionEmail({
      userId: claimInfo.userId,
      businessName: claimInfo.businessName,
      decision: 'approved',
    });
  }
}

export async function rejectClaim(claimId: string, note?: string | null) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  const claimInfo = await loadClaimForNotification(supabase, claimId);

  const { error } = await (supabase as any).rpc('admin_decide_owner_claim_v1', {
    p_claim_id: claimId,
    p_decision: 'rejected',
    p_note: note ?? null,
  });
  if (error) {
    throw new Error('Sahiplenme talebi reddedilemedi.');
  }
  revalidatePath('/yonetici/itirazlar');

  if (claimInfo) {
    await sendClaimDecisionEmail({
      userId: claimInfo.userId,
      businessName: claimInfo.businessName,
      decision: 'rejected',
      note,
    });
  }
}
