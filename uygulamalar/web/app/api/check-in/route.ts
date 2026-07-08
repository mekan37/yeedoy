import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { rateLimit, getRequestIdentity } from '@/src/lib/rate-limit';

const schema = z.object({ businessId: z.string().uuid() });

export async function POST(req: Request) {
  const ip =
    req.headers.get('cf-connecting-ip') ??
    req.headers.get('x-real-ip') ??
    getRequestIdentity({
      ip: req.headers.get('x-forwarded-for'),
      userAgent: req.headers.get('user-agent'),
    });
  const limit = rateLimit(`checkin:${ip}`, 10, 60_000);
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const body = await req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success)
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data, error } = await (supabase as any).rpc('submit_checkin_v1', {
    p_business_id: parsed.data.businessId,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  const result = data as { ok: boolean; error?: string; visit_id?: string } | null;
  if (!result?.ok) {
    const rpcError = result?.error ?? '';
    if (rpcError === 'already_checked_in_today')
      return NextResponse.json({ error: 'already_checked_in_today' }, { status: 409 });
    if (rpcError === 'business_not_found')
      return NextResponse.json({ error: 'not_found' }, { status: 404 });
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  return NextResponse.json({ data: { visitId: result.visit_id } }, { status: 200 });
}
