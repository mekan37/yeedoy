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
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabase, user: null, response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };

  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (!isAdmin) return { supabase, user, response: NextResponse.json({ error: 'Forbidden' }, { status: 403 }) };

  const { data: yetkili } = await supabase.rpc('has_permission_v1', { p_permission: 'page:raporlar' });
  if (!yetkili) return { supabase, user, response: NextResponse.json({ error: 'forbidden' }, { status: 403 }) };

  return { supabase, user, response: null };
}

export async function PATCH(req: Request) {
  const { supabase, user, response } = await requireAdmin();
  if (response) return response;

  const rl = await rateLimit(`raporlar:${user!.id}`, 60, 60_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { reportId, status, adminNote } = parsed.data;

  const update: { status: typeof status; handled_by: string; handled_at: string; admin_note?: string | null } = {
    status,
    handled_by: user!.id,
    handled_at: new Date().toISOString(),
  };
  if (adminNote !== undefined) update.admin_note = adminNote.trim() || null;

  const { error } = await supabase.from('reports').update(update).eq('id', reportId);
  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  return NextResponse.json({ ok: true });
}
