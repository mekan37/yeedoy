import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import type { Database } from '@/src/lib/taban/veri-tanimlari';
import { getOwnerBusinessIds, hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

export const runtime = 'nodejs';

type MenuRow = Database['public']['Tables']['menus']['Row'];

const createMenuSchema = z.object({
  business_id: z.string().uuid(),
  title: z.string().min(1).max(200),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-menus-create:${identity}`, 20, 60_000);
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
  const parsed = createMenuSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { business_id, title } = parsed.data;

  const isOwner = await hasOwnerBusiness(supabase as any, user.id, business_id);
  if (!isOwner) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const { data: menu, error } = await (supabase as any)
    .from('menus')
    .insert({
      business_id,
      title,
      status: 'draft',
      created_by: user.id,
      source: 'owner',
      version: 1,
      confidence_score: 1,
    })
    .select('id, title, status, created_at')
    .single();

  if (error) {
    logger.warn('Owner menu create failed', { business_id, error: (error as { message: string }).message });
    return NextResponse.json({ error: 'insert_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: menu }, { status: 201 });
}

export async function GET(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-menus-list:${identity}`, 60, 60_000);
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

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  if (businessIds.length === 0) {
    return NextResponse.json({ data: [] });
  }

  const { data: menus, error } = await supabase
    .from('menus')
    .select('id, business_id, title, status, kind, created_at, updated_at')
    .in('business_id', businessIds)
    .order('created_at', { ascending: false });

  if (error) {
    logger.warn('Owner menus list failed', { error: error.message });
    return NextResponse.json({ error: 'fetch_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: (menus ?? []) as MenuRow[] });
}
