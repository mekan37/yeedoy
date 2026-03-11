import { createSupabaseServerClient } from '@/src/lib/supabase/server';

export async function canManageBusiness(businessId: string) {
  const supabase = await createSupabaseServerClient();
  const result = await (supabase as unknown as {
    rpc: (
      fn: 'can_manage_business_v1',
      args: { p_business_id: string },
    ) => Promise<{ data: unknown; error: unknown }>;
  }).rpc('can_manage_business_v1', {
    p_business_id: businessId,
  });

  return (
    result.data === true ||
    (typeof result.data === 'object' &&
      result.data !== null &&
      'can_manage' in result.data &&
      (result.data as { can_manage?: boolean }).can_manage === true)
  );
}

export async function getQrAccessState(businessId: string) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { user: null, canManage: false };
  }

  const canManage = await canManageBusiness(businessId);

  return { user, canManage };
}
