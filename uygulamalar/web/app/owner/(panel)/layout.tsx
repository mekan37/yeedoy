import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { OwnerDashboardShell } from '@/src/ui/shell/owner-dashboard-shell';
import { TwoFactorBanner } from '@/src/ui/bilesenler/two-factor-banner';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default async function OwnerLayout({ children }: { children: ReactNode }) {
  const supabase = await createSupabaseServerClient();

  const [{ data: { user } }, mfaRes] = await Promise.all([
    supabase.auth.getUser(),
    supabase.auth.mfa.listFactors().catch(() => ({ data: null })),
  ]);

  const hasTwoFactor = mfaRes.data?.totp?.some((f) => f.status === 'verified') ?? true;

  // Owner's primary business (first approved claim)
  let business = null;
  let reviewBadgeCount = 0;
  let shellUser = null;

  if (user) {
    const [claimRes, profileRes] = await Promise.all([
      (supabase as any)
        .from('owner_claims')
        .select('business_id, businesses(id, name, category, logo_url, is_verified, slug)')
        .eq('user_id', user.id)
        .eq('status', 'approved')
        .limit(1)
        .maybeSingle(),
      (supabase as any)
        .from('user_profiles')
        .select('display_name, avatar_url')
        .eq('user_id', user.id)
        .maybeSingle(),
    ]);

    const biz = claimRes.data?.businesses;
    if (biz) {
      business = {
        id: biz.id as string,
        name: biz.name as string,
        category: (biz.category ?? null) as string | null,
        logoUrl: (biz.logo_url ?? null) as string | null,
        isVerified: (biz.is_verified ?? false) as boolean,
        slug: (biz.slug ?? null) as string | null,
      };

      // Unread (unanswered) reviews count
      const { count } = await (supabase as any)
        .from('business_reviews')
        .select('id', { count: 'exact', head: true })
        .eq('business_id', biz.id)
        .eq('status', 'approved')
        .is('owner_reply', null);
      reviewBadgeCount = count ?? 0;
    }

    const profile = profileRes.data;
    shellUser = {
      displayName: (profile?.display_name ?? user.email?.split('@')[0] ?? 'Kullanıcı') as string,
      avatarUrl: (profile?.avatar_url ?? null) as string | null,
    };
  }

  return (
    <OwnerDashboardShell
      business={business}
      user={shellUser}
      reviewBadgeCount={reviewBadgeCount}
      bannerSlot={<TwoFactorBanner hasTwoFactor={hasTwoFactor} />}
    >
      {children}
    </OwnerDashboardShell>
  );
}
