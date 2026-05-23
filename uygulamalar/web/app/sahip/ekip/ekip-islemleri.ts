'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

const ROLE_VALUES = new Set(['manager', 'editor', 'staff', 'viewer']);

export async function addTeamMember(formData: FormData): Promise<void> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/ekip');

  const businessId = String(formData.get('businessId') ?? '').trim();
  const email = String(formData.get('email') ?? '').trim().toLowerCase();
  const role = String(formData.get('role') ?? '').trim().toLowerCase();

  if (!businessId || !email || !ROLE_VALUES.has(role)) {
    redirect('/sahip/ekip?durum=gecersiz');
  }

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) {
    redirect('/sahip/ekip?durum=yetkisiz');
  }

  const { data, error } = await (supabase as any).rpc('upsert_team_member_v1', {
    p_business_id: businessId,
    p_email: email,
    p_role: role,
    p_scope: 'this_business',
  });

  if (error || data?.ok === false) {
    const code = data?.code ?? error?.code ?? 'hata';
    redirect(`/sahip/ekip?durum=${encodeURIComponent(code)}`);
  }

  revalidatePath('/sahip/ekip');
  redirect('/sahip/ekip?durum=eklendi');
}
