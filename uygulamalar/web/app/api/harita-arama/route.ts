import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { rateLimit, getRequestIdentity } from '@/src/lib/oran-siniri';

const schema = z.object({ q: z.string().min(1).max(100).trim() });

export async function GET(req: NextRequest) {
  const id = getRequestIdentity({
    ip: req.headers.get('x-forwarded-for'),
    userAgent: req.headers.get('user-agent'),
  });
  if (!rateLimit(`harita-arama:${id}`, 30, 60_000)) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const parsed = schema.safeParse({ q: new URL(req.url).searchParams.get('q') });
  if (!parsed.success) return NextResponse.json([]);

  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as unknown as {
    from: (t: string) => {
      select: (...a: unknown[]) => {
        eq: (...a: unknown[]) => {
          or: (...a: unknown[]) => {
            not: (...a: unknown[]) => {
              not: (...a: unknown[]) => {
                limit: (n: number) => Promise<{ data: Record<string, unknown>[] | null }>;
              };
            };
          };
        };
      };
    };
  })
    .from('businesses')
    .select('id,name,slug,public_slug,category,lat,lng,logo_url,cover_url,is_verified')
    .eq('is_active', true)
    .or(`name.ilike.%${parsed.data.q}%,category.ilike.%${parsed.data.q}%`)
    .not('lat', 'is', null)
    .not('lng', 'is', null)
    .limit(8);

  if (!data) return NextResponse.json([]);

  return NextResponse.json(
    data.map((b) => ({
      id: String(b.id),
      name: String(b.name),
      slug: String(b.public_slug ?? b.slug ?? ''),
      category: b.category ? String(b.category) : '',
      lat: Number(b.lat),
      lng: Number(b.lng),
      logo_url: b.logo_url ? String(b.logo_url) : null,
      cover_url: b.cover_url ? String(b.cover_url) : null,
      avg_rating: null,
      is_verified: Boolean(b.is_verified),
    })),
    { headers: { 'Cache-Control': 'no-store' } },
  );
}
