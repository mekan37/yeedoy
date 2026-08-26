import { NextResponse } from 'next/server';
import { z } from 'zod';
import { checkBotId } from 'botid/server';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { rateLimit, getRequestIdentity, getClientIp } from '@/src/lib/oran-siniri';

const schema = z.object({
  q:         z.string().max(120).optional(),
  category:  z.string().max(80).optional(),
  city:      z.string().max(80).optional(),
  sort:      z.enum(['rating', 'reviews', 'az']).default('rating'),
  minRating: z.coerce.number().min(0).max(5).default(0),
  verified:  z.enum(['true', 'false']).optional(),
  limit:     z.coerce.number().min(1).max(48).default(24),
});

export async function GET(request: Request) {
  const { isBot } = await checkBotId();
  if (isBot) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  if (!rateLimit(`isletmeler:${identity}`, 90, 60_000)) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const { searchParams } = new URL(request.url);
  const parsed = schema.safeParse(Object.fromEntries(searchParams));
  if (!parsed.success) {
    return NextResponse.json({ data: [], total: 0 });
  }

  const { q, category, city, sort, minRating, verified, limit } = parsed.data;
  const supabase = createSupabasePublicClient();
  const sb = supabase as unknown as { from: (t: string) => any };

  // ── 1. businesses_with_stats: sıralı + filtreli liste ──────────────────────
  let statsQ = sb
    .from('businesses_with_stats')
    .select('id,name,category,city,district,is_verified,is_active,reviews_count,avg_rating')
    .eq('is_active', true)
    .limit(limit);

  if (q?.trim())        statsQ = statsQ.ilike('name', `%${q.trim()}%`);
  if (category)         statsQ = statsQ.eq('category', category);
  if (city?.trim())     statsQ = statsQ.ilike('city', `%${city.trim()}%`);
  if (minRating > 0)    statsQ = statsQ.gte('avg_rating', minRating);
  if (verified === 'true') statsQ = statsQ.eq('is_verified', true);

  if (sort === 'reviews') {
    statsQ = statsQ
      .order('reviews_count', { ascending: false, nullsFirst: false })
      .order('avg_rating',    { ascending: false, nullsFirst: false });
  } else if (sort === 'az') {
    statsQ = statsQ.order('name', { ascending: true });
  } else {
    // En yüksek puan (default)
    statsQ = statsQ
      .order('avg_rating',    { ascending: false, nullsFirst: false })
      .order('reviews_count', { ascending: false, nullsFirst: false });
  }

  const { data: statsRows } = await statsQ as { data: any[] | null };
  const rows = statsRows ?? [];

  // ── 2. businesses: slug / logo / cover ─────────────────────────────────────
  const detailMap = new Map<string, { slug: string; public_slug: string | null; logo_url: string | null; cover_url: string | null }>();
  if (rows.length > 0) {
    const ids = rows.map((r: any) => r.id as string);
    const { data: details } = await sb
      .from('businesses')
      .select('id,slug,public_slug,logo_url,cover_url')
      .in('id', ids) as { data: any[] | null };
    for (const d of details ?? []) detailMap.set(d.id, d);
  }

  const data = rows.map((row: any) => {
    const det = detailMap.get(row.id);
    return {
      id:           row.id,
      name:         row.name,
      slug:         det?.public_slug ?? det?.slug ?? row.id,
      category:     row.category    ?? null,
      city:         row.city        ?? null,
      district:     row.district    ?? null,
      logoUrl:      det?.logo_url   ?? null,
      coverUrl:     det?.cover_url  ?? null,
      isVerified:   row.is_verified ?? false,
      reviewsCount: row.reviews_count ?? 0,
      avgRating:    row.avg_rating ? parseFloat(row.avg_rating) : null,
    };
  });

  return NextResponse.json(
    { data, total: data.length },
    { headers: { 'Cache-Control': 'no-store' } },
  );
}
