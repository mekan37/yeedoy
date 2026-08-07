import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { CokluSubeOverview } from '@/app/sahip/coklu-sube/coklu-sube-yardimcilari';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const businessId = url.searchParams.get('businessId');
  if (!businessId) return new Response('missing_business_id', { status: 400 });

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return new Response('Unauthorized', { status: 401 });

  const { data: overview, error } = (await (supabase as any).rpc('owner_get_chain_overview_v1', {
    p_business_id: businessId,
  })) as { data: CokluSubeOverview | null; error: { message: string } | null };

  if (error) return new Response('internal_error', { status: 500 });
  if (!overview) return new Response('not_found', { status: 404 });

  const safeStr = (s: string | null) => `"${(s ?? '').replace(/"/g, '""')}"`;
  const header = 'Şube Adı,Şube Etiketi,Şehir,Durum,Görüntülenme,Rezervasyon';
  const lines = overview.branches.map((b) =>
    [safeStr(b.name), safeStr(b.branch_label), safeStr(b.city), b.is_active ? 'Aktif' : 'Pasif', b.views, b.reservations].join(','),
  );
  const csv = [header, ...lines].join('\n');
  const ts = new Date().toISOString().slice(0, 10);

  return new Response('\uFEFF' + csv, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="subeler-${ts}.csv"`,
    },
  });
}
