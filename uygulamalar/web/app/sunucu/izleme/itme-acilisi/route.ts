import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';

const schema = z.object({
  campaign_id: z.string().uuid(),
});

/**
 * POST /sunucu/izleme/itme-acilisi
 *
 * Increments push_campaigns.opened_count when a user taps a push notification.
 * Called by the mobile app on notification tap, best-effort.
 */
export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`push_open:${identity}`, 20, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = schema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const supabase = createSupabaseServiceClient();
  if (!supabase) {
    return NextResponse.json({ error: 'service_unavailable' }, { status: 503 });
  }

  // Increment opened_count — ignore not-found rows (best-effort)
  await (supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<unknown>;
  }).rpc('increment_push_campaign_open_v1', {
    p_campaign_id: parsed.data.campaign_id,
  });

  return NextResponse.json({ ok: true });
}

