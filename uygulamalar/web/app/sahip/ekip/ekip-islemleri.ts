'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { sendEmail } from '@/src/lib/eposta';
import { appConfig } from '@/src/lib/ayarlar';
import { ROLE_LABELS } from './ekip-sabitleri';

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

export type AddTeamMemberInput = {
  businessId: string;
  email: string;
  fullName: string;
  password: string;
  role: string;
};

export type AddTeamMemberOutcome =
  | { error: string }
  | { ok: true; mode: 'created' | 'invited' | 'linked' };

/**
 * Tek giriş noktası: şifre verilmişse doğrudan giriş yapabilen bir hesap
 * oluşturur (auth.admin.createUser, service-role); şifre boşsa yalnızca
 * e-posta daveti oluşturur (kişi kendi kayıt olduğunda upsert_team_member_v1
 * ile aynı e-postayı tekrar çağırıp veya claim_pending_team_invites_v1 ile
 * girişte otomatik bağlanır — bkz. app/sunucu/kimlik/giris/route.ts).
 */
export async function addTeamMember(input: AddTeamMemberInput): Promise<AddTeamMemberOutcome> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const businessId = input.businessId.trim();
  const email = input.email.trim().toLowerCase();
  const fullName = input.fullName.trim();
  const password = input.password;
  const role = input.role.trim().toLowerCase();

  if (!businessId || !email) return { error: 'E-posta ve işletme zorunlu' };
  if (!ROLE_VALUES.has(role)) return { error: 'Geçerli bir rol seçin' };
  if (password && password.length < 8) return { error: 'Şifre en az 8 karakter olmalı' };

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

  const { data: business } = await (supabase as any)
    .from('businesses')
    .select('name')
    .eq('id', businessId)
    .maybeSingle() as { data: { name: string } | null };
  const businessName = business?.name ?? 'İşletmeniz';

  let mode: 'created' | 'invited' | 'linked' = 'invited';

  if (password) {
    const serviceClient = createSupabaseServiceClient();
    if (!serviceClient) {
      return { error: 'Sunucu yapılandırması eksik (SUPABASE_SERVICE_ROLE_KEY tanımlı değil) — şifresiz davet gönderebilirsiniz.' };
    }

    const { data: created, error: createErr } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: fullName ? { full_name: fullName } : undefined,
    });

    if (createErr) {
      const alreadyExists = /already.*registered|already.*exists/i.test(createErr.message ?? '');
      if (!alreadyExists) return { error: createErr.message };
      // E-posta zaten kayıtlı: yeni şifre atamıyoruz (mevcut hesabın şifresini
      // sessizce değiştirmek güvenlik açısından yanlış olur) — sadece ekibe
      // bağlıyoruz, kişi mevcut şifresiyle giriş yapmaya devam eder.
      mode = 'linked';
    } else {
      mode = 'created';
      if (created.user) {
        try {
          await (serviceClient as any)
            .from('user_profiles')
            .insert({ user_id: created.user.id, display_name: fullName || email.split('@')[0] });
        } catch {
          // profil satırı ikincil — başarısız olsa da hesap oluşturma işlemini engellemez
        }
      }
    }
  }

  const { data, error } = await (supabase as any).rpc('upsert_team_member_v1', {
    p_business_id: businessId,
    p_email: email,
    p_role: role,
    p_scope: 'this_business',
  });

  if (error || data?.ok === false) {
    return { error: error?.message ?? 'Ekip üyesi eklenemedi' };
  }

  revalidatePath('/sahip/ekip');

  const roleLabel = ROLE_LABELS[role]?.label ?? role;
  const loginUrl = `${appConfig.siteUrl()}/giris`;

  if (mode === 'created') {
    void sendEmail({
      to: email,
      subject: `${businessName} — Yeedoy Sahip Paneli hesabınız hazır`,
      html: `<p>${businessName} işletmesi için Yeedoy Sahip Paneli'nde <strong>${roleLabel}</strong> rolüyle bir hesap oluşturuldu.</p>
             <p>Giriş bilgilerinizi (e-posta ve şifre) işletme sahibinizden öğrenebilirsiniz.</p>
             <p><a href="${loginUrl}">${loginUrl}</a> adresinden giriş yapabilirsiniz.</p>`,
    });
  } else if (mode === 'invited') {
    void sendEmail({
      to: email,
      subject: `${businessName} sizi ekibine davet etti`,
      html: `<p>${businessName} işletmesi sizi Yeedoy Sahip Paneli'nde <strong>${roleLabel}</strong> rolüyle ekibine davet etti.</p>
             <p>Bu e-posta adresiyle <a href="${loginUrl}">${loginUrl}</a> üzerinden kayıt olun veya giriş yapın; daveti otomatik olarak hesabınıza bağlanacaktır.</p>`,
    });
  } else {
    void sendEmail({
      to: email,
      subject: `${businessName} ekibine eklendiniz`,
      html: `<p>${businessName} işletmesi sizi Yeedoy Sahip Paneli'nde <strong>${roleLabel}</strong> rolüyle ekibine ekledi.</p>
             <p>Mevcut hesabınızla <a href="${loginUrl}">${loginUrl}</a> üzerinden giriş yapabilirsiniz.</p>`,
    });
  }

  return { ok: true, mode };
}
