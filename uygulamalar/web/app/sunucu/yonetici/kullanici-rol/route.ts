import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { z } from 'zod';

// 'admin' bilerek yok: bu route yalnızca app_metadata.role yazıyor, gerçek
// admin panel erişimi admin_users tablosundan geliyor — buradan asla
// verilemez (bkz. rol-degistir-istemci.tsx).
const schema = z.object({
  userId: z.string().uuid(),
  role: z.enum(['user', 'community_mod']),
});

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (!isAdmin) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  // page:roller izni atlanıyordu — bu izne sahip olmayan bir admin bile başka
  // kullanıcıların rolünü (community_mod/admin) değiştirebiliyordu.
  const { data: yetkili } = await supabaseAny.rpc('has_permission_v1', { p_permission: 'page:roller' });
  if (!yetkili) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const rl = await rateLimit(`rol:${user.id}`, 30, 3_600_000); // 30/hour
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data: dbRate, error: dbRateError } = await supabaseAny.rpc('consume_rate_limit_v1', {
    p_action: 'admin_role_assign',
    p_daily_limit: 30,
  });
  if (dbRateError || (dbRate as { ok?: boolean } | null)?.ok === false) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { userId, role } = parsed.data;
  const serviceClient = createSupabaseServiceClient();
  if (!serviceClient) return NextResponse.json({ error: 'Service unavailable' }, { status: 503 });

  // Prevent editing super_admin
  const { data: target, error: targetError } = await serviceClient.auth.admin.getUserById(userId);
  if (targetError || !target.user) {
    return NextResponse.json({ error: 'User not found' }, { status: 404 });
  }

  const currentRole = String(
    target.user.app_metadata?.role ?? target.user.user_metadata?.role ?? 'user',
  ).toLocaleLowerCase('tr-TR');

  if (currentRole === 'super_admin') {
    return NextResponse.json({ error: 'Cannot modify super_admin' }, { status: 403 });
  }

  const { error } = await serviceClient.auth.admin.updateUserById(userId, {
    app_metadata: {
      ...target.user.app_metadata,
      role,
    },
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  // Bu değişiklik hiçbir depoya yazılmıyordu — "kim, kimin rolünü ne zaman
  // değiştirdi" sorusu cevaplanamıyordu.
  await supabaseAny
    .rpc('log_admin_action_v1', {
      p_action: 'user_role_change',
      p_target_table: 'auth.users',
      p_target_id: userId,
      p_meta: { from: currentRole, to: role },
    })
    .then(() => {})
    .catch(() => {});

  return NextResponse.json({ ok: true });
}
