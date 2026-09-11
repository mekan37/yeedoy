import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';

const feedbackSchema = z.object({
  businessId: z.string().uuid(),
  rating: z.number().int().min(1).max(5),
  category: z.enum(['menu', 'price', 'service', 'app', 'other']),
  message: z.string().max(500).optional(),
});

export async function POST(request: Request) {
  // Auth-aware rate limiting: authenticated users get 10/min, anonymous get 2/min
  // (anonymous key is harder to forge than spoofing x-forwarded-for)
  const supabaseServer = await createSupabaseServerClient();
  const { data: { user } } = await supabaseServer.auth.getUser();

  let limitKey: string;
  let maxRequests: number;

  if (user) {
    limitKey = `feedback:user:${user.id}`;
    maxRequests = 10;
  } else {
    const ip = getClientIp(request.headers) ?? 'unknown-ip';
    limitKey = `feedback:anon:${ip}`;
    maxRequests = 2;
  }

  const limit = await rateLimit(limitKey, maxRequests, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = feedbackSchema.safeParse(rawBody);

  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { businessId, rating, category, message } = parsed.data;

  // menu_feedback'in RLS politikası anon+authenticated insert'i zaten aynı
  // kısıtlarla (rating 1-5, category enum, message<=500) izin veriyor —
  // service-role'e gerek yok; oturumlu istemci RLS'i ikinci bir savunma
  // katmanı olarak canlı tutuyor.
  const { error } = await supabaseServer.from('menu_feedback').insert({
    business_id: businessId,
    rating,
    category,
    message: message?.trim() || null,
  });

  if (error) {
    logger.warn('Feedback insert failed', { businessId, error: error.message });
    return NextResponse.json({ error: 'insert_failed' }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
