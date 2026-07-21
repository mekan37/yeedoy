import { logger } from '@/src/lib/kayitci';

type SupabaseLike = {
  from: (table: string) => any;
};

export interface LoyaltyProgram {
  business_id: string;
  is_active: boolean;
  checkin_points: number;
  review_points: number;
  photo_points: number;
  reward_threshold_pts: number;
  reward_type: 'discount_pct' | 'free_item';
  reward_value: number;
  birthday_bonus_pts: number;
}

/**
 * Fetches loyalty programs for the given business IDs.
 * RLS on loyalty_programs ensures only owned businesses are returned.
 * Called by: app/sahip/pazarlama/sadakat/sadakat-form.tsx (via /sunucu/sahip/sadakat)
 */
export async function getOwnerLoyaltyPrograms(
  supabase: SupabaseLike,
  businessIds: string[],
): Promise<{ programs: LoyaltyProgram[]; fetchError: boolean }> {
  if (businessIds.length === 0) {
    return { programs: [], fetchError: false };
  }

  const { data, error } = await supabase
    .from('loyalty_programs')
    .select(
      'business_id, is_active, checkin_points, review_points, photo_points, reward_threshold_pts, reward_type, reward_value, birthday_bonus_pts',
    )
    .in('business_id', businessIds);

  if (error) {
    logger.warn('getOwnerLoyaltyPrograms failed', { code: (error as { code?: string }).code });
    return { programs: [], fetchError: true };
  }

  return { programs: (data ?? []) as LoyaltyProgram[], fetchError: false };
}
