import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({ userId: z.string().uuid(), roleId: z.string().uuid() });

export async function PATCH(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data: isAdmin } = await sb.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const rl = rateLimit(`roller-atama:${user.id}`, 30, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data: dbRate } = await sb.rpc('consume_rate_limit_v1', { p_action: 'admin_rol_atama', p_limit: 30 });
  if (dbRate && (dbRate as { ok?: boolean }).ok === false) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const parsed = schema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { error } = await sb.rpc('admin_assign_user_role_v1', { p_user_id: parsed.data.userId, p_role_id: parsed.data.roleId });
  if (error) {
    const msg = error.message ?? '';
    if (msg.includes('unauthorized')) return NextResponse.json({ error: 'forbidden' }, { status: 403 });
    if (msg.includes('not_found')) return NextResponse.json({ error: 'not_found' }, { status: 404 });
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}
