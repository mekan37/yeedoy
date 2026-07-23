'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { logger } from '@/src/lib/kayitci';
import { computeOnboardingComplete, type OnboardingFlags } from './sahip-baslangic-adimlari';

/**
 * business_team_memberships üzerinde RLS sadece "user_id = auth.uid()" satırlarını
 * görünür kılıyor (bkz. business_team_memberships_self_read policy) — davet edilen
 * kişilerin satırları sahip için doğrudan sorguyla hiç görünmez. Ekip sayfası
 * (app/sahip/ekip/page.tsx) bu yüzden zaten list_team_members_v1 SECURITY DEFINER
 * RPC'sini kullanıyor; aynı desen burada da izleniyor.
 */
async function hasAnyTeamMember(supabase: any, businessIds: string[]): Promise<boolean> {
  const results = await Promise.all(
    businessIds.map(async (businessId) => {
      const { data, error } = await supabase.rpc('list_team_members_v1', { p_business_id: businessId });
      if (error) {
        logger.warn('getOnboardingStatus: list_team_members_v1 başarısız', { businessId, error });
        return false;
      }
      return ((data ?? []) as Array<{ source: string }>).some((row) => row.source === 'team_membership');
    }),
  );
  return results.some(Boolean);
}

export async function getOnboardingStatus(): Promise<OnboardingFlags & { complete: boolean }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return { hasBusiness: false, hasPublishedMenu: false, hasQrCode: false, hasTeamMember: false, complete: false };
  }

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const hasBusiness = businessIds.length > 0;

  if (!hasBusiness) {
    return { hasBusiness: false, hasPublishedMenu: false, hasQrCode: false, hasTeamMember: false, complete: false };
  }

  const [menuResult, qrResult, hasTeamMember] = await Promise.all([
    (supabase as any)
      .from('menus')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds)
      .eq('status', 'published'),
    (supabase as any)
      .from('business_qr_codes')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds),
    hasAnyTeamMember(supabase, businessIds),
  ]);

  if (menuResult.error) {
    logger.warn('getOnboardingStatus: menus sayımı başarısız', { businessIds, error: menuResult.error });
  }
  if (qrResult.error) {
    logger.warn('getOnboardingStatus: business_qr_codes sayımı başarısız', { businessIds, error: qrResult.error });
  }

  const flags: OnboardingFlags = {
    hasBusiness,
    hasPublishedMenu: (menuResult.count ?? 0) > 0,
    hasQrCode: (qrResult.count ?? 0) > 0,
    hasTeamMember,
  };

  return { ...flags, complete: computeOnboardingComplete(flags) };
}
