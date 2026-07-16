import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { logger } from '@/src/lib/kayitci';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { AyarlarIstemcisi, type BusinessData } from './ayarlar-istemcisi';
import type { WeeklyHourRow } from './saatler/saatler-formu';

export const metadata: Metadata = {
  title: 'Ayarlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

type OwnerClaim = {
  business_id: string;
};

type UserProfile = {
  display_name: string | null;
};

type HoursResult = {
  weekly?: WeeklyHourRow[];
};

function throwSettingsLoadError(
  source: 'claim' | 'business' | 'profile' | 'hours',
  error: { code?: string; message?: string },
): never {
  logger.error('Owner settings data load failed', {
    source,
    code: error.code,
  });
  throw new Error(`Owner settings ${source} query failed`);
}

export default async function OwnerSettingsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();

  if (authError || !authData.user) {
    redirect('/giris?redirect=/sahip/ayarlar');
  }

  const user = authData.user;
  const { data: claimData, error: claimError } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle() as { data: OwnerClaim | null; error: { code?: string; message?: string } | null };

  if (claimError) throwSettingsLoadError('claim', claimError);
  if (!claimData?.business_id) redirect('/sahip/gosterge-panosu');

  const businessId = claimData.business_id;
  const service = createSupabaseServiceClient();
  if (!service) redirect('/sahip/gosterge-panosu');

  const [businessResult, profileResult, hoursResult] = await Promise.all([
    (service as any)
      .from('businesses')
      .select(
        'id, name, category, description, phone, email, address, city, district, ' +
        'logo_url, cover_url, is_active, slug, website_url, instagram_url, ' +
        'facebook_url, twitter_url, accepts_reservations, reservation_phone, ' +
        'reservation_min_party, reservation_max_party, reservation_note',
      )
      .eq('id', businessId)
      .single(),
    (supabase as any)
      .from('user_profiles')
      .select('display_name')
      .eq('user_id', user.id)
      .maybeSingle(),
    (supabase as any).rpc('get_business_hours_v1', {
      p_business_id: businessId,
    }),
  ]) as [
    { data: BusinessData | null; error: { code?: string; message?: string } | null },
    { data: UserProfile | null; error: { code?: string; message?: string } | null },
    { data: HoursResult | null; error: { code?: string; message?: string } | null },
  ];

  if (businessResult.error) throwSettingsLoadError('business', businessResult.error);
  if (!businessResult.data) {
    throwSettingsLoadError('business', { code: 'BUSINESS_NOT_FOUND' });
  }
  if (profileResult.error) throwSettingsLoadError('profile', profileResult.error);
  if (hoursResult.error) throwSettingsLoadError('hours', hoursResult.error);

  const displayName =
    profileResult.data?.display_name?.trim() ||
    user.email?.split('@')[0] ||
    'Kullanıcı';

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Ayarlar"
        description="İşletme hesabınızı ve tercihlerinizi yönetin."
      />
      <PanelIcerikYuzeyi className="pt-2 sm:pt-4">
        <AyarlarIstemcisi
          user={{
            id: user.id,
            email: user.email ?? '',
            displayName,
          }}
          business={businessResult.data}
          hours={hoursResult.data?.weekly ?? []}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
