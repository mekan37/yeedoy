'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { sendEmail, escapeHtml } from '@/src/lib/eposta';
import { appConfig } from '@/src/lib/ayarlar';
import { logger } from '@/src/lib/kayitci';
import { rateLimit } from '@/src/lib/oran-siniri';
import { ROLE_LABELS } from './ekip-sabitleri';

const ROLE_VALUES = new Set(['manager', 'editor', 'staff', 'viewer']);
const emailSchema = z.string().trim().toLowerCase().email();

export async function addTeamMember(formData: FormData): Promise<void> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/ekip');

  const businessId = String(formData.get('businessId') ?? '').trim();
  const emailParsed = emailSchema.safeParse(formData.get('email'));
  const fullName = String(formData.get('fullName') ?? '').trim();
  const password = String(formData.get('password') ?? '');
  const role = String(formData.get('role') ?? '').trim().toLowerCase();

  if (!businessId || !emailParsed.success || !ROLE_VALUES.has(role)) {
    redirect('/sahip/ekip?durum=gecersiz');
  }
  const email = emailParsed.data;
  if (password && password.length < 8) {
    redirect('/sahip/ekip?durum=sifre_kisa');
  }

  const canManageBusiness = await hasOwnerBusiness(supabase, user.id, businessId);
  if (!canManageBusiness) {
    redirect('/sahip/ekip?durum=yetkisiz');
  }

  const limit = await rateLimit(`ekip-davet:${user.id}`, 20, 3_600_000);
  if (!limit.ok) {
    redirect('/sahip/ekip?durum=rate_limited');
  }

  const { data: business } = await (supabase)
    .from('businesses')
    .select('name')
    .eq('id', businessId)
    .maybeSingle() as { data: { name: string } | null };
  const businessName = business?.name ?? 'İşletmeniz';

  let mode: 'created' | 'invited' | 'linked' = 'invited';

  if (password) {
    // Plan limiti önceden hiç kontrol edilmiyordu — yeni bir auth
    // hesabı (+ user_profiles satırı) oluşturulduktan SONRA
    // upsert_team_member_v1 içindeki limit reddediyordu, geride
    // ekibe hiç bağlanamayan yetim bir giriş hesabı bırakıyordu.
    const { error: limitError } = await (supabase).rpc('_check_plan_limit_v1', {
      p_business_id: businessId,
      p_feature_key: 'team_seat_count',
    }) as { error: { code?: string; message?: string } | null };
    if (limitError) {
      redirect(limitError.code === 'P0002' ? '/sahip/ekip?durum=yetkisiz' : '/sahip/ekip?durum=plan_limit_exceeded');
    }

    const serviceClient = createSupabaseServiceClient();
    if (!serviceClient) {
      redirect('/sahip/ekip?durum=servis_yok');
    }

    const { data: created, error: createErr } = await (serviceClient).auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: fullName ? { full_name: fullName } : undefined,
    });

    if (createErr) {
      const alreadyExists = createErr.code === 'email_exists' || createErr.code === 'user_already_exists'
        || /already.*registered|already.*exists/i.test(createErr.message ?? '');
      if (!alreadyExists) redirect('/sahip/ekip?durum=hesap_hata');
      // E-posta zaten kayıtlı: mevcut hesabın şifresine dokunmuyoruz, sadece ekibe bağlıyoruz.
      mode = 'linked';
    } else {
      mode = 'created';
      if (created.user) {
        try {
          await (serviceClient)
            .from('user_profiles')
            .insert({ user_id: created.user.id, display_name: fullName || email.split('@')[0] });
        } catch (profileError) {
          // profil satırı ikincil — başarısız olsa da hesap oluşturmayı engellemez
          logger.warn('addTeamMember: user_profiles satırı oluşturulamadı', { userId: created.user.id, error: profileError });
        }
      }
    }
  }

  const { data, error } = await (supabase).rpc('upsert_team_member_v1', {
    p_business_id: businessId,
    p_email: email,
    p_role: role,
    p_scope: 'this_business',
  }) as { data: { ok: boolean; code?: string } | null; error: { code?: string } | null };

  if (error || data?.ok === false) {
    const code = data?.code ?? error?.code ?? 'hata';
    redirect(`/sahip/ekip?durum=${encodeURIComponent(code)}`);
  }

  revalidatePath('/sahip/ekip');

  const roleLabel = ROLE_LABELS[role]?.label ?? role;
  const loginUrl = `${appConfig.siteUrl()}/giris`;
  // businessName işletme sahibinin kendi girdiği serbest metin — e-posta
  // HTML'ine kaçışsız basılıyordu (davet edilen kullanıcının e-posta
  // istemcisine yönelik HTML enjeksiyonu).
  const safeBusinessName = escapeHtml(businessName);
  const safeRoleLabel = escapeHtml(roleLabel);

  if (mode === 'created') {
    void sendEmail({
      to: email,
      subject: `${businessName} — Yeedoy Sahip Paneli hesabınız hazır`,
      html: `<p>${safeBusinessName} işletmesi için Yeedoy Sahip Paneli'nde <strong>${safeRoleLabel}</strong> rolüyle bir hesap oluşturuldu.</p>
             <p>Giriş bilgilerinizi (e-posta ve şifre) işletme sahibinizden öğrenebilirsiniz.</p>
             <p><a href="${loginUrl}">${loginUrl}</a> adresinden giriş yapabilirsiniz.</p>`,
    });
  } else if (mode === 'invited') {
    void sendEmail({
      to: email,
      subject: `${businessName} sizi ekibine davet etti`,
      html: `<p>${safeBusinessName} işletmesi sizi Yeedoy Sahip Paneli'nde <strong>${safeRoleLabel}</strong> rolüyle ekibine davet etti.</p>
             <p>Bu e-posta adresiyle <a href="${loginUrl}">${loginUrl}</a> üzerinden kayıt olun veya giriş yapın; daveti otomatik olarak hesabınıza bağlanacaktır.</p>`,
    });
  } else {
    void sendEmail({
      to: email,
      subject: `${businessName} ekibine eklendiniz`,
      html: `<p>${safeBusinessName} işletmesi sizi Yeedoy Sahip Paneli'nde <strong>${safeRoleLabel}</strong> rolüyle ekibine ekledi.</p>
             <p>Mevcut hesabınızla <a href="${loginUrl}">${loginUrl}</a> üzerinden giriş yapabilirsiniz.</p>`,
    });
  }

  redirect('/sahip/ekip?durum=eklendi');
}

