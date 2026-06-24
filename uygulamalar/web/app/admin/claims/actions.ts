'use server';

import { revalidatePath } from 'next/cache';
import {
  approveClaim as approveClaimCanonical,
  rejectClaim as rejectClaimCanonical,
} from '@/app/yonetici/itirazlar/claims/itiraz-islemleri';

// /admin/claims is the secret-subdomain (ops.yeedoy.com) mirror of the
// canonical /yonetici/itirazlar/claims queue. The decision logic (admin
// check, RPC call, claimant e-mail notification) lives in one place —
// itiraz-islemleri.ts — so both surfaces stay in sync automatically.
export async function approveClaim(claimId: string) {
  await approveClaimCanonical(claimId);
  revalidatePath('/admin/claims');
}

export async function rejectClaim(claimId: string, note?: string | null) {
  await rejectClaimCanonical(claimId, note);
  revalidatePath('/admin/claims');
}
