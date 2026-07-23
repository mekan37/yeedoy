'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { computeOnboardingComplete, type OnboardingFlags } from './baslangic-adimlari';

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

  const [{ count: menuCount }, { count: qrCount }, { count: teamCount }] = await Promise.all([
    (supabase as any)
      .from('menus')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds)
      .eq('status', 'published'),
    (supabase as any)
      .from('business_qr_codes')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds),
    (supabase as any)
      .from('business_team_memberships')
      .select('id', { count: 'exact', head: true })
      .in('business_id', businessIds)
      .is('revoked_at', null),
  ]);

  const flags: OnboardingFlags = {
    hasBusiness,
    hasPublishedMenu: (menuCount ?? 0) > 0,
    hasQrCode: (qrCount ?? 0) > 0,
    hasTeamMember: (teamCount ?? 0) > 0,
  };

  return { ...flags, complete: computeOnboardingComplete(flags) };
}
