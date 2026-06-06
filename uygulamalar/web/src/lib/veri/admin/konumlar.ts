import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

// ─── Tipler ───────────────────────────────────────────────────────────────────

export type KonumKaliteFiltre = {
  city?: string;
  district?: string;
  eksikKoordinat?: boolean;
  eksikKonum?: boolean;
  eksikSlug?: boolean;
  aktif?: boolean;
  limit?: number;
  offset?: number;
};

export type KonumIsletme = {
  id: string;
  name: string;
  city: string | null;
  district: string | null;
  category: string | null;
  city_slug: string | null;
  district_slug: string | null;
  category_slug: string | null;
  lat: number | null;
  lng: number | null;
  is_active: boolean;
  is_verified: boolean;
  // Türetilmiş kalite alanları
  has_coords: boolean;
  has_city: boolean;
  has_district: boolean;
  has_slugs: boolean;
};

export type KonumOzet = {
  toplam: number;
  koordinatsiz: number;
  sehirsiz: number;
  ilcesiz: number;
  slugsuz: number;
};

export type KonumKaliteSonucu = {
  items: KonumIsletme[];
  total: number;
  fetchError: boolean;
};

// ─── Yardımcı ─────────────────────────────────────────────────────────────────

function buildSupabaseClient() {
  return createSupabaseServiceClient() ?? createSupabaseServerClient();
}

function mapRow(b: Record<string, unknown>): KonumIsletme {
  const lat = b['lat'] != null ? Number(b['lat']) : null;
  const lng = b['lng'] != null ? Number(b['lng']) : null;
  return {
    id: String(b['id'] ?? ''),
    name: b['name'] != null ? String(b['name']) : '—',
    city: b['city'] != null ? String(b['city']) : null,
    district: b['district'] != null ? String(b['district']) : null,
    category: b['category'] != null ? String(b['category']) : null,
    city_slug: b['city_slug'] != null ? String(b['city_slug']) : null,
    district_slug: b['district_slug'] != null ? String(b['district_slug']) : null,
    category_slug: b['category_slug'] != null ? String(b['category_slug']) : null,
    lat,
    lng,
    is_active: Boolean(b['is_active']),
    is_verified: Boolean(b['is_verified']),
    has_coords: lat != null && lng != null,
    has_city: b['city'] != null && String(b['city']).trim().length > 0,
    has_district: b['district'] != null && String(b['district']).trim().length > 0,
    has_slugs:
      b['city_slug'] != null &&
      b['district_slug'] != null &&
      b['category_slug'] != null,
  };
}

// ─── Veri Fonksiyonları ───────────────────────────────────────────────────────

/**
 * Konum veri kalitesi listesini döndürür.
 * businesses tablosunu doğrudan sorgular.
 * Supabase service client varsa kullanır (RLS bypass).
 * Her durumda checkAdminAccess() ile is_admin() guard uygulanır — service client
 * kullanıldığında RLS atlandığından guard zorunludur.
 */
export async function adminKonumlariGetir(
  params?: KonumKaliteFiltre,
): Promise<KonumKaliteSonucu> {
  const limit = params?.limit ?? 50;
  const offset = params?.offset ?? 0;

  try {
    // Her durumda is_admin() guard — service client path'inde RLS bypass olduğundan kritik
    const guard = await checkAdminAccess();
    if (!guard.authorized) {
      logger.warn('adminKonumlariGetir: admin guard başarısız', { status: guard.status });
      return { items: [], total: 0, fetchError: false };
    }

    const supabaseOrPromise = buildSupabaseClient();
    const supabase =
      supabaseOrPromise instanceof Promise ? await supabaseOrPromise : supabaseOrPromise;

    let query = (supabase as any)
      .from('businesses')
      .select(
        'id, name, city, district, category, city_slug, district_slug, category_slug, lat, lng, is_active, is_verified',
        { count: 'exact' },
      );

    if (params?.city) query = query.ilike('city', `%${params.city}%`);
    if (params?.district) query = query.ilike('district', `%${params.district}%`);
    if (params?.eksikKoordinat) query = query.or('lat.is.null,lng.is.null');
    if (params?.eksikKonum) query = query.or('city.is.null,district.is.null');
    if (params?.eksikSlug)
      query = query.or('city_slug.is.null,district_slug.is.null,category_slug.is.null');
    if (params?.aktif !== undefined) query = query.eq('is_active', params.aktif);

    query = query
      .order('name', { ascending: true })
      .range(offset, offset + limit - 1);

    const { data, count, error } = await query;

    if (error) {
      logger.warn('adminKonumlariGetir: sorgu hatası', { error });
      return { items: [], total: 0, fetchError: true };
    }

    return {
      items: ((data ?? []) as Record<string, unknown>[]).map(mapRow),
      total: count ?? 0,
      fetchError: false,
    };
  } catch (err) {
    logger.warn('adminKonumlariGetir: istisna', { err });
    return { items: [], total: 0, fetchError: true };
  }
}

/**
 * Konum veri kalitesi özetini döndürür.
 * 5 paralel count sorgusu: toplam, koordinatsız, şehirsiz, ilçesiz, slugsuz.
 */
export async function adminKonumOzetiniGetir(): Promise<KonumOzet> {
  const bos: KonumOzet = {
    toplam: 0,
    koordinatsiz: 0,
    sehirsiz: 0,
    ilcesiz: 0,
    slugsuz: 0,
  };

  try {
    // Her durumda is_admin() guard — service client path'inde RLS bypass olduğundan kritik
    const guard = await checkAdminAccess();
    if (!guard.authorized) {
      logger.warn('adminKonumOzetiniGetir: admin guard başarısız', { status: guard.status });
      return bos;
    }

    const supabaseOrPromise = buildSupabaseClient();
    const supabase =
      supabaseOrPromise instanceof Promise ? await supabaseOrPromise : supabaseOrPromise;

    const sb = supabase as any;
    const [toplam, koordinatsiz, sehirsiz, ilcesiz, slugsuz] = await Promise.all([
      sb.from('businesses').select('*', { count: 'exact', head: true }),
      sb
        .from('businesses')
        .select('*', { count: 'exact', head: true })
        .or('lat.is.null,lng.is.null'),
      sb
        .from('businesses')
        .select('*', { count: 'exact', head: true })
        .is('city', null),
      sb
        .from('businesses')
        .select('*', { count: 'exact', head: true })
        .is('district', null),
      sb
        .from('businesses')
        .select('*', { count: 'exact', head: true })
        .or('city_slug.is.null,district_slug.is.null,category_slug.is.null'),
    ]);

    return {
      toplam: toplam.count ?? 0,
      koordinatsiz: koordinatsiz.count ?? 0,
      sehirsiz: sehirsiz.count ?? 0,
      ilcesiz: ilcesiz.count ?? 0,
      slugsuz: slugsuz.count ?? 0,
    };
  } catch (err) {
    logger.warn('adminKonumOzetiniGetir: istisna', { err });
    return bos;
  }
}
