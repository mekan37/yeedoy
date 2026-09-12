import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { logger } from '@/src/lib/kayitci';
import { z } from 'zod';

const reviewSchema = z.object({
  id: z.string().uuid(),
  status: z.enum(['in_review', 'rejected', 'cancelled']),
});
const executeSchema = z.object({ id: z.string().uuid() });

type SupabaseAny = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };

async function guard(sb: SupabaseAny): Promise<NextResponse | null> {
  const { data: yetkili } = await sb.rpc('has_permission_v1', { p_permission: 'page:kvkk-gdpr' });
  if (!yetkili) return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  return null;
}

// PATCH — talebi incelemeye al / reddet / iptal et (yorum kararları, geri alınabilir)
export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb);
  if (guardRes) return guardRes;

  const rl = await rateLimit(`hesap-silme-review:${user.id}`, 30, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = reviewSchema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { data: affected, error } = await sb.rpc('admin_review_account_deletion_request_v1', {
    p_id: parsed.data.id,
    p_status: parsed.data.status,
  });
  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  if (((affected as number) ?? 0) === 0) return NextResponse.json({ error: 'not_found' }, { status: 404 });
  return NextResponse.json({ ok: true });
}

// POST — talebi gerçekten uygula: kullanıcı verisini siler + auth hesabını
// kaldırır. Geri alınamaz — bu yüzden PATCH'ten ayrı, daha sıkı rate limitli.
export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb);
  if (guardRes) return guardRes;

  const rl = await rateLimit(`hesap-silme-execute:${user.id}`, 10, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = executeSchema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { data: rpcData, error: rpcError } = await sb.rpc('admin_execute_account_deletion_v1', {
    p_request_id: parsed.data.id,
  });
  if (rpcError) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  const result = rpcData as { ok: boolean; error?: string; user_id?: string } | null;
  if (!result?.ok) return NextResponse.json({ error: result?.error ?? 'unknown' }, { status: 422 });

  // Uygulama verisi zaten silindi (RPC), şimdi auth kaydını sil — self-servis
  // /sunucu/hesap/sil ile aynı 2 adımlı desen (service_role gerektirir).
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey) {
    logger.error('hesap-silme-talepleri: SUPABASE_SERVICE_ROLE_KEY tanımsız');
    return NextResponse.json({ error: 'server_misconfigured' }, { status: 500 });
  }
  const { createClient } = await import('@supabase/supabase-js');
  const admin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceKey,
    { auth: { persistSession: false } },
  );
  const { error: deleteError } = await admin.auth.admin.deleteUser(result.user_id!);
  if (deleteError) {
    // Uygulama verisi silindi, talep 'completed' işaretlendi ama auth kaydı
    // duruyor (self-servis rotadaki aynı "zombi hesap" riski). Manuel tekrar
    // deneme güvenli — auth.admin.deleteUser idempotenttir.
    logger.error('hesap-silme-talepleri: auth.users silinemedi', { error: deleteError.message, userId: result.user_id });
    return NextResponse.json({ error: 'auth_delete_failed' }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
