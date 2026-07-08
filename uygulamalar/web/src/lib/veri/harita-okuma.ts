import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export interface HaritaIsletme {
  id: string;
  name: string;
  slug: string;
  category: string;
  lat: number;
  lng: number;
  avg_rating: number | null;
  logo_url: string | null;
  is_verified: boolean;
}

export async function getMapBusinesses(
  centerLat = 39.9334,
  centerLng = 32.8597,
  radiusKm = 50,
  limit = 200,
): Promise<HaritaIsletme[]> {
  try {
    const supabase = createSupabasePublicClient();

    // nearby_businesses_v2 is not yet in the generated Database types;
    // using unknown cast until types are regenerated.
    const sb = supabase as unknown as {
      rpc: (name: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
    };
    const { data, error } = await sb.rpc('nearby_businesses_v2', {
      p_lat: centerLat,
      p_lng: centerLng,
      p_radius_m: radiusKm * 1000,
      p_limit: limit,
    });

    if (error || !data) return [];

    return (data as Array<Record<string, unknown>>)
      .filter((b) => b.lat != null && b.lng != null)
      .map((b) => ({
        id: String(b.id ?? ''),
        name: String(b.name ?? ''),
        slug: String(b.slug ?? b.public_slug ?? ''),
        category: String(b.category ?? ''),
        lat: Number(b.lat),
        lng: Number(b.lng),
        avg_rating: b.avg_rating != null ? Number(b.avg_rating) : null,
        logo_url: b.logo_url != null ? String(b.logo_url) : null,
        is_verified: Boolean(b.is_verified),
      }));
  } catch {
    return [];
  }
}
