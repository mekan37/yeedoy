import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';

export type OwnerDashboardSummary = {
  businessCount: number;
  menuCount: number;
  reviewCount: number;
  totalViews: number;
};

export type OwnerAnalytics = {
  views7d: number;
  views30d: number;
  reviewCount: number;
  avgRating: number | null;
};

/**
 * Returns aggregate dashboard metrics for the given owner.
 * Tries the get_owner_dashboard_summary_v1 RPC first, then falls back to direct counts.
 */
export async function getOwnerDashboardSummary(userId: string): Promise<OwnerDashboardSummary> {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  try {
    const { data, error } = await supabaseAny.rpc(
      'get_owner_dashboard_summary_v1',
      { p_user_id: userId },
    );

    if (!error && data) {
      const row = data as {
        business_count?: number;
        menu_count?: number;
        review_count?: number;
        total_views?: number;
      };
      return {
        businessCount: row.business_count ?? 0,
        menuCount: row.menu_count ?? 0,
        reviewCount: row.review_count ?? 0,
        totalViews: row.total_views ?? 0,
      };
    }

    if (error) {
      logger.warn('getOwnerDashboardSummary: RPC unavailable, falling back', { userId, error });
    }
  } catch (err) {
    logger.warn('getOwnerDashboardSummary: RPC threw, falling back', { userId, err });
  }

  // Fallback: direct table counts.
  const { data: businesses } = await supabase
    .from('businesses')
    .select('id', { count: 'exact', head: true })
    .eq('owner_id', userId);

  const businessIds: string[] = [];
  const { data: bizRows } = await supabaseAny
    .from('businesses')
    .select('id')
    .eq('owner_id', userId);
  if (bizRows) {
    for (const b of (bizRows as Array<{ id: string }>)) businessIds.push(b.id);
  }

  let menuCount = 0;
  let reviewCount = 0;
  let totalViews = 0;

  if (businessIds.length > 0) {
    const { count: mc } = await supabase
      .from('menus')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds);
    menuCount = mc ?? 0;

    const { count: rc } = await supabaseAny
      .from('reviews')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds);
    reviewCount = rc ?? 0;

    const { count: vc } = await supabaseAny
      .from('analytics_events')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds)
      .eq('event_name', 'menu_view');
    totalViews = vc ?? 0;
  }

  const { count: bc } = await supabase
    .from('businesses')
    .select('id', { count: 'exact', head: true })
    .eq('owner_id', userId);

  void businesses; // unused variable from first head query

  return {
    businessCount: bc ?? 0,
    menuCount,
    reviewCount,
    totalViews,
  };
}

/**
 * Returns analytics for a specific business, ownership-checked.
 * Tries the get_owner_analytics_v1 RPC first, then falls back to direct queries.
 */
export async function getOwnerAnalytics(
  businessId: string,
  userId: string,
): Promise<OwnerAnalytics> {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  // Ownership check.
  const { data: business, error: bizError } = await supabase
    .from('businesses')
    .select('id')
    .eq('id', businessId)
    .eq('owner_id', userId)
    .maybeSingle();

  if (bizError || !business) {
    logger.warn('getOwnerAnalytics: ownership check failed or business not found', {
      businessId,
      userId,
      error: bizError,
    });
    return { views7d: 0, views30d: 0, reviewCount: 0, avgRating: null };
  }

  try {
    const { data, error } = await supabaseAny.rpc('get_owner_analytics_v1', {
      p_business_id: businessId,
      p_user_id: userId,
    });

    if (!error && data) {
      const row = data as {
        views_7d?: number;
        views_30d?: number;
        review_count?: number;
        avg_rating?: number | null;
      };
      return {
        views7d: row.views_7d ?? 0,
        views30d: row.views_30d ?? 0,
        reviewCount: row.review_count ?? 0,
        avgRating: row.avg_rating ?? null,
      };
    }

    if (error) {
      logger.warn('getOwnerAnalytics: RPC unavailable, falling back', { businessId, error });
    }
  } catch (err) {
    logger.warn('getOwnerAnalytics: RPC threw, falling back', { businessId, err });
  }

  // Fallback: direct queries.
  const now = new Date();
  const ago7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const ago30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const [v7, v30, reviews] = await Promise.all([
    supabaseAny
      .from('analytics_events')
      .select('id', { count: 'exact', head: true })
      .eq('business_id', businessId)
      .eq('event_name', 'menu_view')
      .gte('created_at', ago7d),
    supabaseAny
      .from('analytics_events')
      .select('id', { count: 'exact', head: true })
      .eq('business_id', businessId)
      .eq('event_name', 'menu_view')
      .gte('created_at', ago30d),
    supabaseAny
      .from('reviews')
      .select('rating', { count: 'exact' })
      .eq('business_id', businessId),
  ]);

  const reviewRows = (reviews.data ?? []) as Array<{ rating: number }>;
  const reviewCount = reviews.count ?? reviewRows.length;
  const avgRating =
    reviewRows.length > 0
      ? reviewRows.reduce((sum, r) => sum + (r.rating ?? 0), 0) / reviewRows.length
      : null;

  return {
    views7d: (v7.count ?? 0) as number,
    views30d: (v30.count ?? 0) as number,
    reviewCount,
    avgRating,
  };
}
