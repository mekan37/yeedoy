import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { YoreselMutfakIstemcisi, type YoreselEtiket } from './yoresel-mutfak-istemcisi';

export const metadata: Metadata = {
  title: 'Yöresel Mutfak | Yönetici Paneli',
  robots: { index: false, follow: false },
};

export default async function YoreselMutfakPage() {
  const yetkili = await hasPermission('page:yoresel-mutfak');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Yöresel Mutfak" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Yöresel Mutfak" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
  const { data } = await sb.rpc('admin_list_regional_cuisine_tags_v1');
  const etiketler: YoreselEtiket[] = Array.isArray(data) ? (data as YoreselEtiket[]) : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Yöresel Mutfak"
        description="Şehir bazlı yöresel yemek kataloğunu ve işletme eşleşmelerini yönetin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <YoreselMutfakIstemcisi initialEtiketler={etiketler} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
