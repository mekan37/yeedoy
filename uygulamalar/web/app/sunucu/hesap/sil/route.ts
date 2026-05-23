import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  // Hesap silme — günde max 3 deneme (spam koruması)
  const limit = rateLimit(`delete-account:${identity}`, 3, 86_400_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  // 1. Uygulama verilerini temizle (RPC)
  const { data: rpcData, error: rpcError } = await (supabase as any)
    .rpc('delete_user_account_v1');

  if (rpcError) {
    return NextResponse.json({ error: rpcError.message }, { status: 500 });
  }
  if (!rpcData?.ok) {
    return NextResponse.json({ error: rpcData?.error ?? 'unknown' }, { status: 500 });
  }

  // 2. Auth kaydını sil (service role gerektirir)
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (serviceKey) {
    const { createClient } = await import('@supabase/supabase-js');
    const admin = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      serviceKey,
      { auth: { persistSession: false } },
    );
    await admin.auth.admin.deleteUser(user.id);
  }

  // 3. Oturumu kapat
  await supabase.auth.signOut();

  return NextResponse.json({ ok: true });
}
