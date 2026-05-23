import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';

export type QueueCounts = {
  reports_open: number;
  claims_pending: number;
  suggestions_pending: number;
  submissions_pending: number;
};

export type ReportRow = {
  id: string;
  created_at: string | null;
  business_id: string | null;
  reporter_id: string | null;
  reason: string | null;
  status: string | null;
  [key: string]: unknown;
};

export type BusinessSubmissionRow = {
  id: string;
  created_at: string | null;
  owner_id: string | null;
  status: string | null;
  name: string | null;
  [key: string]: unknown;
};

/**
 * Returns pending queue counts for the admin dashboard.
 * Tries the admin_get_queues_counts_v1 RPC first, then falls back to individual table counts.
 */
export async function getQueueCounts(): Promise<QueueCounts> {
  const supabase = await createSupabaseServerClient();

  try {
    const { data, error } = await (supabase as any).rpc('admin_get_queues_counts_v1');

    if (!error && data) {
      const row = data as {
        reports_open?: number;
        claims_pending?: number;
        suggestions_pending?: number;
        submissions_pending?: number;
      };
      return {
        reports_open: row.reports_open ?? 0,
        claims_pending: row.claims_pending ?? 0,
        suggestions_pending: row.suggestions_pending ?? 0,
        submissions_pending: row.submissions_pending ?? 0,
      };
    }

    if (error) {
      logger.warn('getQueueCounts: RPC unavailable, falling back', { error });
    }
  } catch (err) {
    logger.warn('getQueueCounts: RPC threw, falling back', { err });
  }

  // Fallback: individual table counts.
  const [reports, claims, suggestions, submissions] = await Promise.all([
    (supabase as any)
      .from('reports')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'open'),
    (supabase as any)
      .from('owner_claims')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'pending'),
    (supabase as any)
      .from('menu_item_price_suggestions')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'pending'),
    (supabase as any)
      .from('business_submissions')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'pending'),
  ]);

  return {
    reports_open: (reports.count ?? 0) as number,
    claims_pending: (claims.count ?? 0) as number,
    suggestions_pending: (suggestions.count ?? 0) as number,
    submissions_pending: (submissions.count ?? 0) as number,
  };
}

/**
 * Returns open report rows for the admin queue.
 */
export async function listOpenReports(limit = 50): Promise<ReportRow[]> {
  const supabase = await createSupabaseServerClient();

  const { data, error } = await (supabase as any)
    .from('reports')
    .select('*')
    .eq('status', 'open')
    .order('created_at', { ascending: true })
    .limit(limit);

  if (error) {
    logger.error('listOpenReports failed', { error });
    return [];
  }

  return (data ?? []) as ReportRow[];
}

/**
 * Returns pending business submission rows for the admin queue.
 */
export async function listPendingSubmissions(limit = 50): Promise<BusinessSubmissionRow[]> {
  const supabase = await createSupabaseServerClient();

  const { data, error } = await (supabase as any)
    .from('business_submissions')
    .select('*')
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(limit);

  if (error) {
    logger.error('listPendingSubmissions failed', { error });
    return [];
  }

  return (data ?? []) as BusinessSubmissionRow[];
}
