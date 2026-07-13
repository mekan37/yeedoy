import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { YapayZekaAnalizKarti } from './yapay-zeka-analiz-karti';
import type { Isletme } from './yapay-zeka-analiz-islemi';

export const metadata: Metadata = {
  title: 'Yapay Zeka Menü Analizi | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function YapayZekaAnaliziSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  // Onaylı işletme sahipliklerini al
  const { data: claims } = (await (supabase as any)
    .from('owner_claims')
    .select('business_id, businesses(id, name)')
    .eq('user_id', user.id)
    .eq('status', 'approved')) as {
    data: { business_id: string; businesses: { id: string; name: string } }[] | null;
  };

  const isletmeler = (claims ?? [])
    .map((c) => c.businesses)
    .filter(Boolean) as Isletme[];

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Sahip"
        title="Yapay Zeka Menü Analizi"
        description="Menü görseli URL'si veya metin girerek AI ile menü ögelerini çıkarın."
      />
      <div className="max-w-3xl px-6 py-4">
        <YapayZekaAnalizKarti isletmeler={isletmeler} />
      </div>
    </div>
  );
}
