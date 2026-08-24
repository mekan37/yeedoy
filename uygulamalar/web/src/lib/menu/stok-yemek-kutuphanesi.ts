import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';
import type { StockDishImage } from './varsayilan-yemek-gorseli';

// Sayfa/sekme yüklendiğinde bir kez çekilir, aynı tarayıcı oturumunda tekrar
// kullanılır — kütüphane küçük (bugün 117 satır) ve yavaş büyüyor, ürün
// başına ayrı RPC çağrısına gerek yok.
let cache: Promise<StockDishImage[]> | null = null;

export function getStokYemekKutuphanesi(): Promise<StockDishImage[]> {
  if (!cache) {
    cache = fetchStokYemekKutuphanesi();
  }
  return cache;
}

async function fetchStokYemekKutuphanesi(): Promise<StockDishImage[]> {
  try {
    const supabase = createSupabaseBrowserClient();
    const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
    const { data, error } = await sb.rpc('get_stock_dish_images_v1');
    if (error || !Array.isArray(data)) return [];
    return (data as any[]).map((r) => ({
      id: String(r.id),
      image_url: String(r.image_url),
      keywords: Array.isArray(r.keywords) ? r.keywords.map(String) : [],
    }));
  } catch {
    return [];
  }
}
