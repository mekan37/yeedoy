import { z } from 'zod';
import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const schema = z.object({
  orderId: z.string().uuid(),
  status: z.enum(['seen', 'done']),
});

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const rl = rateLimit(`sipdurum:${user.id}`, 30, 60_000); // 30/min
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data, error } = await supabaseAny.rpc('update_table_order_status_v1', {
    p_order_id: parsed.data.orderId,
    p_status: parsed.data.status,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if (!data?.ok) return NextResponse.json({ error: data?.error }, { status: 403 });

  return NextResponse.json({ ok: true });
}
