import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { ProfilimIstemcisi } from './profilim-istemcisi';

export const metadata: Metadata = {
  title: 'Profilim | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function SahipProfilimSayfasi() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/profilim');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);

  const [{ data: profile }, { data: plan }, { data: prefRows }] = await Promise.all([
    (supabase as any)
      .from('user_profiles')
      .select('display_name, avatar_url, bio, phone, birth_date, gender')
      .eq('user_id', user.id)
      .maybeSingle(),
    businessIds.length > 0
      ? (supabase as any).rpc('get_my_plan_v1', { p_business_id: businessIds[0] })
      : Promise.resolve({ data: null }),
    (supabase as any)
      .from('notification_preferences')
      .select('notification_type, enabled')
      .eq('user_id', user.id)
      .then((res: { data: Array<{ notification_type: string; enabled: boolean }> | null }) => res)
      .catch(() => ({ data: [] as Array<{ notification_type: string; enabled: boolean }> })),
  ]);

  const notificationPrefs: Record<string, boolean> = {};
  for (const row of (prefRows ?? []) as Array<{ notification_type: string; enabled: boolean }>) {
    notificationPrefs[row.notification_type] = row.enabled;
  }

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <ProfilimIstemcisi
          user={{
            id: user.id,
            email: user.email ?? '',
            createdAt: user.created_at,
            lastSignInAt: user.last_sign_in_at ?? null,
            emailConfirmed: Boolean(user.email_confirmed_at),
          }}
          profile={{
            displayName: profile?.display_name ?? user.email?.split('@')[0] ?? 'Kullanıcı',
            avatarUrl: profile?.avatar_url ?? null,
            bio: profile?.bio ?? null,
            phone: profile?.phone ?? null,
            birthDate: profile?.birth_date ?? null,
            gender: profile?.gender ?? null,
          }}
          planTier={(plan as { plan_tier?: string } | null)?.plan_tier ?? null}
          businessCount={businessIds.length}
          notificationPrefs={notificationPrefs}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
