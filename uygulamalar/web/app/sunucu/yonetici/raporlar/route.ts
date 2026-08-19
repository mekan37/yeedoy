import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  reportId: z.string().uuid(),
  status: z.enum(['open', 'reviewing', 'closed']),
  adminNote: z.string().max(1000).optional(),
});

async function requireAdmin() {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabaseAny, user: null, response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return { supabaseAny, user, response: NextResponse.json({ error: 'Forbidden' }, { status: 403 }) };

  return { supabaseAny, user, response: null };
}

export async function PATCH(req: Request) {
  const { supabaseAny, user, response } = await requireAdmin();
  if (response) return response;

  const rl = rateLimit(`raporlar:${user!.id}`, 60, 60_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { reportId, status, adminNote } = parsed.data;

  const update: Record<string, unknown> = {
    status,
    handled_by: user!.id,
    handled_at: new Date().toISOString(),
  };
  if (adminNote !== undefined) update.admin_note = adminNote.trim() || null;

  const { error } = await supabaseAny.from('reports').update(update).eq('id', reportId);
  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  return NextResponse.json({ ok: true });
}
