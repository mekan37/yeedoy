import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';
import { ADMIN_PERMISSIONS, type AdminPermissionKey } from '@/src/lib/admin-izinler';

const permissionKeys = ADMIN_PERMISSIONS.map((p) => p.key) as [AdminPermissionKey, ...AdminPermissionKey[]];
const permissionEnum = z.enum(permissionKeys);

const createSchema = z.object({
  name: z.string().min(1).max(60),
  description: z.string().max(200).optional(),
  permissions: z.array(permissionEnum),
});
const updateSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(60),
  description: z.string().max(200).optional(),
  permissions: z.array(permissionEnum),
  isActive: z.boolean(),
});
const deleteSchema = z.object({ id: z.string().uuid() });

type SupabaseAny = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };

async function guard(sb: SupabaseAny, userId: string): Promise<NextResponse | null> {
  const { data: isAdmin } = await sb.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const rl = rateLimit(`roller:${userId}`, 30, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data: dbRate } = await sb.rpc('consume_rate_limit_v1', { p_action: 'admin_roller_write', p_daily_limit: 30 });
  if (dbRate && (dbRate as { ok?: boolean }).ok === false) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }
  return null;
}

function mapPgError(error: { message?: string } | null): { status: number; error: string } {
  const msg = error?.message ?? '';
  if (msg.includes('unauthorized')) return { status: 403, error: 'forbidden' };
  if (msg.includes('not_found')) return { status: 404, error: 'not_found' };
  if (msg.includes('validation_error')) return { status: 422, error: msg.replace('validation_error: ', '') };
  return { status: 500, error: 'internal_error' };
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = createSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });

  const { data, error } = await sb.rpc('admin_create_role_v1', {
    p_name: parsed.data.name,
    p_description: parsed.data.description ?? null,
    p_permissions: parsed.data.permissions,
  });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { id: data } }, { status: 200 });
}

export async function PATCH(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = updateSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });

  const { error } = await sb.rpc('admin_update_role_v1', {
    p_role_id: parsed.data.id,
    p_name: parsed.data.name,
    p_description: parsed.data.description ?? null,
    p_permissions: parsed.data.permissions,
    p_is_active: parsed.data.isActive,
  });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}

export async function DELETE(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = deleteSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { error } = await sb.rpc('admin_delete_role_v1', { p_role_id: parsed.data.id });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}
