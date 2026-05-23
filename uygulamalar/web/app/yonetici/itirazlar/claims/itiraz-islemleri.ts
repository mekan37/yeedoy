'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function approveClaim(claimId: string) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  await (supabase as any)
    .from('owner_claims')
    .update({ status: 'approved', handled_at: new Date().toISOString() })
    .eq('id', claimId);
  revalidatePath('/yonetici/itirazlar');
}

export async function rejectClaim(claimId: string) {
  const supabase = await createSupabaseServerClient();
  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return;

  await (supabase as any)
    .from('owner_claims')
    .update({ status: 'rejected', handled_at: new Date().toISOString() })
    .eq('id', claimId);
  revalidatePath('/yonetici/itirazlar');
}
