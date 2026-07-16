'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { rateLimit } from '@/src/lib/oran-siniri';

type MenuActionResult = { error: string } | null;

// Menü oluşturma modalı için — sayfa yenilemeden sonucu (menuId veya hata)
// döndürür, çağıran taraf editöre yönlendirir.
export async function createMenuAction(
  businessId: string,
  title: string,
): Promise<{ menuId: string } | { error: string }> {
  const trimmedTitle = title.trim();
  if (!businessId || !trimmedTitle) return { error: 'İşletme ve menü adı zorunlu.' };

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı.' };

  const isOwner = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!isOwner) return { error: 'Bu işletme için menü oluşturma yetkiniz yok.' };

  const { data, error } = await (supabase as any)
    .from('menus')
    .insert({
      business_id: businessId,
      title: trimmedTitle,
      status: 'draft',
      created_by: user.id,
      source: 'owner',
      version: 1,
      confidence_score: 1,
    })
    .select('id')
    .single() as { data: { id: string } | null; error: { message: string } | null };

  if (error || !data) return { error: 'Menü oluşturulamadı. Lütfen tekrar deneyin.' };

  revalidatePath('/sahip/menuler');
  return { menuId: data.id };
}

// ─── Menü aktifleştirme (yayına alma) ────────────────────────────────────────
//
// Bir işletmenin aynı anda yalnızca tek bir "published" menüsü olmasını
// atomik olarak garanti eder: hedef menü yayına alınırken aynı işletmenin
// önceden yayınlanmış diğer menüleri tek bir transaction içinde otomatik
// taslağa çekilir (bkz. supabase/migrations/20260709000001_set_active_menu_v1.sql).
//
// Kaynak: owner tarafının /api/owner/menus/[menuId]/activate route.ts +
// _components/activate-menu-button.tsx mantığı — bu action olarak taşındı.
// Menü editöründeki tekil "Yayınla" geçişi de (menuler/[menuId]/duzenle/
// menu-islemleri.ts → publishMenu) aynı RPC'yi çağırır; böylece hem liste
// hem editör üzerinden yayına alma her zaman atomik kalır.
const activateMenuSchema = z.object({
  menuId: z.string().uuid(),
  businessId: z.string().uuid(),
});

export async function activateMenu(menuId: string, businessId: string): Promise<MenuActionResult> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const parsed = activateMenuSchema.safeParse({ menuId, businessId });
  if (!parsed.success) return { error: 'Geçersiz istek parametreleri.' };

  const rl = rateLimit(`sahip-menu-activate:${user.id}`, 20, 60_000);
  if (!rl.ok) return { error: 'Çok fazla istek. Lütfen birazdan tekrar deneyin.' };

  const { error } = await (supabase as any).rpc('set_active_menu_v1', {
    p_menu_id: parsed.data.menuId,
    p_business_id: parsed.data.businessId,
  });

  if (error) {
    if (error.code === 'P0002') return { error: 'Bu işletme size ait değil.' };
    if (error.code === 'P0001') return { error: 'Menü bulunamadı.' };
    return { error: 'Menü aktifleştirilemedi. Lütfen tekrar deneyin.' };
  }

  revalidatePath('/sahip/menuler');
  revalidatePath(`/sahip/menuler/${menuId}`);
  revalidatePath(`/sahip/menuler/${menuId}/duzenle`);

  // Genel menü sayfaları en fazla 2 dakika cache'lenir (bkz. src/lib/veri/
  // menu-okuma.ts getMenuForBusinessCached); ziyaretçilerin değişikliği daha
  // hızlı görmesi için burada da tetikliyoruz.
  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('slug, public_slug')
    .eq('id', parsed.data.businessId)
    .maybeSingle() as { data: { slug: string | null; public_slug: string | null } | null };

  if (biz?.slug) revalidatePath(`/m/${biz.slug}`);
  if (biz?.public_slug && biz.public_slug !== biz.slug) revalidatePath(`/m/${biz.public_slug}`);

  return null;
}
