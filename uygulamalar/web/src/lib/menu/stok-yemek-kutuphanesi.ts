import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';
import type { StockDishImage } from './varsayilan-yemek-gorseli';

// Sayfa/sekme yüklendiğinde bir kez çekilir, aynı tarayıcı oturumunda tekrar
// kullanılır — kütüphane küçük (bugün 117 satır) ve yavaş büyüyor, ürün
// başına ayrı RPC çağrısına gerek yok.
let cache: Promise<StockDishImage[]> | null = null;

export function getStokYemekKutuphanesi(): Promise<StockDishImage[]> {
  if (!cache) {
    // Geçici bir ağ/RPC hatasında promise'i cache'lemiyoruz — aksi halde tek
    // bir hata, sayfa yeniden yüklenene kadar (SPA içi navigasyonlarda dahil)
    // kütüphaneyi kalıcı olarak boş bırakırdı. Başarılı sonuç (boş dizi dahil)
    // normal şekilde cache'lenir.
    cache = fetchStokYemekKutuphanesi().catch(() => {
      cache = null;
      return [];
    });
  }
  return cache;
}

async function fetchStokYemekKutuphanesi(): Promise<StockDishImage[]> {
  const supabase = createSupabaseBrowserClient();
  const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
  const { data, error } = await sb.rpc('get_stock_dish_images_v1');
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return (data as any[]).map((r) => ({
    id: String(r.id),
    image_url: String(r.image_url),
    keywords: Array.isArray(r.keywords) ? r.keywords.map(String) : [],
  }));
}
