import { NextResponse } from 'next/server';
import { mapTrackEventToRpc, parseRpcTrackResult, trackEventSchema } from '@/src/lib/analytics';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`track:${identity}`, 40, 60_000);

  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = trackEventSchema.safeParse(rawBody);

  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const uaFamily = (request.headers.get('user-agent') || 'unknown').split(' ')[0]?.slice(0, 80) || 'unknown';
  const mappedEvent = mapTrackEventToRpc(parsed.data);

  if (mappedEvent.eventName === 'menu_link_opened' && !parsed.data.clientId) {
    return NextResponse.json({ error: 'client_id_required' }, { status: 400 });
  }

  const supabase = createSupabaseServiceClient() ?? (await createSupabaseServerClient());
  const { data, error } = await (supabase as unknown as {
    rpc: (
      fn: 'log_event_v1',
      args: {
        p_event_name: string;
        p_business_id: string;
        p_menu_id: string | null;
        p_source: string;
        p_client_id: string | null;
        p_meta: Record<string, unknown>;
      },
    ) => Promise<{ data: unknown; error: unknown }>;
  }).rpc('log_event_v1', {
    p_event_name: mappedEvent.eventName,
    p_business_id: parsed.data.businessId,
    p_menu_id: parsed.data.menuId ?? null,
    p_source: parsed.data.source,
    p_client_id: parsed.data.clientId ?? null,
    p_meta: {
      ...mappedEvent.meta,
      ua_family: uaFamily,
    },
  });

  if (error) {
    logger.warn('Failed to track analytics event', {
      event: parsed.data.eventName,
      rpcEvent: mappedEvent.eventName,
      businessId: parsed.data.businessId,
      error,
    });
    return NextResponse.json({ error: 'tracking_failed' }, { status: 500 });
  }

  const rpcResult = parseRpcTrackResult(data);
  if (!rpcResult.ok) {
    const status =
      rpcResult.code === 'rate_limited'
        ? 429
        : rpcResult.code === 'invalid_event' || rpcResult.code === 'client_required'
          ? 400
          : 500;

    logger.warn('Analytics event rejected by RPC', {
      event: parsed.data.eventName,
      rpcEvent: mappedEvent.eventName,
      businessId: parsed.data.businessId,
      code: rpcResult.code,
    });

    return NextResponse.json(
      {
        error: 'tracking_rejected',
        code: rpcResult.code,
      },
      { status },
    );
  }

  return NextResponse.json({ ok: true, data: rpcResult });
}
