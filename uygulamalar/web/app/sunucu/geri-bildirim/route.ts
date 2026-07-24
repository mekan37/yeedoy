import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
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

  const limit = rateLimit(limitKey, maxRequests, 60_000);
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

  const supabase = createSupabaseServiceClient();
  if (!supabase) {
    logger.warn('Feedback: no supabase service client available');
    return NextResponse.json({ error: 'service_unavailable' }, { status: 503 });
  }

  // menu_feedback table added in migration 20260422000002; types updated after db push.
  // @ts-expect-error menu_feedback not yet in generated types
  const { error } = await supabase.from('menu_feedback').insert({
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
