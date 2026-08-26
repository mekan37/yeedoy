import { NextRequest, NextResponse } from 'next/server';
import { checkBotId } from 'botid/server';
import { getMapBusinesses } from '@/src/lib/veri/harita-okuma';
import { rateLimit, getRequestIdentity, getClientIp } from '@/src/lib/rate-limit';

export async function GET(req: NextRequest) {
  const { isBot } = await checkBotId();
  if (isBot) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const { searchParams } = new URL(req.url);
  const lat = parseFloat(searchParams.get('lat') ?? '39.9334');
  const lng = parseFloat(searchParams.get('lng') ?? '32.8597');
  const radius = parseFloat(searchParams.get('radius') ?? '50');
  const category = searchParams.get('category');

  if (isNaN(lat) || isNaN(lng)) {
    return NextResponse.json({ error: 'invalid params' }, { status: 400 });
  }

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
