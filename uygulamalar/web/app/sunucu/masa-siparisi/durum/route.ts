import { z } from 'zod';
import { NextResponse } from 'next/server';
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
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data, error } = await (supabase as any).rpc('update_table_order_status_v1', {
    p_order_id: parsed.data.orderId,
    p_status: parsed.data.status,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if (!data?.ok) return NextResponse.json({ error: data?.error }, { status: 403 });

  return NextResponse.json({ ok: true });
}
