import { NextResponse } from 'next/server';
import { z } from 'zod';
import { rateLimit, getRequestIdentity, getClientIp } from '@/src/lib/oran-siniri';
import { fetchIsletmelerListesi } from '@/src/lib/veri/isletme-listesi';

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
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const rl = rateLimit(`isletmeler:${identity}`, 90, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const { searchParams } = new URL(request.url);
  const parsed = schema.safeParse(Object.fromEntries(searchParams));
  if (!parsed.success) {
    return NextResponse.json({ data: [], total: 0 });
  }

  const { q, category, city, sort, minRating, verified, limit } = parsed.data;
  const { data, total } = await fetchIsletmelerListesi({
    q, category, city, sort, minRating, limit,
    verified: verified === 'true',
  });

  // Sonuçlar herkese açık ve kullanıcıya özel değil — sabit `no-store` her
  // isteği (varsayılan/filtresiz sorgu dahil) DB'ye zorluyordu. Kısa bir
  // CDN cache penceresi (aynı sorgu string'i için) gerçek zamanlılığı
  // önemli ölçüde etkilemeden yükü büyük ölçüde azaltır.
  return NextResponse.json(
    { data, total },
    { headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300' } },
  );
}
