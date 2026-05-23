import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';

export async function GET() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const businesses = (await getOwnerBusinesses<{ id: string; name: string; is_active: boolean | null }>(
    supabase as any,
    user.id,
    'id, name, is_active',
  )).filter((business) => business.is_active !== false);

  const allOrders: any[] = [];
  for (const biz of businesses) {
    const { data } = await (supabase as any).rpc('get_pending_table_orders_v1', {
      p_business_id: biz.id,
      p_limit: 30,
    }).catch(() => ({ data: null }));
    if (data) {
      allOrders.push(...(data as any[]).map((o: any) => ({ ...o, businessName: biz.name })));
    }
  }

  allOrders.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

  return NextResponse.json({ orders: allOrders });
}
