import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { rateLimit, getRequestIdentity } from '@/src/lib/oran-siniri';

const schema = z.object({
  id: z.string().uuid(),
});

export async function GET(req: NextRequest) {
  const id = getRequestIdentity({
    ip: req.headers.get('x-forwarded-for'),
    userAgent: req.headers.get('user-agent'),
  });
  if (!rateLimit(`isletme-ozet:${id}`, 60, 60_000)) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const parsed = schema.safeParse({ id: new URL(req.url).searchParams.get('id') });
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const supabase = createSupabasePublicClient();
  const sb = supabase as unknown as { from: (t: string) => any };

  const [bizRes, statsRes] = await Promise.all([
    sb
      .from('businesses')
      .select('id,name,slug,public_slug,description,logo_url,cover_url,category,city,district,address,phone,is_verified,is_active')
      .eq('id', parsed.data.id)
      .eq('is_active', true)
      .maybeSingle() as Promise<{ data: Record<string, unknown> | null }>,
    sb
      .from('businesses_with_stats')
      .select('avg_rating,reviews_count')
      .eq('id', parsed.data.id)
      .maybeSingle() as Promise<{ data: Record<string, unknown> | null }>,
  ]);

  const biz = bizRes.data;
  if (!biz) return NextResponse.json({ error: 'not_found' }, { status: 404 });

  const stats = statsRes.data;

  return NextResponse.json(
    {
      id: String(biz.id),
      name: String(biz.name ?? ''),
      slug: String(biz.public_slug ?? biz.slug ?? biz.id),
      description: biz.description ? String(biz.description) : null,
      logo_url: biz.logo_url ? String(biz.logo_url) : null,
      cover_url: biz.cover_url ? String(biz.cover_url) : null,
      category: biz.category ? String(biz.category) : null,
      city: biz.city ? String(biz.city) : null,
      district: biz.district ? String(biz.district) : null,
      address: biz.address ? String(biz.address) : null,
      phone: biz.phone ? String(biz.phone) : null,
      is_verified: Boolean(biz.is_verified),
      avg_rating: stats?.avg_rating != null ? Number(stats.avg_rating) : null,
      reviews_count: stats?.reviews_count != null ? Number(stats.reviews_count) : null,
    },
    { headers: { 'Cache-Control': 'public, s-maxage=120, stale-while-revalidate=300' } },
  );
}
