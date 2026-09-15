import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit, getRequestIdentity, getClientIp } from '@/src/lib/oran-siniri';

const schema = z.object({
  q: z.string().max(120).optional(),
  city: z.string().max(80).optional(),
  district: z.string().max(80).optional(),
  limit: z.coerce.number().int().min(1).max(30).default(10),
});

// GET /sunucu/isletme-ara?q=adana&city=Adana&district=Seyhan&limit=10
export async function GET(request: NextRequest) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const rl = await rateLimit(`isletme-ara:${identity}`, 60, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const parsed = schema.safeParse(Object.fromEntries(request.nextUrl.searchParams));
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }
  const q        = parsed.data.q?.trim() ?? '';
  const city     = parsed.data.city?.trim() ?? '';
  const district = parsed.data.district?.trim() ?? '';
  const limit    = parsed.data.limit;

  if (!q && !city && !district) {
    return NextResponse.json({ results: [] });
  }

  const supabase = await createSupabaseServerClient();

  let query = supabase
    .from('businesses')
    .select('id, name, category, city, district, address, slug')
    .eq('is_active', true)
    .limit(limit);

  if (q) {
    query = query.ilike('name', `%${q}%`);
  }
  if (city) {
    query = query.ilike('city', `%${city}%`);
  }
  if (district) {
    query = query.ilike('district', `%${district}%`);
  }

  const { data, error } = await query.order('name');

  if (error) {
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  return NextResponse.json({ results: data ?? [] });
}
