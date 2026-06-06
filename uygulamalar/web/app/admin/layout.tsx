import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { AdminShellClient } from '@/src/ui/shell/admin-shell-client';
import { TwoFactorBanner } from '@/src/ui/bilesenler/two-factor-banner';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default async function AdminLayout({ children }: { children: ReactNode }) {
  // MFA durumunu server-side oku — hata varsa guvenli fallback (banner gizle)
  let hasTwoFactor = true;
  try {
    const supabase = await createSupabaseServerClient();
    const { data: factors } = await supabase.auth.mfa.listFactors();
    const verifiedTotp = factors?.totp?.some((f) => f.status === 'verified') ?? false;
    hasTwoFactor = verifiedTotp;
  } catch {
    // MFA API hatasi — paneli kirma, banner gizle
    hasTwoFactor = true;
  }

  return (
    <AdminShellClient
      bannerSlot={<TwoFactorBanner hasTwoFactor={hasTwoFactor} />}
    >
      {children}
    </AdminShellClient>
  );
}
