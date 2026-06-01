import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

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

const ANALYTICS_PAGE_SIZE = 10_000;

const pageSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ type: string }> },
) {
  const { type } = await params;
  const url = new URL(_req.url);
  const parsedPage = pageSchema.safeParse(Object.fromEntries(url.searchParams));
  const page = parsedPage.success ? parsedPage.data.page : 1;
  const rangeFrom = (page - 1) * ANALYTICS_PAGE_SIZE;
  const rangeTo = rangeFrom + ANALYTICS_PAGE_SIZE - 1;

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };

  // Admin kontrolü
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Yetkisiz' }, { status: 401 });

  const { data: isAdmin } = await supabase.rpc('is_admin' as any);
  if (!isAdmin) return NextResponse.json({ error: 'Yetkisiz' }, { status: 403 });

  let rows: Record<string, unknown>[] = [];
  let filename = 'export.csv';

  if (type === 'businesses') {
    const { data } = await supabase
      .from('businesses')
      .select('id,name,category,city,district,address,phone,lat,lng,source,is_active,is_verified,created_at')
      .eq('is_active', true)
      .order('name');
    rows = data ?? [];
    filename = `yeedoy-isletmeler-${new Date().toISOString().slice(0,10)}.csv`;

  } else if (type === 'menus') {
    const { data } = await supabase
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
    const { data } = await supabaseAny
      .from('analytics_events')
      .select('event_name,business_id,created_at')
      .gte('created_at', since30d)
      .order('created_at', { ascending: false })
      .range(rangeFrom, rangeTo);
    rows = data ?? [];
    filename = `yeedoy-analitik-30g-${new Date().toISOString().slice(0,10)}.csv`;

  } else {
    return NextResponse.json({ error: 'Geçersiz tür' }, { status: 400 });
  }

  const csv = toCsv(rows);
  const headers: Record<string, string> = {
    'Content-Type':        'text/csv; charset=utf-8',
    'Content-Disposition': `attachment; filename="${filename}"`,
  };
  if (type === 'analytics') {
    headers['X-Row-Limit'] = String(ANALYTICS_PAGE_SIZE);
    headers['X-Page'] = String(page);
    headers['X-Page-Size'] = String(ANALYTICS_PAGE_SIZE);
  }
  return new NextResponse(csv, { headers });
}
