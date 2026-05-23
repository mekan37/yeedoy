import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

function toCsv(rows: Record<string, unknown>[]): string {
  if (!rows.length) return '';
  const headers = Object.keys(rows[0]);
  const escape  = (v: unknown) => {
    const s = v == null ? '' : String(v).replace(/"/g, '""');
    return s.includes(',') || s.includes('"') || s.includes('\n') ? `"${s}"` : s;
  };
  const lines = [
    headers.join(','),
    ...rows.map((r) => headers.map((h) => escape(r[h])).join(',')),
  ];
  return lines.join('\r\n');
}

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ type: string }> },
) {
  const { type } = await params;
  const supabase = await createSupabaseServerClient();

  // Admin kontrolü
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Yetkisiz' }, { status: 401 });

  const isAdmin = await (supabase as any)
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id)
    .in('role', ['admin', 'superadmin'])
    .maybeSingle();

  if (!isAdmin.data) return NextResponse.json({ error: 'Yetkisiz' }, { status: 403 });

  let rows: Record<string, unknown>[] = [];
  let filename = 'export.csv';

  if (type === 'businesses') {
    const { data } = await (supabase as any)
      .from('businesses')
      .select('id,name,category,city,district,address,phone,lat,lng,source,is_active,is_verified,created_at')
      .eq('is_active', true)
      .order('name');
    rows = data ?? [];
    filename = `yeedoy-isletmeler-${new Date().toISOString().slice(0,10)}.csv`;

  } else if (type === 'menus') {
    const { data } = await (supabase as any)
      .from('menu_items')
      .select('id,name,category:section_id,price,currency,is_available,created_at,menu:menu_id(business_id)')
      .eq('is_available', true)
      .order('name')
      .limit(50000);
    rows = (data ?? []).map((r: any) => ({
      id: r.id, name: r.name, price: r.price, currency: r.currency,
      business_id: r.menu?.business_id, created_at: r.created_at,
    }));
    filename = `yeedoy-menu-ogeler-${new Date().toISOString().slice(0,10)}.csv`;

  } else if (type === 'analytics') {
    const since30d = new Date(Date.now() - 30 * 86400000).toISOString();
    const { data } = await (supabase as any)
      .from('analytics_events')
      .select('event_name,business_id,created_at')
      .gte('created_at', since30d)
      .order('created_at', { ascending: false })
      .limit(100000);
    rows = data ?? [];
    filename = `yeedoy-analitik-30g-${new Date().toISOString().slice(0,10)}.csv`;

  } else {
    return NextResponse.json({ error: 'Geçersiz tür' }, { status: 400 });
  }

  const csv = toCsv(rows);
  return new NextResponse(csv, {
    headers: {
      'Content-Type':        'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`,
    },
  });
}
