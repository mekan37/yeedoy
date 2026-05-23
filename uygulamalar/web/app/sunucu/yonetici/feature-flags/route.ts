import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

// Toggle flag
export async function PATCH(request: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const body = await request.json() as { id: string; enabled: boolean };
  const { error } = await (supabase as any)
    .from('runtime_feature_flags')
    .update({ enabled: body.enabled, updated_at: new Date().toISOString() })
    .eq('key', body.id);

  if (error) return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}

// Create flag
export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await (supabase as any).rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const body = await request.json() as {
    key: string;
    description: string;
    rollout_percent: number;
    environment: string;
  };

  if (!body.key || !/^[a-z0-9_]+$/.test(body.key)) {
    return NextResponse.json({ ok: false, error: 'Geçersiz flag anahtarı' }, { status: 400 });
  }

  const { error } = await (supabase as any).from('runtime_feature_flags').insert({
    key: body.key,
    enabled: false,
    rollout_percent: Math.min(100, Math.max(0, body.rollout_percent)),
    metadata: {
      description: body.description || null,
      environment: body.environment ?? 'staging',
    },
    updated_by: user.id,
    updated_at: new Date().toISOString(),
  });

  if (error) {
    if (error.code === '23505') {
      return NextResponse.json({ ok: false, error: 'Bu anahtar zaten mevcut' }, { status: 409 });
    }
    return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });
  }
  return NextResponse.json({ ok: true });
}
