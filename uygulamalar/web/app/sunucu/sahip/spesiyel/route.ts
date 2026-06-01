import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';

const schema = z.object({
  menuItemId: z.string().uuid(),
  isSpecial: z.boolean(),
  note: z.string().max(200).optional(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`today-special:${identity}`, 30, 60_000);
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data, error } = await supabaseAny.rpc('set_today_special_v1', {
    p_menu_item_id: parsed.data.menuItemId,
    p_is_special: parsed.data.isSpecial,
    p_note: parsed.data.note ?? null,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if (!data?.ok) {
    const status = data?.error === 'forbidden' ? 403 : 404;
    return NextResponse.json({ error: data?.error }, { status });
  }

  return NextResponse.json({ ok: true });
}
