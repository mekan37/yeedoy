'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export async function approveClaim(claimId: string) {
  const supabase = await createSupabaseServerClient();
  await (supabase as any)
    .from('business_ownership_claims')
    .update({ status: 'approved' })
    .eq('id', claimId);
  revalidatePath('/admin/claims');
}

export async function rejectClaim(claimId: string) {
  const supabase = await createSupabaseServerClient();
  await (supabase as any)
    .from('business_ownership_claims')
    .update({ status: 'rejected' })
    .eq('id', claimId);
  revalidatePath('/admin/claims');
}
