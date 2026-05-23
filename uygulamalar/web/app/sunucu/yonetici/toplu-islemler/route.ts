import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
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

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const data = parsed.data;

  if (data.type === 'businesses') {
    const isActive = data.action === 'approve';
    const { error } = await (supabase as any)
      .from('businesses')
      .update({ is_active: isActive })
      .in('id', data.ids);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  } else if (data.type === 'reviews') {
    const newStatus = data.action === 'approve' ? 'approved' : 'rejected';
    const { error } = await (supabase as any)
      .from('reviews')
      .update({ status: newStatus })
      .in('id', data.ids);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  } else {
    const update =
      data.action === 'ban'
        ? { shadow_banned: true }
        : data.action === 'clear'
          ? { shadow_banned: false }
          : null;

    if (update) {
      const { error } = await (supabase as any)
        .from('user_profiles')
        .update(update)
        .in('user_id', data.ids);
      if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    }
  }

  await (supabase as any)
    .from('bulk_op_logs')
    .insert({
      op_type: data.type,
      count: data.ids.length,
      action: data.action,
      operator: user.id,
    })
    .then(() => null)
    .catch(() => null);

  return NextResponse.json({ ok: true, count: data.ids.length });
}
