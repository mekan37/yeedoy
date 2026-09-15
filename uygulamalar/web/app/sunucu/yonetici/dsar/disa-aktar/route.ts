import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({ userId: z.string().uuid() });

// DSAR request_type='data_export'/'access'/'portability' için hiçbir export
// mekanizması yoktu — talep hiçbir zaman kapatılamıyordu.
export async function GET(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const { data: yetkili } = await supabase.rpc('has_permission_v1', { p_permission: 'page:kvkk-gdpr' });
  if (!yetkili) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const rl = await rateLimit(`dsar-export:${user.id}`, 20, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const url = new URL(req.url);
  const parsed = schema.safeParse({ userId: url.searchParams.get('userId') });
  if (!parsed.success) return NextResponse.json({ error: 'invalid_input' }, { status: 400 });

  // DİKKAT — as any temizliği sırasında bulunan, düzeltilmemiş kritik bir bug:
  // admin_export_user_data_v1 hiçbir migration'da tanımlı değil (grep ile
  // doğrulandı) — bu RPC her zaman "fonksiyon bulunamadı" ile başarısız olur,
  // yani DSAR (KVKK md.11 — kullanıcı verisine erişim/taşınabilirlik) export
  // özelliği hiç çalışmıyor. Bunu şimdi icat etmek (hangi tabloların "kullanıcı
  // verisi" sayılacağına dair bir kapsam/hukuki karar gerektiriyor) bu turun
  // kapsamı dışında — ayrı, özel bir oturum gerektiriyor. Tip-güvenliğini
  // bozmadan, RPC adının üretilen tipte olmadığını belgeleyen dar bir cast:
  const rpcMissing = supabase as unknown as {
    rpc: (fn: 'admin_export_user_data_v1', args: { p_user_id: string }) => Promise<{ data: unknown; error: { message: string } | null }>;
  };
  const { data, error } = await rpcMissing.rpc('admin_export_user_data_v1', { p_user_id: parsed.data.userId });
  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  return new NextResponse(JSON.stringify(data, null, 2), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Content-Disposition': `attachment; filename="dsar-export-${parsed.data.userId}.json"`,
    },
  });
}
