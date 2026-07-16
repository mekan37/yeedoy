'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

const ROLE_VALUES = new Set(['manager', 'editor', 'staff', 'viewer']);

type ActionResult = { error: string } | null;

export async function changeTeamMemberRole(businessId: string, email: string, role: string): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const normalizedRole = role.trim().toLowerCase();
  if (!ROLE_VALUES.has(normalizedRole)) return { error: 'Geçerli bir rol seçin' };

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

  // upsert_team_member_v1, aynı e-posta + işletme için tekrar çağrıldığında
  // mevcut üyeliği (revoked_at dahil) günceller — bu yüzden rol değişikliği de
  // aynı RPC üzerinden yapılıyor (bkz. supabase/migrations/00000000000000_base_schema.sql).
  const { data, error } = await (supabase as any).rpc('upsert_team_member_v1', {
    p_business_id: businessId,
    p_email: email.trim().toLowerCase(),
    p_role: normalizedRole,
    p_scope: 'this_business',
  });

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: data?.code === 'forbidden' ? 'Bu işletme için ekip yönetimi yetkiniz yok' : 'Rol güncellenemedi' };

  revalidatePath('/sahip/ekip');
  return null;
}

export async function removeTeamMember(businessId: string, membershipId: string): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

  const { data, error } = await (supabase as any).rpc('revoke_team_member_v1', {
    p_business_id: businessId,
    p_membership_id: membershipId,
  });

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: 'Üye kaldırılamadı' };

  revalidatePath('/sahip/ekip');
  return null;
}

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
