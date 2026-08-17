import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { logger } from '@/src/lib/kayitci';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { SettingsClient, type BusinessData } from './ayarlar-istemcisi';
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

const SUPPLEMENTARY_ITEMS = [
  {
    href: '/sahip/ayarlar/saatler',
    label: 'Çalışma Saatleri',
    description: 'Birden fazla işletmeniz varsa haftalık saatleri buradan toplu düzenleyin',
    disabled: false,
  },
  {
    href: '/sahip/ayarlar/alan-adi',
    label: 'Özel Domain',
    description: 'İşletmenize özel alan adı bağlayın',
    disabled: false,
  },
];

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
        eyebrow="Sahip"
        title="Ayarlar"
        description="İşletme hesabınızı ve tercihlerinizi yönetin."
      />
      <PanelIcerikYuzeyi className="pt-2 sm:pt-4">
        <SettingsClient
          user={{
            id: user.id,
            email: user.email ?? '',
            displayName,
          }}
          business={businessResult.data}
          hours={hoursResult.data?.weekly ?? []}
        />

        <div className="mt-8 border-t border-border pt-6">
          <h2 className="mb-3 text-[15px] font-black text-textStrong">Diğer Ayarlar</h2>
          <div className="flex max-w-lg flex-col gap-3">
            {SUPPLEMENTARY_ITEMS.map((item) =>
              item.disabled ? (
                <div
                  key={item.href}
                  className="flex cursor-not-allowed items-center justify-between rounded-2xl border border-border bg-card px-6 py-5 opacity-60"
                >
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="font-bold text-textStrong">{item.label}</p>
                      <span className="rounded-full bg-muted/15 px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wider text-muted">
                        Yakında
                      </span>
                    </div>
                    <p className="mt-0.5 text-sm text-muted">{item.description}</p>
                  </div>
                </div>
              ) : (
                <Link
                  key={item.href}
                  href={item.href}
                  className="flex cursor-pointer items-center justify-between rounded-2xl border border-border bg-card px-6 py-5 transition-colors hover:border-primary/30"
                >
                  <div>
                    <p className="font-bold text-textStrong">{item.label}</p>
                    <p className="mt-0.5 text-sm text-muted">{item.description}</p>
                  </div>
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="shrink-0 text-muted"
                  >
                    <path d="M9 18l6-6-6-6" />
                  </svg>
                </Link>
              ),
            )}
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
