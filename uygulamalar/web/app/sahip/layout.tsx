import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { cookies } from 'next/headers';
import { SahipKabukIstemcisi, type SahipKabukIsletmeKimligi } from '@/src/ui/kabuk/sahip-kabuk-istemcisi';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds, getOwnerBusinessesByIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { AKTIF_ISLETME_COOKIE_NAME } from '@/src/ui/kabuk/aktif-isletme-cerezi';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default async function OwnerLayout({ children }: { children: ReactNode }) {
  // İşletme kimliği + yanıtsız yorum rozeti — hata varsa güvenli
  // fallback (işletme kimliği yok, rozet 0).
  let isletme: SahipKabukIsletmeKimligi | null = null;
  let isletmeSayisi = 0;
  let yorumBadgeSayisi = 0;
  let isletmeListesi: { id: string; name: string; logoUrl: string | null }[] = [];

  try {
    const supabase = await createSupabaseServerClient();
    const [{ data: { user } }, cookieStore] = await Promise.all([
      supabase.auth.getUser(),
      cookies(),
    ]);

    if (user) {
      const bizIds = await getOwnerBusinessIds(supabase as any, user.id);
      isletmeSayisi = bizIds.length;

      if (bizIds.length > 0) {
        const [businesses, unrepliedRes] = await Promise.all([
          getOwnerBusinessesByIds<{
            id: string;
            name: string;
            slug: string | null;
            category: string | null;
            logo_url: string | null;
            is_verified: boolean | null;
            is_active: boolean | null;
          }>(supabase as any, bizIds, 'id, name, slug, category, logo_url, is_verified, is_active'),
          (supabase as any)
            .from('reviews')
            .select('id', { count: 'exact', head: true })
            .in('business_id', bizIds)
            .is('owner_reply', null),
        ]);

        isletmeListesi = businesses.map((b) => ({
          id: b.id,
          name: b.name,
          logoUrl: buildMenuImageUrl(b.logo_url, { width: 64, quality: 80 }),
        }));

        // Aktif işletme: çerezdeki seçim (hâlâ sahip olunan bir işletmeyse) — yoksa ilk işletme.
        const cookieId = cookieStore.get(AKTIF_ISLETME_COOKIE_NAME)?.value;
        const biz = businesses.find((b) => b.id === cookieId) ?? businesses[0];
        if (biz) {
          isletme = {
            id: biz.id,
            name: biz.name,
            slug: biz.slug ?? null,
            category: biz.category ?? null,
            logoUrl: buildMenuImageUrl(biz.logo_url, { width: 96, quality: 84 }),
            isVerified: biz.is_verified ?? false,
            isActive: biz.is_active ?? false,
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
      isletme={isletme}
      isletmeSayisi={isletmeSayisi}
      isletmeListesi={isletmeListesi}
      yorumBadgeSayisi={yorumBadgeSayisi}
    >
      {children}
    </SahipKabukIstemcisi>
  );
}
