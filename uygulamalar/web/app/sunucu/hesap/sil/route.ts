import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';

export async function POST() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  // Hesap silme — kullanıcı başına günde max 3 deneme (spam koruması).
  // Auth'tan SONRA, user.id ile anahtarlanıyor — eskiden IP+User-Agent
  // (spoofable, auth'tan önce) kullanılıyordu.
  const limit = await rateLimit(`delete-account:${user.id}`, 3, 86_400_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  // 1. Uygulama verilerini temizle (RPC)
  const { data: rpcDataRaw, error: rpcError } = await supabase
    .rpc('delete_user_account_v1');
  const rpcData = rpcDataRaw as { ok: boolean; error?: string } | null;

  if (rpcError) {
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }
  if (!rpcData?.ok) {
    return NextResponse.json({ error: rpcData?.error ?? 'unknown' }, { status: 500 });
  }

  // 2. Auth kaydını sil (service role gerektirir)
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey) {
    return NextResponse.json({ error: 'server_misconfigured' }, { status: 500 });
  }
  const { createClient } = await import('@supabase/supabase-js');
  const admin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceKey,
    { auth: { persistSession: false } },
  );
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    // Uygulama verisi zaten silindi ama auth kaydı duruyor — "zombi hesap".
    // ok:true DÖNMÜYORUZ ki kullanıcı/istemci gerçek durumdan haberdar olsun
    // ve tekrar denesin; RPC idempotent olduğu için tekrar çağrı güvenli.
    return NextResponse.json({ error: 'auth_delete_failed' }, { status: 500 });
  }

  // 3. Oturumu kapat
  await supabase.auth.signOut();

  return NextResponse.json({ ok: true });
}
