import { z } from 'zod';
import { NextResponse } from 'next/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const orderItemSchema = z.object({
  name: z.string().min(1).max(100),
  qty: z.number().int().min(1).max(20),
  note: z.string().max(200).optional(),
});

const schema = z.object({
  businessId: z.string().uuid(),
  tableNumber: z.string().min(1).max(20).transform((s) => s.trim()),
  items: z.array(orderItemSchema).min(1).max(30),
  note: z.string().max(500).optional(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`table-order:${identity}`, 10, 120_000); // 10/2dk
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  // Anonim istemci — müşteri giriş yapmak zorunda değil
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  const { data, error } = await supabaseAny.rpc('submit_table_order_v1', {
    p_business_id: parsed.data.businessId,
    p_table_number: parsed.data.tableNumber,
    p_items_json: JSON.stringify(parsed.data.items),
    p_note: parsed.data.note ?? null,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if (!data?.ok) return NextResponse.json({ error: data?.error ?? 'failed' }, { status: 400 });

  return NextResponse.json({ ok: true, orderId: data.order_id });
}
