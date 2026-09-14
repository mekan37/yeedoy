import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { randomBytes, createHash } from 'crypto';
import { z } from 'zod';

// scope: UI'nin sunduğu seçenekler + geriye dönük uyumluluk için RATE_LIMITS'te
// tanımlı eski anahtarlar (bkz. app/yonetici/api-anahtarlari/page.tsx).
const API_KEY_SCOPES = [
  'read', 'write', 'read,write', 'read_write', 'admin',
  'menu:read', 'read:businesses', 'read:menus',
] as const;

const postSchema = z.object({
  name: z.string().trim().min(1).max(60), // DB check constraint: char_length(name) <= 60
  scope: z.enum(API_KEY_SCOPES).default('read'),
  expiresDays: z.number().int().min(0).max(3650).default(0), // 0 = sınırsız, üst sınır 10 yıl
}).strict();
const deleteSchema = z.object({ id: z.string().uuid() }).strict();

function generateApiKey() {
  const raw = randomBytes(32).toString('hex');
  return `yk_${raw}`;
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const { data: yetkili } = await supabaseAny.rpc('has_permission_v1', { p_permission: 'page:api-anahtarlari' });
  if (!yetkili) return NextResponse.json({ ok: false, error: 'forbidden' }, { status: 403 });

  const rl = await rateLimit(`apikey:${user.id}`, 10, 3_600_000); // 10/hour
  if (!rl.ok) return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });

  const { data: dbRate, error: dbRateError } = await supabaseAny.rpc('consume_rate_limit_v1', {
    p_action: 'admin_apikey_write',
    p_daily_limit: 10,
  });
  if (dbRateError || (dbRate as { ok?: boolean } | null)?.ok === false) {
    return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });
  }

  const rawBodyPost = await request.json().catch(() => null);
  const parsedPost = postSchema.safeParse(rawBodyPost);
  if (!parsedPost.success) {
    return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  }
  // Doğrulanan gövde atılıp ham istek gövdesi kullanılıyordu — güvenmediğimiz
  // scope='admin:*' veya expiresDays=1e15 gibi değerler doğrudan DB'ye
  // yazılabiliyordu (mass assignment). Yalnızca parsed.data kullanılıyor.
  const body = parsedPost.data;

  const rawKey = generateApiKey();
  const keyHash = createHash('sha256').update(rawKey).digest('hex');
  const prefix = rawKey.slice(0, 10);

  const expiresAt = body.expiresDays > 0
    ? new Date(Date.now() + body.expiresDays * 86400000).toISOString()
    : null;

  const { data: inserted, error } = await supabaseAny.from('api_keys').insert({
    name: body.name,
    key_hash: keyHash,
    prefix,
    scope: body.scope,
    created_by: user.id,
    expires_at: expiresAt,
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }).select('id').single();

  if (error) return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });

  // API anahtarı oluşturma hiçbir depoya loglanmıyordu — "kim bu anahtarı
  // üretti" sorusu cevaplanamıyordu.
  await supabaseAny.rpc('log_admin_action_v1', {
    p_action: 'api_key.create',
    p_target_table: 'api_keys',
    p_target_id: inserted?.id ?? null,
    p_meta: { name: body.name, prefix, scope: body.scope, expires_at: expiresAt },
  });

  return NextResponse.json({ ok: true, key: rawKey });
}

export async function DELETE(request: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const { data: yetkili } = await supabaseAny.rpc('has_permission_v1', { p_permission: 'page:api-anahtarlari' });
  if (!yetkili) return NextResponse.json({ ok: false, error: 'forbidden' }, { status: 403 });

  const rl2 = await rateLimit(`apikey:${user.id}`, 10, 3_600_000); // shared 10/hour bucket with POST
  if (!rl2.ok) return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });

  const { data: dbRate2, error: dbRate2Error } = await supabaseAny.rpc('consume_rate_limit_v1', {
    p_action: 'admin_apikey_write',
    p_daily_limit: 10,
  });
  if (dbRate2Error || (dbRate2 as { ok?: boolean } | null)?.ok === false) {
    return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });
  }

  const rawBodyDelete = await request.json().catch(() => null);
  const parsedDelete = deleteSchema.safeParse(rawBodyDelete);
  if (!parsedDelete.success) {
    return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  }
  const { data: existing } = await supabaseAny
    .from('api_keys')
    .select('name, prefix, is_active')
    .eq('id', parsedDelete.data.id)
    .maybeSingle();

  const { error } = await supabaseAny
    .from('api_keys')
    .update({ is_active: false, updated_at: new Date().toISOString() })
    .eq('id', parsedDelete.data.id);

  if (error) return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });

  // API anahtarı iptali de loglanmıyordu.
  await supabaseAny.rpc('log_admin_action_v1', {
    p_action: 'api_key.revoke',
    p_target_table: 'api_keys',
    p_target_id: parsedDelete.data.id,
    p_meta: { before: existing ?? null, after: existing ? { ...existing, is_active: false } : null },
  });

  return NextResponse.json({ ok: true });
}
