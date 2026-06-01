import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const createSchema = z.object({
  name: z.string().min(4).max(64).startsWith('ab_'),
  description: z.string().max(300),
  rolloutPercent: z.number().int().min(1).max(100),
  environment: z.enum(['staging', 'production']).optional(),
});

const patchSchema = z.object({
  id: z.string().min(4).max(64).startsWith('ab_'),
  enabled: z.boolean(),
});

const winnerSchema = z.object({
  id: z.string().min(4).max(64).startsWith('ab_'),
  winner: z.enum(['a', 'b']),
});

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const parsed = createSchema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { name, description, rolloutPercent, environment = 'staging' } = parsed.data;

  const { error } = await supabaseAny
    .from('runtime_feature_flags')
    .insert({
      key: name,
      enabled: true,
      rollout_percent: rolloutPercent,
      metadata: {
        description,
        environment,
        created_at: new Date().toISOString(),
      },
      updated_by: user.id,
    });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const parsed = patchSchema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { id, enabled } = parsed.data;

  const { error } = await supabaseAny
    .from('runtime_feature_flags')
    .update({ enabled, updated_at: new Date().toISOString() })
    .eq('key', id);

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}

export async function PUT(req: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const parsed = winnerSchema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { id, winner } = parsed.data;
  const { data: current } = await supabaseAny
    .from('runtime_feature_flags')
    .select('metadata')
    .eq('key', id)
    .maybeSingle();

  const { error } = await supabaseAny
    .from('runtime_feature_flags')
    .update({
      metadata: { ...((current?.metadata ?? {}) as Record<string, unknown>), winner },
      updated_by: user.id,
      updated_at: new Date().toISOString(),
    })
    .eq('key', id);

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}
