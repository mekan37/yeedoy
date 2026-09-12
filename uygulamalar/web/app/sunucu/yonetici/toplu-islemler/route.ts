import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';
import { z } from 'zod';

const schema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('businesses'),
    ids: z.array(z.string().uuid()).min(1).max(200),
    action: z.enum(['approve', 'reject']),
  }),
  z.object({
    type: z.literal('reviews'),
    ids: z.array(z.string().uuid()).min(1).max(200),
    action: z.enum(['approve', 'remove']),
  }),
  z.object({
    type: z.literal('users'),
    ids: z.array(z.string().uuid()).min(1).max(200),
    action: z.enum(['ban', 'warn', 'clear']),
  }),
]);

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  // reviews / user_profiles / bulk_op_logs / is_admin are not in Database types yet
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const rl = await rateLimit(`toplu:${user.id}`, 10, 3_600_000); // 10/hour
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data: dbRate } = await supabaseAny.rpc('consume_rate_limit_v1', {
    p_action: 'admin_bulk_op',
    p_limit: 10,
  });
  if (dbRate && (dbRate as { ok?: boolean }).ok === false) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const data = parsed.data;

  if (data.type === 'businesses') {
    const isActive = data.action === 'approve';
    const { error } = await supabaseAny
      .from('businesses')
      .update({ is_active: isActive })
      .in('id', data.ids);
    if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  } else if (data.type === 'reviews') {
    const newStatus = data.action === 'approve' ? 'approved' : 'rejected';
    const { error } = await supabaseAny.rpc('admin_moderate_reviews_v1', {
      p_ids: data.ids,
      p_status: newStatus,
    });
    if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  } else if (data.action === 'ban' || data.action === 'clear') {
    // user_profiles'ta admin için UPDATE RLS policy'si yok — doğrudan tablo
    // yazması RLS tarafından sessizce 0 satır güncelliyordu (P0: "başarılı"
    // dönüp hiçbir şey yapmıyordu). Artık is_admin() guard'lı, gerçek
    // etkilenen satır sayısını döndüren bir RPC üzerinden yapılıyor.
    const { data: affected, error } = await supabaseAny.rpc('admin_set_shadow_banned_v1', {
      p_user_ids: data.ids,
      p_banned: data.action === 'ban',
    });
    if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
    if ((affected ?? 0) !== data.ids.length) {
      return NextResponse.json(
        { ok: true, count: affected ?? 0, requested: data.ids.length, partial: true },
        { status: 207 },
      );
    }
  }

  supabaseAny
    .from('bulk_op_logs')
    .insert({
      op_type: data.type,
      count: data.ids.length,
      action: data.action,
      operator: user.id,
    })
    .then(({ error: logError }: { error: { message: string } | null }) => {
      if (logError) logger.error('[toplu-islemler] audit log insert failed:', { message: logError.message });
    })
    .catch((err: unknown) => {
      logger.error('[toplu-islemler] audit log unexpected error:', { err });
    });

  return NextResponse.json({ ok: true, count: data.ids.length });
}
