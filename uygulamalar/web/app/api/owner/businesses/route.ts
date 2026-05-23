import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-businesses-list:${identity}`, 60, 60_000);
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

  const { data: businesses, error } = await supabase
    .from('businesses')
    .select(
      'id, name, slug, public_slug, category, description, phone, city, district, address, is_active, is_verified, logo_url, cover_url, created_at',
    )
    .eq('owner_id', user.id)
    .order('created_at', { ascending: false });

  if (error) {
    logger.warn('Owner businesses list failed', { userId: user.id, error: error.message });
    return NextResponse.json({ error: 'fetch_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: businesses });
}
