import { createClient } from '@supabase/supabase-js';
import { logger } from '@/src/lib/kayitci';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;

/**
 * Fetches FCM tokens for a campaign segment.
 * Uses service role key to access user_devices.
 * Returns empty array if service role key not configured.
 */
export async function getSegmentTokens(
  businessId: string,
  segment: string,
  limit = 500,
): Promise<string[]> {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();

  if (!serviceRoleKey) {
    logger.warn('get-segment-tokens: service role key not configured');
    return [];
  }

  try {
    const client = createClient(SUPABASE_URL, serviceRoleKey);

    // Cutoff: 90 days ago — skip inactive tokens
    const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();

    // Resolve target user IDs from business_follows
    // all_followers, new_30d and all unknown segments → all followers of the business
    let followsQuery = client
      .from('business_follows')
      .select('user_id')
      .eq('business_id', businessId);

    if (segment === 'new_30d') {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
      followsQuery = followsQuery.gte('created_at', thirtyDaysAgo);
    }

    const { data: follows, error: followsError } = await followsQuery.limit(limit);

    if (followsError) {
      logger.warn('get-segment-tokens: follows query failed', { code: followsError.code });
      return [];
    }

    if (!follows || follows.length === 0) {
      logger.info('get-segment-tokens: no followers found', { segment });
      return [];
    }

    const userIds = follows.map((f: { user_id: string }) => f.user_id);

    // Fetch active FCM tokens from user_devices
    const { data: devices, error: devicesError } = await client
      .from('user_devices')
      .select('fcm_token')
      .in('user_id', userIds)
      .gte('last_seen_at', cutoff)
      .not('fcm_token', 'is', null)
      .limit(limit);

    if (devicesError) {
      logger.warn('get-segment-tokens: devices query failed', { code: devicesError.code });
      return [];
    }

    const tokens = (devices ?? [])
      .map((d: { fcm_token: string | null }) => d.fcm_token)
      .filter((t): t is string => typeof t === 'string' && t.length > 0);

    // Log only count — never log raw token values
    logger.info('get-segment-tokens: tokens fetched', { count: tokens.length, segment });

    return tokens;
  } catch (err) {
    logger.warn('get-segment-tokens: unexpected error', {
      message: err instanceof Error ? err.message : 'unknown',
    });
    return [];
  }
}