export async function changeTeamMemberRole(businessId: string, email: string, role: string): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const normalizedRole = role.trim().toLowerCase();
  if (!ROLE_VALUES.has(normalizedRole)) return { error: 'Geçerli bir rol seçin' };

  const canManageBusiness = await hasOwnerBusiness(supabase, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

  const { data, error } = await (supabase).rpc('upsert_team_member_v1', {
    p_business_id: businessId,
    p_email: email.trim().toLowerCase(),
    p_role: normalizedRole,
    p_scope: 'this_business',
  }) as { data: { ok: boolean; code?: string } | null; error: { message: string } | null };

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: data?.code === 'forbidden' ? 'Bu işletme için ekip yönetimi yetkiniz yok' : 'Rol güncellenemedi' };

  revalidatePath('/sahip/ekip');
  return null;
}

export async function removeTeamMember(businessId: string, membershipId: string): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const canManageBusiness = await hasOwnerBusiness(supabase, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

  const { data, error } = await (supabase).rpc('revoke_team_member_v1', {
    p_business_id: businessId,
    p_membership_id: membershipId,
  }) as { data: { ok: boolean } | null; error: { message: string } | null };

  if (error) return { error: error.message };
  if (data?.ok === false) return { error: 'Üye kaldırılamadı' };

  revalidatePath('/sahip/ekip');
  return null;
}
