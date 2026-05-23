import { logger } from '@/src/lib/kayitci';

type SupabaseLike = {
  from: (table: string) => any;
};

export async function getOwnerBusinessIds(supabase: SupabaseLike, userId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', userId)
    .eq('status', 'approved');

  if (error) {
    logger.warn('getOwnerBusinessIds failed', { userId, error });
    return [];
  }

  const rows = (data ?? []) as Array<{ business_id: string | null }>;
  const ids = rows
    .map((row: { business_id: string | null }) => row.business_id)
    .filter((id): id is string => Boolean(id));

  return Array.from(new Set(ids));
}

export async function hasOwnerBusiness(
  supabase: SupabaseLike,
  userId: string,
  businessId: string,
): Promise<boolean> {
  const { data, error } = await supabase
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', userId)
    .eq('business_id', businessId)
    .eq('status', 'approved')
    .maybeSingle();

  if (error) {
    logger.warn('hasOwnerBusiness failed', { userId, businessId, error });
    return false;
  }

  return Boolean(data);
}

export async function getOwnerBusinesses<T>(
  supabase: SupabaseLike,
  userId: string,
  select: string,
): Promise<T[]> {
  const ids = await getOwnerBusinessIds(supabase, userId);
  if (ids.length === 0) return [];

  const { data, error } = await supabase
    .from('businesses')
    .select(select)
    .in('id', ids);

  if (error) {
    logger.warn('getOwnerBusinesses failed', { userId, error });
    return [];
  }

  return (data ?? []) as T[];
}
