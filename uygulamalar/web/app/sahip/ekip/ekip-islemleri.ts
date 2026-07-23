'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { sendEmail } from '@/src/lib/eposta';
import { appConfig } from '@/src/lib/ayarlar';
import { ROLE_LABELS } from './ekip-sabitleri';

const ROLE_VALUES = new Set(['manager', 'editor', 'staff', 'viewer']);

export async function addTeamMember(formData: FormData): Promise<void> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/ekip');

  const businessId = String(formData.get('businessId') ?? '').trim();
  const email = String(formData.get('email') ?? '').trim().toLowerCase();
  const fullName = String(formData.get('fullName') ?? '').trim();
  const password = String(formData.get('password') ?? '');
  const role = String(formData.get('role') ?? '').trim().toLowerCase();

  if (!businessId || !email || !ROLE_VALUES.has(role)) {
    redirect('/sahip/ekip?durum=gecersiz');
  }
  if (password && password.length < 8) {
    redirect('/sahip/ekip?durum=sifre_kisa');
  }

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) {
    redirect('/sahip/ekip?durum=yetkisiz');
  }

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
      redirect('/sahip/ekip?durum=servis_yok');
    }

    const { data: created, error: createErr } = await (serviceClient as any).auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: fullName ? { full_name: fullName } : undefined,
    });

    if (createErr) {
      const alreadyExists = /already.*registered|already.*exists/i.test(createErr.message ?? '');
      if (!alreadyExists) redirect('/sahip/ekip?durum=hesap_hata');
      // E-posta zaten kayıtlı: mevcut hesabın şifresine dokunmuyoruz, sadece ekibe bağlıyoruz.
      mode = 'linked';
    } else {
      mode = 'created';
      if (created.user) {
        try {
          await (serviceClient as any)
            .from('user_profiles')
            .insert({ user_id: created.user.id, display_name: fullName || email.split('@')[0] });
        } catch {
          // profil satırı ikincil — başarısız olsa da hesap oluşturmayı engellemez
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
    const code = data?.code ?? error?.code ?? 'hata';
    redirect(`/sahip/ekip?durum=${encodeURIComponent(code)}`);
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

  redirect('/sahip/ekip?durum=eklendi');
}

export async function changeTeamMemberRole(businessId: string, email: string, role: string): Promise<{ error: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const normalizedRole = role.trim().toLowerCase();
  if (!ROLE_VALUES.has(normalizedRole)) return { error: 'Geçerli bir rol seçin' };

  const canManageBusiness = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!canManageBusiness) return { error: 'Bu işletme için ekip yönetimi yetkiniz yok' };

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

export async function removeTeamMember(businessId: string, membershipId: string): Promise<{ error: string } | null> {
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
