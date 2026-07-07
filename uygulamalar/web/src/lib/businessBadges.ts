import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export interface BusinessBadge {
  id: string;
  title: string;
  color: string;
  tier: 'bronze' | 'silver' | 'gold' | 'special';
}

export async function fetchBusinessBadges(businessId: string): Promise<BusinessBadge[]> {
  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase.rpc('get_business_badges_v1' as any, {
      p_business_id: businessId,
    } as any);
    if (error || !data) return [];
    return (data as Array<{ badge_id: string; title: string; color: string; tier: string }>).map(
      (row) => ({
        id: row.badge_id,
        title: row.title,
        color: row.color,
        tier: (row.tier as BusinessBadge['tier']) ?? 'bronze',
      })
    );
  } catch {
    return [];
  }
}
