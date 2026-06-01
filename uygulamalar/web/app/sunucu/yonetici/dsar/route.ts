import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  id: z.string().uuid(),
  status: z.enum(['in_review', 'resolved', 'rejected']),
});

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const rl = rateLimit(`dsar:${user.id}`, 20, 3_600_000); // 20/hour
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { id, status } = parsed.data;
  const update = {
    status,
    resolved_at: status === 'resolved' || status === 'rejected' ? new Date().toISOString() : null,
  };

  const { error } = await supabaseAny
    .from('privacy_requests')
    .update(update)
    .eq('id', id);

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}
