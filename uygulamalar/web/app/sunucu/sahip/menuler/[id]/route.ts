import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

export const runtime = 'nodejs';

const updateMenuSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  status: z.enum(['draft', 'published', 'archived']).optional(),
});

type RouteContext = { params: Promise<{ id: string }> };

async function resolveOwnership(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  menuId: string,
  userId: string,
): Promise<{ ok: true } | { ok: false; response: NextResponse }> {
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: menu, error } = await supabase
    .from('menus')
    .select('id, business_id')
    .eq('id', menuId)
    .maybeSingle();

  if (error || !menu) {
    return { ok: false, response: NextResponse.json({ error: 'menu_not_found' }, { status: 404 }) };
  }

  const isOwner = await hasOwnerBusiness(supabaseAny, userId, (menu as { business_id: string }).business_id);
  if (!isOwner) {
    return { ok: false, response: NextResponse.json({ error: 'forbidden' }, { status: 403 }) };
  }

  return { ok: true };
}

export async function PATCH(request: Request, context: RouteContext) {
  const { id } = await context.params;

  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-menu-patch:${identity}`, 30, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
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

  const ownership = await resolveOwnership(supabase, id, user.id);
  if (!ownership.ok) {
    return ownership.response;
  }

  const { data: updated, error } = await supabaseAny
    .from('menus')
    .update(parsed.data)
    .eq('id', id)
    .select('id, title, status, updated_at')
    .single();

  if (error) {
    logger.warn('Owner menu update failed', {
      menuId: id,
      error: (error as { message: string }).message,
    });
    return NextResponse.json({ error: 'update_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: updated });
}

export async function DELETE(request: Request, context: RouteContext) {
  const { id } = await context.params;

  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-menu-delete:${identity}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const ownership = await resolveOwnership(supabase, id, user.id);
  if (!ownership.ok) {
    return ownership.response;
  }

  // Soft-delete: set status = 'archived'
  const { data: archived, error } = await supabaseAny
    .from('menus')
    .update({ status: 'archived' })
    .eq('id', id)
    .select('id, status')
    .single();

  if (error) {
    logger.warn('Owner menu delete (archive) failed', {
      menuId: id,
      error: (error as { message: string }).message,
    });
    return NextResponse.json({ error: 'delete_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: archived });
}
