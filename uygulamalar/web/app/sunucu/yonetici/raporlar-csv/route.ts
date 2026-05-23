import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const status = url.searchParams.get('status') ?? 'all';
  const hedef = url.searchParams.get('hedef') ?? '';

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response('Unauthorized', { status: 401 });

  let query = (supabase as any)
    .from('reports')
    .select('id, target_type, reason, details, status, created_at')
    .order('created_at', { ascending: false })
    .limit(5000);

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
    },
  });
}
