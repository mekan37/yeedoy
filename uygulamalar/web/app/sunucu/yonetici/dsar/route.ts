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

  const rl = await rateLimit(`dsar:${user.id}`, 20, 3_600_000); // 20/hour
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { id, status } = parsed.data;

  // privacy_requests'te admin için UPDATE RLS policy'si yok — doğrudan tablo
  // yazması RLS tarafından sessizce 0 satır güncelliyordu (P0: KVKK silme
  // talebi sonsuza kadar "submitted" kalıyordu ama UI "başarılı" gösteriyordu).
  const { data: affected, error } = await supabaseAny.rpc('admin_update_privacy_request_status_v1', {
    p_id: id,
    p_status: status,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if ((affected ?? 0) === 0) return NextResponse.json({ error: 'not_found' }, { status: 404 });
  return NextResponse.json({ ok: true });
}
