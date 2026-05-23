import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { searchAdminIndex, normalizeAdminSearchType } from '@/src/lib/veri/admin/yonetici-arama';

export const runtime = 'nodejs';

const searchSchema = z.object({
  q: z.string().trim().min(2).max(120),
  type: z.enum(['businesses', 'users', 'all']).default('all'),
  limit: z.coerce.number().int().min(1).max(30).default(5),
});

export async function GET(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`admin-search:${identity}`, 120, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const url = new URL(request.url);
  const parsed = searchSchema.safeParse({
    q: url.searchParams.get('q') ?? '',
    type: normalizeAdminSearchType(url.searchParams.get('type')),
    limit: url.searchParams.get('limit') ?? undefined,
  });

  if (!parsed.success) {
    return NextResponse.json({ data: [] });
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (!isAdmin) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const serviceClient = createSupabaseServiceClient();
  const searchClient = serviceClient ?? supabase;
  const results = await searchAdminIndex(searchClient as any, parsed.data.q, {
    type: parsed.data.type,
    limit: parsed.data.limit,
  });

  return NextResponse.json({ data: results });
}
