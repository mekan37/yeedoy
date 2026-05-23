import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { randomBytes, createHash } from 'crypto';

function generateApiKey() {
  const raw = randomBytes(32).toString('hex');
  return `yk_${raw}`;
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const body = await request.json() as {
    name: string;
    scope: string;
    expiresDays: number;
  };

  if (!body.name?.trim()) {
    return NextResponse.json({ ok: false, error: 'Anahtar adı zorunludur' }, { status: 400 });
  }

  const rawKey = generateApiKey();
  const keyHash = createHash('sha256').update(rawKey).digest('hex');
  const prefix = rawKey.slice(0, 10);

  const expiresAt = body.expiresDays > 0
    ? new Date(Date.now() + body.expiresDays * 86400000).toISOString()
    : null;

  const { error } = await (supabase as any).from('api_keys').insert({
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

  if (error) return NextResponse.json({ ok: false, error: error.message }, { status: 500 });

  return NextResponse.json({ ok: true, key: rawKey });
}

export async function DELETE(request: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const body = await request.json() as { id: string };
  const { error } = await (supabase as any)
    .from('api_keys')
    .update({ is_active: false, updated_at: new Date().toISOString() })
    .eq('id', body.id);

  if (error) return NextResponse.json({ ok: false, error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
