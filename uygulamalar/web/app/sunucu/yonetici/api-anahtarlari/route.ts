import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { randomBytes, createHash } from 'crypto';
import { z } from 'zod';

const postSchema = z.object({ name: z.string().min(1).max(100) });
const deleteSchema = z.object({ id: z.string().uuid() });

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

  const rl = rateLimit(`apikey:${user.id}`, 10, 3_600_000); // 10/hour
  if (!rl.ok) return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });

  const { data: dbRate } = await supabaseAny.rpc('consume_rate_limit_v1', {
    p_action: 'admin_apikey_write',
    p_limit: 10,
  });
  if (dbRate && (dbRate as { ok?: boolean }).ok === false) {
    return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });
  }

  const rawBodyPost = await request.json().catch(() => null);
  const parsedPost = postSchema.safeParse(rawBodyPost);
  if (!parsedPost.success) {
    return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  }
  const body = rawBodyPost as { name: string; scope?: string; expiresDays?: number };

  const rawKey = generateApiKey();
  const keyHash = createHash('sha256').update(rawKey).digest('hex');
  const prefix = rawKey.slice(0, 10);

  const expiresDays = body.expiresDays ?? 0;
  const expiresAt = expiresDays > 0
    ? new Date(Date.now() + expiresDays * 86400000).toISOString()
    : null;

  const { error } = await supabaseAny.from('api_keys').insert({
    name: body.name.trim(),
    key_hash: keyHash,
    prefix,
    scope: body.scope ?? 'read',
    created_by: user.id,
    expires_at: expiresAt,
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });

  if (error) return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });

  return NextResponse.json({ ok: true, key: rawKey });
}

export async function DELETE(request: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const rl2 = rateLimit(`apikey:${user.id}`, 10, 3_600_000); // shared 10/hour bucket with POST
  if (!rl2.ok) return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });

  const { data: dbRate2 } = await supabaseAny.rpc('consume_rate_limit_v1', {
    p_action: 'admin_apikey_write',
    p_limit: 10,
  });
  if (dbRate2 && (dbRate2 as { ok?: boolean }).ok === false) {
    return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });
  }

  const rawBodyDelete = await request.json().catch(() => null);
  const parsedDelete = deleteSchema.safeParse(rawBodyDelete);
  if (!parsedDelete.success) {
    return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  }
  const { error } = await supabaseAny
    .from('api_keys')
    .update({ is_active: false, updated_at: new Date().toISOString() })
    .eq('id', parsedDelete.data.id);

  if (error) return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}
