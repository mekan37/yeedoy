import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import { logAudit, AUDIT } from '@/src/lib/denetim';

export const runtime = 'nodejs';

const ADMIN_ROLES = ['super_admin', 'admin', 'community_mod'] as const;

const CreateMenuSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().optional(),
  is_active: z.boolean().default(true),
});

async function assertAdmin(request: Request) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { ok: false as const, status: 401 };

  const { data: profile, error: profileError } = await (supabase as any)
    .from('user_profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError || !profile || !ADMIN_ROLES.includes(profile.role)) {
    return { ok: false as const, status: 403 };
  }

  return { ok: true as const, userId: user.id };
}

type RouteContext = { params: Promise<{ id: string }> };

// POST — işletmeye yeni menü oluştur
export async function POST(request: Request, context: RouteContext) {
  const { id: businessId } = await context.params;

  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });

  const rl = rateLimit(`admin-menu-create:${identity}`, 20, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const guard = await assertAdmin(request);
  if (!guard.ok) {
    return NextResponse.json(
      { error: guard.status === 401 ? 'unauthorized' : 'forbidden' },
      { status: guard.status },
    );
  }

  // UUID doğrulama
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(businessId)) {
    return NextResponse.json({ error: 'invalid_payload', issues: { id: ['Geçersiz işletme ID'] } }, { status: 400 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = CreateMenuSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const serviceClient = createSupabaseServiceClient();
  if (!serviceClient) {
    logger.warn('Admin menu create: no service client available');
    return NextResponse.json({ error: 'service_unavailable' }, { status: 503 });
  }

  // İşletmenin var olduğunu doğrula
  const { data: business, error: bizError } = await (serviceClient as any)
    .from('businesses')
    .select('id')
    .eq('id', businessId)
    .maybeSingle();

  if (bizError || !business) {
    return NextResponse.json({ error: 'not_found' }, { status: 404 });
  }

  const { name, description, is_active } = parsed.data;

  const { data: created, error: insertError } = await (serviceClient as any)
    .from('menus')
    .insert({
      business_id: businessId,
      title: name,
      status: is_active ? 'published' : 'archived',
      source: 'admin',
      created_by: guard.userId,
    })
    .select('id, title, business_id, status')
    .single();

  if (insertError) {
    logger.warn('Admin menu create failed', { error: insertError.message, businessId });
    return NextResponse.json({ error: 'create_failed' }, { status: 500 });
  }

  logAudit({
    supabase: serviceClient as any,
    userId: guard.userId,
    action: AUDIT.MENU_CREATE,
    resourceType: 'menu',
    resourceId: created.id,
    newData: { business_id: businessId, title: name, description, status: created.status },
    request,
  });

  return NextResponse.json(
    { data: { id: created.id, name: created.title, business_id: created.business_id } },
    { status: 201 },
  );
}
