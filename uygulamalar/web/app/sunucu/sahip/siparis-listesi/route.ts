import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';

export async function GET() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const rl = rateLimit(`siparislist:${user.id}`, 60, 60_000); // 60/min
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const businesses = (await getOwnerBusinesses<{ id: string; name: string; is_active: boolean | null }>(
    supabase as any,
    user.id,
    'id, name, is_active',
  )).filter((business) => business.is_active !== false);

  // get_pending_table_orders_v1 is not in Database types yet
  const supabaseAny = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown }> };

  // Parallelise: one RPC call per business concurrently instead of sequential for...of await
  const results = await Promise.all(
    businesses.map((biz) =>
      supabaseAny
        .rpc('get_pending_table_orders_v1', { p_business_id: biz.id, p_limit: 30 })
        .catch(() => ({ data: null }))
        .then(({ data }) =>
          data
            ? (data as any[]).map((o: any) => ({ ...o, businessName: biz.name }))
            : [],
        ),
    ),
  );

  const allOrders: any[] = results.flat();

  allOrders.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

  return NextResponse.json({ orders: allOrders });
}
