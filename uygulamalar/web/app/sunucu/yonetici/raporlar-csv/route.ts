import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const PAGE_SIZE = 500;

const querySchema = z.object({
  status: z.string().optional(),
  hedef: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
});

export async function GET(request: Request) {
  const url = new URL(request.url);

  const parsedQuery = querySchema.safeParse(Object.fromEntries(url.searchParams));
  if (!parsedQuery.success) return new Response('invalid_input', { status: 400 });

  const status = parsedQuery.data.status ?? 'all';
  const hedef = parsedQuery.data.hedef ?? '';
  const page = parsedQuery.data.page;
  const rangeFrom = (page - 1) * PAGE_SIZE;
  const rangeTo = rangeFrom + PAGE_SIZE - 1;

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response('Unauthorized', { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return new Response('Forbidden', { status: 403 });

  let query = supabaseAny
    .from('reports')
    .select('id, target_type, reason, details, status, created_at')
    .order('created_at', { ascending: false })
    .range(rangeFrom, rangeTo);

  if (status !== 'all') query = query.eq('status', status);
  if (hedef) query = query.eq('target_type', hedef);

  const { data } = await query;
  const rows = (data ?? []) as Array<{
    id: string;
    target_type: string;
    reason: string | null;
    details: string | null;
    status: string;
    created_at: string;
  }>;

  const header = 'ID,Hedef,Neden,Detay,Durum,Tarih';
  const lines = rows.map(r => {
    const safeStr = (s: string | null) => `"${(s ?? '').replace(/"/g, '""')}"`;
    return [
      r.id,
      r.target_type,
      safeStr(r.reason),
      safeStr(r.details),
      r.status,
      new Date(r.created_at).toLocaleDateString('tr-TR'),
    ].join(',');
  });

  const csv = [header, ...lines].join('\n');
  const ts = new Date().toISOString().slice(0, 10);

  return new Response('﻿' + csv, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="raporlar-${ts}.csv"`,
      'X-Page': String(page),
      'X-Page-Size': String(PAGE_SIZE),
    },
  });
}
