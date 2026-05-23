import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  itemId: z.string().uuid(),
  stockCount: z.number().int().min(0).optional(),
  isAvailable: z.boolean().optional(),
});

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { itemId, stockCount, isAvailable } = parsed.data;

  const update: Record<string, unknown> = {};
  if (stockCount !== undefined) update.stock_count = stockCount;
  if (isAvailable !== undefined) update.is_available = isAvailable;

  if (Object.keys(update).length === 0) return NextResponse.json({ error: 'Nothing to update' }, { status: 400 });

  const { error } = await (supabase as any)
    .from('menu_items')
    .update(update)
    .eq('id', itemId);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
