import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { GorselKutuphanesiIstemcisi, type StokGorsel } from './gorsel-kutuphanesi-istemcisi';

export const metadata: Metadata = {
  title: 'Görsel Kütüphanesi | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function GorselKutuphanesiPage() {
  const yetkili = await hasPermission('page:gorsel-kutuphanesi');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Görsel Kütüphanesi" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Görsel Kütüphanesi" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
  const { data } = await sb.rpc('admin_list_stock_dish_images_v1');
  const gorseller: StokGorsel[] = Array.isArray(data)
    ? (data as any[]).map((r) => ({
        id: r.id,
        image_url: r.image_url,
        keywords: Array.isArray(r.keywords) ? r.keywords : [],
        is_active: r.is_active,
        created_at: r.created_at,
      }))
    : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Görsel Kütüphanesi"
        description="Sahiplerin ürün görseli yüklemediğinde önerilen stok yemek fotoğraflarını yönetin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <GorselKutuphanesiIstemcisi initialGorseller={gorseller} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
