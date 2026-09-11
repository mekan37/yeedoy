import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { getMapBusinesses } from '@/src/lib/veri/harita-okuma';
import { rateLimit, getRequestIdentity, getClientIp } from '@/src/lib/rate-limit';

// lat/lng/radius hiçbir sınıra tabi değildi — ?radius=999999 ile pratikte
// tüm ülke tek istekte taranabiliyordu (pahalı sorgu + scraping riski).
// Türkiye kabaca bu koordinat aralığında; radius "yakınımda" harita
// özelliği için makul bir üst sınırla (150 km) sınırlandı.
const querySchema = z.object({
  lat: z.coerce.number().min(35).max(43).default(39.9334),
  lng: z.coerce.number().min(25).max(45).default(32.8597),
  radius: z.coerce.number().min(0.1).max(150).default(50),
  category: z.string().max(80).optional(),
});

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const parsed = querySchema.safeParse(Object.fromEntries(searchParams));
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid params' }, { status: 400 });
  }
  const { lat, lng, radius, category } = parsed.data;

  const identity = getRequestIdentity({
    ip: getClientIp(req.headers),
    userAgent: req.headers.get('user-agent'),
  });
  const rl = rateLimit(`harita:${identity}`, 60, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const businesses = await getMapBusinesses(lat, lng, radius, 200, category);
  return NextResponse.json(businesses, {
    headers: {
      'Cache-Control': 'public, s-maxage=30, stale-while-revalidate=60',
    },
  });
}
