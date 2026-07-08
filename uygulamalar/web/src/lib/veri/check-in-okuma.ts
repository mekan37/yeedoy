import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function getMyCheckInToday(businessId: string): Promise<boolean> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return false;

  const { data } = await (supabase as any).rpc('get_my_checkin_today_v1', {
    p_business_id: businessId,
  });

  return (data as { checked_in?: boolean } | null)?.checked_in ?? false;
}
