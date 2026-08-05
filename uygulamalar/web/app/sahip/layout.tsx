import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { SahipKabukIstemcisi, type SahipKabukIsletmeKimligi } from '@/src/ui/kabuk/sahip-kabuk-istemcisi';
import { TwoFactorBanner } from '@/src/ui/bilesenler/two-factor-banner';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds, getOwnerBusinessesByIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default async function OwnerLayout({ children }: { children: ReactNode }) {
  // MFA durumu + işletme kimliği + yanıtsız yorum rozeti — hata varsa güvenli
  // fallback (banner gizli, işletme kimliği yok, rozet 0).
  let hasTwoFactor = true;
  let isletme: SahipKabukIsletmeKimligi | null = null;
  let isletmeSayisi = 0;
  let yorumBadgeSayisi = 0;

  try {
    const supabase = await createSupabaseServerClient();
    const [{ data: factors }, { data: { user } }] = await Promise.all([
      supabase.auth.mfa.listFactors(),
      supabase.auth.getUser(),
    ]);
    hasTwoFactor = factors?.totp?.some((f) => f.status === 'verified') ?? false;

    if (user) {
      const bizIds = await getOwnerBusinessIds(supabase as any, user.id);
      isletmeSayisi = bizIds.length;

      if (bizIds.length > 0) {
        const [businesses, unrepliedRes] = await Promise.all([
          bizIds.length === 1
            ? getOwnerBusinessesByIds<{
                id: string;
                name: string;
                category: string | null;
                logo_url: string | null;
                is_verified: boolean | null;
              }>(supabase as any, bizIds, 'id, name, category, logo_url, is_verified')
            : Promise.resolve([]),
          (supabase as any)
            .from('reviews')
            .select('id', { count: 'exact', head: true })
            .in('business_id', bizIds)
            .is('owner_reply', null),
        ]);

        const biz = businesses[0];
        if (biz) {
          isletme = {
            id: biz.id,
            name: biz.name,
            category: biz.category ?? null,
            logoUrl: buildMenuImageUrl(biz.logo_url, { width: 96, quality: 84 }),
            isVerified: biz.is_verified ?? false,
          };
        }

        yorumBadgeSayisi = Math.max(0, unrepliedRes.count ?? 0);
      }
    }
  } catch {
    // Sorgu hatası — paneli kırma, tüm eklerin güvenli varsayılanlarıyla devam et
  }

  return (
    <SahipKabukIstemcisi
      bannerSlot={<TwoFactorBanner hasTwoFactor={hasTwoFactor} />}
      isletme={isletme}
      isletmeSayisi={isletmeSayisi}
      yorumBadgeSayisi={yorumBadgeSayisi}
    >
      {children}
    </SahipKabukIstemcisi>
  );
}
