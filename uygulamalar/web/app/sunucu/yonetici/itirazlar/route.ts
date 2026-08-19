import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`admin-claims-list:${identity}`, 60, 60_000);
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

  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const { data: yetkili } = await supabaseAny.rpc('has_permission_v1', { p_permission: 'page:itirazlar' });
  if (!yetkili) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const serviceClient = createSupabaseServiceClient();
  if (!serviceClient) {
    logger.warn('Admin claims list: no service client available');
    return NextResponse.json({ error: 'service_unavailable' }, { status: 503 });
  }

  const url = new URL(request.url);
  const page = Math.max(1, parseInt(url.searchParams.get('page') ?? '1', 10));
  const pageSize = Math.min(100, Math.max(1, parseInt(url.searchParams.get('page_size') ?? '50', 10)));
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  const serviceClientAny = serviceClient as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: claims, error, count } = await serviceClientAny
    .from('owner_claims')
    .select('*', { count: 'exact' })
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .range(from, to);

  if (error) {
    logger.warn('Admin claims list failed', { error: error.message });
    return NextResponse.json({ error: 'fetch_failed' }, { status: 500 });
  }

  return NextResponse.json({
    data: claims,
    meta: {
      total: count ?? 0,
      page,
      page_size: pageSize,
    },
  });
}
