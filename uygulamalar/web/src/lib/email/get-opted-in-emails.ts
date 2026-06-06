import { createClient } from '@supabase/supabase-js';
import { logger } from '@/src/lib/kayitci';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;

export type OptedInRecipient = {
  email: string;
  displayName: string;
};

/**
 * Gets email addresses of users who opted in to marketing emails for a business.
 * Uses service role to access auth.users and business_follows with consent filter.
 * Returns empty array if service role key not configured.
 * Never logs email addresses — only counts.
 */
export async function getOptedInEmails(
  businessId: string,
  limit = 200,
): Promise<OptedInRecipient[]> {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();

  if (!serviceRoleKey) {
    logger.warn('get-opted-in-emails: service role key not configured');
    return [];
  }

  try {
    const client = createClient(SUPABASE_URL, serviceRoleKey);

    // Step 1: Fetch user_ids who opted in to email marketing for this business
    const { data: follows, error: followsError } = await client
      .from('business_follows')
      .select('user_id, user_profiles:user_id(display_name)')
      .eq('business_id', businessId)
      .eq('is_subscribed_email', true)
      .limit(limit);

    if (followsError) {
      logger.warn('get-opted-in-emails: follows query failed', { code: followsError.code });
      return [];
    }

    if (!follows || follows.length === 0) {
      logger.info('get-opted-in-emails: no opted-in followers', { businessId });
      return [];
    }

    const userIds = follows.map((f: { user_id: string }) => f.user_id);

    // Step 2: Fetch auth emails via auth.admin — service role required
    // listUsers paginates 1000/page; for MVP limit is 200 so one page suffices
    const { data: usersPage, error: usersError } = await client.auth.admin.listUsers({
      page: 1,
      perPage: limit,
    });

    if (usersError) {
      logger.warn('get-opted-in-emails: listUsers failed', { message: usersError.message });
      return [];
    }

    // Build email lookup: user_id → email
    const emailMap = new Map<string, string>();
    for (const u of usersPage.users) {
      if (u.email) emailMap.set(u.id, u.email);
    }

    // Build displayName lookup from joined user_profiles
    // Supabase returns the join as array — cast via unknown to handle type mismatch
    type FollowRow = { user_id: string; user_profiles: { display_name: string } | null };
    const displayNameMap = new Map<string, string>();
    for (const f of follows as unknown as FollowRow[]) {
      const name = f.user_profiles?.display_name ?? 'Değerli Müşteri';
      displayNameMap.set(f.user_id, name);
    }

    // Step 3: Merge — only include user_ids in our opted-in set
    const recipients: OptedInRecipient[] = [];
    for (const userId of userIds) {
      const email = emailMap.get(userId);
      if (!email) continue; // skip users without email
      recipients.push({
        email,
        displayName: displayNameMap.get(userId) ?? 'Değerli Müşteri',
      });
    }

    // Log only count — never log raw email addresses
    logger.info('get-opted-in-emails: recipients fetched', { count: recipients.length });

    return recipients;
  } catch (err) {
    logger.warn('get-opted-in-emails: unexpected error', {
      message: err instanceof Error ? err.message : 'unknown',
    });
    return [];
  }
}
