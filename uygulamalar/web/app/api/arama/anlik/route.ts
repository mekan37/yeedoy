import { NextResponse } from 'next/server';
import { z } from 'zod';
import { checkBotId } from 'botid/server';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { rateLimit, getRequestIdentity, getClientIp } from '@/src/lib/oran-siniri';

const querySchema = z.object({
  q: z.string().min(1).max(100).trim(),
  lat: z.coerce.number().min(-90).max(90).optional(),
  lng: z.coerce.number().min(-180).max(180).optional(),
});

export async function GET(request: Request) {
  const { isBot } = await checkBotId();
  if (isBot) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const id = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  if (!rateLimit(`anlik-arama:${id}`, 60, 60_000)) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const { searchParams } = new URL(request.url);
  const parsed = querySchema.safeParse({
    q: searchParams.get('q'),
    lat: searchParams.get('lat') ?? undefined,
    lng: searchParams.get('lng') ?? undefined,
  });

  if (!parsed.success) {
    return NextResponse.json({ businesses: [], items: [] });
  }

  const { q, lat, lng } = parsed.data;
  const supabase = createSupabasePublicClient();
  const sb = supabase as unknown as { rpc: (fn: string, args?: any) => any; from: (t: string) => any };
  const hasLocation = lat != null && lng != null;

  // ── İşletmeler ─────────────────────────────────────────────────────────────
  type BizRow = {
    id: string; name: string; slug: string | null; public_slug: string | null;
    category: string | null; city: string | null; district: string | null;
    logo_url: string | null; cover_url: string | null; is_verified: boolean;
    is_open_now?: boolean | null; distance_km?: number | null;
    avg_rating?: number | null;
  };

  let businesses: BizRow[] = [];

  if (hasLocation) {
    const { data: nearby } = await sb.rpc('search_nearby_businesses_v3', {
      p_lat: lat,
      p_lng: lng,
      p_radius_km: 25,
      p_query: q,
      p_limit: 6,
    }) as { data: any[] | null };

    if (nearby && nearby.length > 0) {
      const ids = nearby.map((r: any) => r.id as string);
      const { data: details } = await sb
        .from('businesses')
        .select('id,slug,public_slug,logo_url,cover_url,is_verified')
        .in('id', ids) as { data: any[] | null };
      const detailMap = new Map((details ?? []).map((d: any) => [d.id, d]));

      businesses = nearby.map((row: any) => {
        const d = detailMap.get(row.id) ?? {};
        return {
          id: row.id,
          name: row.name,
          slug: d.slug ?? null,
          public_slug: d.public_slug ?? null,
          category: row.category ?? null,
          city: row.city ?? null,
          district: row.district ?? null,
          logo_url: d.logo_url ?? null,
          cover_url: d.cover_url ?? null,
          is_verified: d.is_verified ?? false,
          is_open_now: typeof row.is_open_now === 'boolean' ? row.is_open_now : null,
          distance_km: typeof row.distance_km === 'number' ? Math.round(row.distance_km * 10) / 10 : null,
          avg_rating: typeof row.avg_rating === 'number' ? row.avg_rating : null,
        } satisfies BizRow;
      });
    }
  }

  // Eğer konum yoksa veya konum araması yeterli sonuç vermediyse metin araması yap
  if (businesses.length < 3) {
    const { data: textResults } = await sb
      .from('businesses')
      .select('id,name,slug,public_slug,category,city,district,logo_url,cover_url,is_verified')
      .eq('is_active', true)
      .or(`name.ilike.%${q}%,category.ilike.%${q}%`)
      .limit(6) as { data: BizRow[] | null };

    if (textResults) {
      const existingIds = new Set(businesses.map((b) => b.id));
      const extra = textResults.filter((b) => !existingIds.has(b.id));
      businesses = [...businesses, ...extra].slice(0, 6);
    }
  }

  // ── Menü kalemleri ─────────────────────────────────────────────────────────
  type ItemRow = {
    id: string; name: string; description: string | null;
    price_cents: number | null; image_url: string | null;
    business_id: string;
  };

  const { data: rawItems } = await sb
    .from('menu_items')
    .select('id,name,description,price_cents,image_url,business_id')
    .eq('is_available', true)
    .ilike('name', `%${q}%`)
    .limit(6) as { data: ItemRow[] | null };

  const itemBizIds = [...new Set((rawItems ?? []).map((i) => i.business_id))];
  let itemBizMap = new Map<string, { name: string; slug: string; public_slug: string | null }>();

  if (itemBizIds.length > 0) {
    const { data: itemBizRows } = await sb
      .from('businesses')
      .select('id,name,slug,public_slug')
      .in('id', itemBizIds)
      .eq('is_active', true) as { data: Array<{ id: string; name: string; slug: string; public_slug: string | null }> | null };

    itemBizMap = new Map((itemBizRows ?? []).map((b) => [b.id, b]));
  }

  const items = (rawItems ?? [])
    .filter((i) => itemBizMap.has(i.business_id))
    .map((i) => {
      const biz = itemBizMap.get(i.business_id)!;
      return {
        id: i.id,
        name: i.name,
        description: i.description,
        price_cents: i.price_cents,
        image_url: i.image_url,
        businessName: biz.name,
        businessSlug: biz.public_slug ?? biz.slug,
      };
    });

  return NextResponse.json(
    {
      businesses: businesses.map((b) => ({
        id: b.id,
        name: b.name,
        slug: b.public_slug ?? b.slug,
        category: b.category,
        city: b.city,
        district: b.district,
        logoUrl: b.logo_url,
        coverUrl: b.cover_url,
        isVerified: b.is_verified,
        isOpenNow: b.is_open_now ?? null,
        distanceKm: b.distance_km ?? null,
        avgRating: b.avg_rating ?? null,
      })),
      items,
    },
    { headers: { 'Cache-Control': 'no-store' } },
  );
}
