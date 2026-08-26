import { NextResponse } from 'next/server';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const lat = parseFloat(searchParams.get('lat') ?? '');
  const lng = parseFloat(searchParams.get('lng') ?? '');
  const radius = Math.min(50, Math.max(1, parseInt(searchParams.get('r') ?? '10', 10)));
  const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') ?? '40', 10)));

  if (!isFinite(lat) || !isFinite(lng)) {
    return NextResponse.json({ error: 'invalid_coordinates' }, { status: 400 });
  }

  const supabase = createSupabasePublicClient();
  const sb = supabase as unknown as { rpc: (fn: string, args?: any) => any; from: (t: string) => any };

  const { data: nearby, error } = await sb.rpc('search_nearby_businesses_v3', {
    p_lat: lat,
    p_lng: lng,
    p_radius_km: radius,
    p_limit: limit,
  }) as { data: any[] | null; error: any };

  if (error || !nearby || nearby.length === 0) {
    return NextResponse.json({ data: [] });
  }

  const ids = nearby.map((r: any) => r.id as string);
  const { data: details } = await sb
    .from('businesses')
    .select('id,slug,public_slug,logo_url,cover_url,is_verified,price_level,avg_rating,review_count')
    .in('id', ids) as { data: any[] | null };

  const detailMap = new Map((details ?? []).map((d: any) => [d.id, d]));

  const businesses = nearby.map((row: any) => {
    const d = detailMap.get(row.id) ?? {};
    const slug = d.slug ?? d.public_slug ?? row.id;
    return {
      id: row.id,
      name: row.name,
      slug,
      publicSlug: d.public_slug ?? null,
      category: row.category ?? null,
      city: row.city ?? null,
      district: row.district ?? null,
      address: row.address ?? null,
      logoUrl: d.logo_url ?? null,
      coverUrl: d.cover_url ?? null,
      isVerified: d.is_verified ?? false,
      isOpenNow: typeof row.is_open_now === 'boolean' ? row.is_open_now : null,
      avgRating: typeof row.avg_rating === 'number' ? row.avg_rating : (typeof d.avg_rating === 'number' ? d.avg_rating : null),
      distanceKm: typeof row.distance_km === 'number' ? Math.round(row.distance_km * 10) / 10 : null,
      priceLevel: d.price_level ?? null,
      medianPriceCents: typeof row.median_price_cents === 'number' ? row.median_price_cents : null,
      menuHref: `/m/${slug}`,
    };
  });

  return NextResponse.json({ data: businesses }, {
    headers: { 'Cache-Control': 'no-store' },
  });
}
