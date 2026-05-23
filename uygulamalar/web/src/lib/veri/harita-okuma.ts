import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import type { AcikIsletmeKarti } from '@/src/ui/acik/tipler';

export type HaritaIsletme = AcikIsletmeKarti & {
  lat: number;
  lng: number;
};

const SEHIR_KOORDINAT: Record<string, [number, number]> = {
  'İstanbul': [41.015, 28.979],
  'Ankara': [39.925, 32.866],
  'İzmir': [38.423, 27.143],
  'Bursa': [40.182, 29.066],
  'Antalya': [36.896, 30.713],
  'Adana': [37.001, 35.321],
  'Gaziantep': [37.066, 37.383],
  'Konya': [37.868, 32.485],
  'Mersin': [36.801, 34.614],
  'Diyarbakır': [37.910, 40.230],
  'Trabzon': [41.005, 39.724],
  'Erzurum': [39.905, 41.269],
  'Samsun': [41.286, 36.330],
  'Eskişehir': [39.776, 30.520],
  'Denizli': [37.773, 29.087],
  'Kayseri': [38.735, 35.487],
  'Malatya': [38.357, 38.317],
  'Sakarya': [40.765, 30.402],
};

function idOffset(id: string, idx: number): [number, number] {
  const hash = id.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return [((hash * 7 + idx * 13) % 100) / 1000 - 0.05, ((hash * 11 + idx * 17) % 100) / 1000 - 0.05];
}

function toHaritaIsletme(row: any, idx: number): HaritaIsletme | null {
  const lat = row.lat ?? null;
  const lng = row.lng ?? null;
  const city: string = row.city ?? '';
  const cityCoord = SEHIR_KOORDINAT[city];

  if (lat && lng) {
    return { ...normalizeRow(row), lat, lng };
  }
  if (cityCoord) {
    const [dLat, dLng] = idOffset(row.id, idx);
    return { ...normalizeRow(row), lat: cityCoord[0] + dLat, lng: cityCoord[1] + dLng };
  }
  return null;
}

function normalizeRow(row: any): AcikIsletmeKarti {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug ?? row.public_slug ?? row.id,
    publicSlug: row.public_slug ?? null,
    category: row.category ?? null,
    city: row.city ?? null,
    district: row.district ?? null,
    address: row.address ?? null,
    logoUrl: row.logo_url ?? null,
    coverUrl: row.cover_url ?? null,
    isVerified: row.is_verified ?? false,
    avgRating: row.avg_rating ?? null,
    reviewCount: row.review_count ?? null,
    medianPriceCents: row.median_price_cents ?? null,
    menuHref: `/m/${row.slug ?? row.public_slug ?? row.id}`,
  };
}

export async function getMapBusinesses(limit = 120): Promise<HaritaIsletme[]> {
  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as any)
    .from('businesses')
    .select('id,name,slug,public_slug,category,city,district,address,logo_url,cover_url,is_verified,lat,lng')
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .limit(limit) as { data: any[] | null };

  const rows = data ?? [];
  return rows.flatMap((row, idx) => {
    const h = toHaritaIsletme(row, idx);
    return h ? [h] : [];
  });
}
