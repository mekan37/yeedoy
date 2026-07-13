import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export const runtime = 'nodejs';

const updateMenuSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  status: z.enum(['draft', 'published', 'archived']).optional(),
});

type RouteContext = { params: Promise<{ menuId: string }> };

async function resolveOwnership(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  menuId: string,
  userId: string,
): Promise<{ ok: true } | { ok: false; response: NextResponse }> {
  const { data: menu, error } = await (supabase as any)
    .from('menus')
    .select('id, business_id')
    .eq('id', menuId)
    .maybeSingle();

  if (error || !menu) {
    return { ok: false, response: NextResponse.json({ error: 'menu_not_found' }, { status: 404 }) };
  }

  const { data: business, error: bizError } = await (supabase as any)
    .from('businesses')
    .select('owner_id')
    .eq('id', (menu as { business_id: string }).business_id)
    .maybeSingle();

  if (bizError || !business) {
    return { ok: false, response: NextResponse.json({ error: 'business_not_found' }, { status: 404 }) };
  }

  if ((business as { owner_id: string }).owner_id !== userId) {
    return { ok: false, response: NextResponse.json({ error: 'forbidden' }, { status: 403 }) };
  }

  return { ok: true };
}

export async function PATCH(request: Request, context: RouteContext) {
  const { menuId } = await context.params;

  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-menu-patch:${identity}`, 30, 60_000);
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
  const parsed = updateMenuSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  if (Object.keys(parsed.data).length === 0) {
    return NextResponse.json({ error: 'no_fields_to_update' }, { status: 400 });
  }

  const ownership = await resolveOwnership(supabase, menuId, user.id);
  if (!ownership.ok) {
    return ownership.response;
  }

  const { data: updated, error } = await (supabase as any)
    .from('menus')
    .update(parsed.data)
    .eq('id', menuId)
    .select('id, title, status, updated_at')
    .single();

  if (error) {
    logger.warn('Owner menu update failed', {
      menuId,
      error: (error as { message: string }).message,
    });
    return NextResponse.json({ error: 'update_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: updated });
}

export async function DELETE(request: Request, context: RouteContext) {
  const { menuId } = await context.params;

  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-menu-delete:${identity}`, 10, 60_000);
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

  const ownership = await resolveOwnership(supabase, menuId, user.id);
  if (!ownership.ok) {
    return ownership.response;
  }

  // Soft-delete: set status = 'archived'
  const { data: archived, error } = await (supabase as any)
    .from('menus')
    .update({ status: 'archived' })
    .eq('id', menuId)
    .select('id, status')
    .single();

  if (error) {
    logger.warn('Owner menu delete (archive) failed', {
      menuId,
      error: (error as { message: string }).message,
    });
    return NextResponse.json({ error: 'delete_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: archived });
}
