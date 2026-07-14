import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { headers } from 'next/headers';
import { SahipKabukIstemcisi } from '@/src/ui/kabuk/sahip-kabuk-istemcisi';
import { TwoFactorBanner } from '@/src/ui/bilesenler/two-factor-banner';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

// middleware.ts tarafından yalnızca /sahip (kök, herkese açık landing page)
// için set edilir — aşağıdaki yetkili-kullanıcıya-özel MFA sorgusunu atlamak
// için kullanılır.
const PUBLIC_LANDING_HEADER = 'x-yeedoy-public-landing';

export default async function OwnerLayout({ children }: { children: ReactNode }) {
  const isPublicLanding = (await headers()).get(PUBLIC_LANDING_HEADER) === '1';

  // MFA durumunu server-side oku — hata varsa guvenli fallback (banner gizle)
  // Herkese açık landing page'de (girişsiz ziyaretçi) bu sorgu hem gereksiz
  // hem de banner zaten sahip-kabuk-istemcisi.tsx'te render edilmiyor.
  let hasTwoFactor = true;
  if (!isPublicLanding) {
    try {
      const supabase = await createSupabaseServerClient();
      const { data: factors } = await supabase.auth.mfa.listFactors();
      const verifiedTotp = factors?.totp?.some((f) => f.status === 'verified') ?? false;
      hasTwoFactor = verifiedTotp;
    } catch {
      // MFA API hatasi — paneli kirma, banner gizle
      hasTwoFactor = true;
    }
  }

  return (
    <SahipKabukIstemcisi
      bannerSlot={<TwoFactorBanner hasTwoFactor={hasTwoFactor} />}
    >
      {children}
    </SahipKabukIstemcisi>
  );
}
