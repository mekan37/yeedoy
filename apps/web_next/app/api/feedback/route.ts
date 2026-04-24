import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

const feedbackSchema = z.object({
  businessId: z.string().uuid(),
  rating: z.number().int().min(1).max(5),
  category: z.enum(['menu', 'price', 'service', 'app', 'other']),
  message: z.string().max(500).optional(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });

  // 5 requests per minute per identity
  const limit = rateLimit(`feedback:${identity}`, 5, 60_000);
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
