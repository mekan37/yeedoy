import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';

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

  const businesses = await getOwnerBusinesses(
    supabase as any,
    user.id,
      'id, name, slug, public_slug, category, description, phone, city, district, address, is_active, is_verified, logo_url, cover_url, created_at',
  );

  businesses.sort((a: any, b: any) => (b.created_at ?? '').localeCompare(a.created_at ?? ''));

  return NextResponse.json({ data: businesses });
}
