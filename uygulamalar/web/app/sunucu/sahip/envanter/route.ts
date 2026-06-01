import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { z } from 'zod';

const schema = z.object({
  itemId: z.string().uuid(),
  stockCount: z.number().int().min(0).optional(),
  isAvailable: z.boolean().optional(),
});

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { itemId, stockCount, isAvailable } = parsed.data;

  // Verify caller owns the business this menu item belongs to
  const { data: item } = await supabaseAny
    .from('menu_items')
    .select('menu:menu_id(business_id)')
    .eq('id', itemId)
    .maybeSingle();

  const businessId = item?.menu?.business_id;
  if (!businessId) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const owned = await hasOwnerBusiness(supabaseAny, user.id, businessId);
  if (!owned) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const update: Record<string, unknown> = {};
  if (stockCount !== undefined) update.stock_count = stockCount;
  if (isAvailable !== undefined) update.is_available = isAvailable;

  if (Object.keys(update).length === 0) return NextResponse.json({ error: 'Nothing to update' }, { status: 400 });

  const { error } = await supabaseAny
    .from('menu_items')
    .update(update)
    .eq('id', itemId);

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}
