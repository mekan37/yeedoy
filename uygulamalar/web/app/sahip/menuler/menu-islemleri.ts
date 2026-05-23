'use server';

import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

export async function createOwnerMenu(formData: FormData) {
  const businessId = String(formData.get('businessId') ?? '');
  const title = String(formData.get('title') ?? '').trim();

  if (!businessId || !title) {
    redirect('/sahip/menuler?hata=missing_fields');
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent('/sahip/menuler')}`);
  }

  const isOwner = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!isOwner) {
    redirect('/sahip/menuler?hata=forbidden');
  }

  const { data, error } = await (supabase as any)
    .from('menus')
    .insert({
      business_id: businessId,
      title,
      status: 'draft',
      created_by: user.id,
      source: 'owner',
      version: 1,
      confidence_score: 1,
    })
    .select('id')
    .single() as { data: { id: string } | null; error: { message: string } | null };

  if (error || !data) {
    redirect('/sahip/menuler?hata=create_failed');
  }

  redirect(`/sahip/menuler/${data.id}/duzenle`);
}

export async function createExternalMenu(formData: FormData) {
  const businessId   = String(formData.get('businessId') ?? '');
  const title        = String(formData.get('title') ?? '').trim();
  const externalUrl  = String(formData.get('externalUrl') ?? '').trim();
  const kind         = String(formData.get('kind') ?? 'external');

  if (!businessId || !title || !externalUrl) {
    redirect('/sahip/menuler?hata=missing_fields');
  }

  // Basit URL doğrulama
  try { new URL(externalUrl); } catch {
    redirect('/sahip/menuler?hata=invalid_url');
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/giris?redirect=${encodeURIComponent('/sahip/menuler')}`);
  }

  const isOwner = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!isOwner) {
    redirect('/sahip/menuler?hata=forbidden');
  }

  const { error } = await (supabase as any)
    .from('menus')
    .insert({
      business_id: businessId,
      title,
      kind,
      external_url: externalUrl,
      status: 'published',
      created_by: user.id,
      source: 'owner',
      version: 1,
      confidence_score: 1,
    });

  if (error) {
    redirect('/sahip/menuler?hata=create_failed');
  }

  redirect('/sahip/menuler?basari=external_menu_created');
}

export async function updateExternalMenuUrl(formData: FormData) {
  const menuId      = String(formData.get('menuId') ?? '');
  const externalUrl = String(formData.get('externalUrl') ?? '').trim();

  if (!menuId || !externalUrl) {
    redirect('/sahip/menuler?hata=missing_fields');
  }

  try { new URL(externalUrl); } catch {
    redirect('/sahip/menuler?hata=invalid_url');
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris');

  // Ownership check — menü sahibi mi?
  const { data: menu } = await (supabase as any)
    .from('menus')
    .select('business_id')
    .eq('id', menuId)
    .single() as { data: { business_id: string } | null };

  if (!menu) redirect('/sahip/menuler?hata=not_found');

  const isOwner = await hasOwnerBusiness(supabase as any, user.id, menu.business_id);
  if (!isOwner) redirect('/sahip/menuler?hata=forbidden');

  await (supabase as any)
    .from('menus')
    .update({ external_url: externalUrl })
    .eq('id', menuId);

  redirect('/sahip/menuler?basari=url_updated');
}
