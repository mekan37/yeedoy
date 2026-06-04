'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { logger } from '@/src/lib/kayitci';

export type LoyaltyActionResult = { ok: true } | { ok: false; error: string };

const REWARD_TYPE_WHITELIST = ['discount_pct', 'free_item'] as const;
type RewardType = (typeof REWARD_TYPE_WHITELIST)[number];

function clampInt(value: unknown, min: number, max: number): number | null {
  const n = parseInt(String(value), 10);
  if (isNaN(n)) return null;
  return Math.min(max, Math.max(min, n));
}

export async function upsertLoyaltyAction(
  _prevState: LoyaltyActionResult | null,
  formData: FormData,
): Promise<LoyaltyActionResult> {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as {
    auth: { getUser: () => Promise<{ data: { user: { id: string } | null } }> };
    rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ error: unknown }>;
  };

  const {
    data: { user },
  } = await supabaseAny.auth.getUser();

  if (!user) {
    return { ok: false, error: 'unauthorized' };
  }

  const businessId = formData.get('business_id');
  if (typeof businessId !== 'string' || !businessId) {
    return { ok: false, error: 'invalid_payload' };
  }

  // Ownership guard — fail-closed
  const owned = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!owned) {
    return { ok: false, error: 'forbidden' };
  }

  // Parse & validate fields
  const isActiveRaw = formData.get('is_active');
  const isActive = isActiveRaw === 'true' || isActiveRaw === '1';

  const checkinPoints = clampInt(formData.get('checkin_points'), 1, 100);
  const reviewPoints = clampInt(formData.get('review_points'), 1, 200);
  const photoPoints = clampInt(formData.get('photo_points'), 1, 100);
  const rewardThresholdPts = clampInt(formData.get('reward_threshold_pts'), 50, 5000);
  const rewardValue = clampInt(formData.get('reward_value'), 0, 100);

  if (
    checkinPoints === null ||
    reviewPoints === null ||
    photoPoints === null ||
    rewardThresholdPts === null ||
    rewardValue === null
  ) {
    return { ok: false, error: 'invalid_payload' };
  }

  const rewardTypeRaw = formData.get('reward_type');
  if (
    typeof rewardTypeRaw !== 'string' ||
    !(REWARD_TYPE_WHITELIST as readonly string[]).includes(rewardTypeRaw)
  ) {
    return { ok: false, error: 'invalid_payload' };
  }
  const rewardType = rewardTypeRaw as RewardType;

  try {
    const { error } = await supabaseAny.rpc('upsert_loyalty_program_v1', {
      p_business_id: businessId,
      p_is_active: isActive,
      p_checkin_points: checkinPoints,
      p_review_points: reviewPoints,
      p_photo_points: photoPoints,
      p_reward_threshold_pts: rewardThresholdPts,
      p_reward_type: rewardType,
      p_reward_value: rewardValue,
    });

    if (error) {
      logger.warn('upsertLoyaltyAction rpc failed', { businessId });
      return { ok: false, error: 'internal_error' };
    }
  } catch {
    logger.error('upsertLoyaltyAction unexpected error', { businessId });
    return { ok: false, error: 'internal_error' };
  }

  revalidatePath('/owner/marketing/loyalty');
  return { ok: true };
}
