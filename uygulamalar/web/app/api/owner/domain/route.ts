import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export const runtime = 'nodejs';

const domainSchema = z.object({
  business_id: z.string().uuid(),
  domain: z
    .string()
    .min(4)
    .max(253)
    .regex(
      /^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$/,
      'Geçerli bir domain girin',
    ),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  // 3 istek/saat
  const limit = rateLimit(`owner-domain-add:${identity}`, 3, 3_600_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = domainSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { business_id, domain } = parsed.data;

  // İlk sahiplik kontrolü: businesses.owner_id üzerinden
  const { data: biz, error: bizError } = await (supabase as any)
    .from('businesses')
    .select('id')
    .eq('id', business_id)
    .eq('owner_id', user.id)
    .maybeSingle();

  if (bizError || !biz) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  // SECURITY DEFINER RPC: token üretimi + upsert + business_claims sahiplik denetimi
  const { data: result, error: rpcError } = await (supabase as any).rpc(
    'upsert_custom_domain_v1',
    { p_business_id: business_id, p_domain: domain.toLowerCase() },
  ) as { data: { dns_txt_token: string; domain: string } | null; error: { message: string } | null };

  if (rpcError) {
    const msg = rpcError.message ?? '';
    if (msg.includes('not_owner')) {
      return NextResponse.json({ error: 'forbidden' }, { status: 403 });
    }
    if (msg.includes('domain_taken')) {
      return NextResponse.json({ error: 'domain_taken' }, { status: 409 });
    }
    if (msg.includes('invalid_domain')) {
      return NextResponse.json({ error: 'invalid_domain' }, { status: 400 });
    }
    logger.warn('upsert_custom_domain_v1 failed', { business_id, domain, error: msg });
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  if (!result) {
    logger.warn('upsert_custom_domain_v1 returned null', { business_id, domain });
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  return NextResponse.json({ data: { dns_txt_token: result.dns_txt_token } });
}
