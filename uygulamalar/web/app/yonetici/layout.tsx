import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { YoneticiKabukIstemcisi } from '@/src/ui/kabuk/yonetici-kabuk-istemcisi';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  robots: { index: false, follow: false },
};

export default async function AdminLayout({ children }: { children: ReactNode }) {
  let bekleyenItirazSayisi = 0;
  let bekleyenKuyrukSayisi = 0;
  let bekleyenBildirimSayisi = 0;
  try {
    const supabase = await createSupabaseServerClient();
    const sb = supabase as any;
    const [itirazRes, oneriRes, sahiplenmeRes, incelemeRes] = await Promise.all([
      sb.from('moderation_appeals').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      sb.from('business_suggestions').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      sb.from('owner_claims').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      sb.from('business_submissions').select('id', { count: 'exact', head: true }).eq('status', 'new'),
    ]);
    bekleyenItirazSayisi = itirazRes.count ?? 0;
    bekleyenKuyrukSayisi = (incelemeRes.count ?? 0) + (sahiplenmeRes.count ?? 0);
    bekleyenBildirimSayisi = bekleyenItirazSayisi + (oneriRes.count ?? 0) + bekleyenKuyrukSayisi;
  } catch {
    bekleyenItirazSayisi = 0;
    bekleyenKuyrukSayisi = 0;
    bekleyenBildirimSayisi = 0;
  }

  return (
    <YoneticiKabukIstemcisi
      bekleyenItirazSayisi={bekleyenItirazSayisi}
      bekleyenKuyrukSayisi={bekleyenKuyrukSayisi}
      bekleyenBildirimSayisi={bekleyenBildirimSayisi}
    >
      {children}
    </YoneticiKabukIstemcisi>
  );
}
