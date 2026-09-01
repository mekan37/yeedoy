'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };

type SbRpc = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

export interface IsletmeDetay {
  id: string;
  name: string;
  category: string;
  description: string | null;
  phone: string | null;
  email: string | null;
  website_url: string | null;
  instagram_url: string | null;
  facebook_url: string | null;
  twitter_url: string | null;
  address: string | null;
  city: string | null;
  district: string | null;
  lat: number | null;
  lng: number | null;
  logo_url: string | null;
  cover_url: string | null;
}

export interface CalismaSaatiSatiri {
  day_of_week: number;
  open_time: string | null;
  close_time: string | null;
  is_closed: boolean;
}

export async function isletmeDetayGetir(businessId: string): Promise<IsletmeDetay | null> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return null;

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { data, error } = await sb.rpc('admin_get_business_detail_v1', { p_business_id: businessId });
  if (error || !data) {
    logger.warn('isletmeDetayGetir: RPC hatası', { error, businessId });
    return null;
  }
  return data as IsletmeDetay;
}

export async function calismaSaatleriGetir(businessId: string): Promise<CalismaSaatiSatiri[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { data, error } = await sb.rpc('get_business_hours_v1', { p_business_id: businessId });
  if (error) {
    logger.warn('calismaSaatleriGetir: RPC hatası', { error, businessId });
    return [];
  }
  const weekly = (data as { weekly?: CalismaSaatiSatiri[] } | null)?.weekly;
  return Array.isArray(weekly) ? weekly : [];
}

export interface IsletmeGuncelleGirdi {
  id: string;
  name: string;
  category: string;
  address: string;
  city: string;
  district: string;
  lat: number | null;
  lng: number | null;
  logoUrl: string;
  coverUrl: string;
  description: string;
  phone: string;
  email: string;
  websiteUrl: string;
  instagramUrl: string;
  facebookUrl: string;
  twitterUrl: string;
}

export async function isletmeGuncelle(input: IsletmeGuncelleGirdi): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!input.name.trim()) return { ok: false, error: 'İşletme adı zorunlu.' };
  if (!input.category.trim()) return { ok: false, error: 'Kategori zorunlu.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { error } = await sb.rpc('admin_update_business_v1', {
    p_business_id: input.id,
    p_name: input.name.trim(),
    p_category: input.category.trim(),
    p_address: input.address.trim() || null,
    p_city: input.city.trim() || null,
    p_district: input.district.trim() || null,
    p_lat: input.lat,
    p_lng: input.lng,
    p_logo_url: input.logoUrl.trim() || null,
    p_cover_url: input.coverUrl.trim() || null,
    p_description: input.description.trim() || null,
    p_phone: input.phone.trim() || null,
    p_email: input.email.trim() || null,
    p_website_url: input.websiteUrl.trim() || null,
    p_instagram_url: input.instagramUrl.trim() || null,
    p_facebook_url: input.facebookUrl.trim() || null,
    p_twitter_url: input.twitterUrl.trim() || null,
  });

  if (error) {
    logger.warn('isletmeGuncelle: RPC hatası', { error, businessId: input.id });
    return { ok: false, error: 'İşletme güncellenemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/isletmeler');
  return { ok: true };
}

export async function isletmeSaatleriGuncelle(businessId: string, hours: CalismaSaatiSatiri[]): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { error } = await sb.rpc('admin_upsert_business_hours_v1', {
    p_business_id: businessId,
    p_hours: hours,
  });

  if (error) {
    logger.warn('isletmeSaatleriGuncelle: RPC hatası', { error, businessId });
    return { ok: false, error: 'Çalışma saatleri kaydedilemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/isletmeler');
  return { ok: true };
}
