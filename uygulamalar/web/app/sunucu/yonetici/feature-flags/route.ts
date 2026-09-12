import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { z } from 'zod';

const patchSchema = z.object({
  id: z.string().min(1),
  enabled: z.boolean().optional(),
  rollout_percent: z.number().int().min(0).max(100).optional(),
}).strict();

const postSchema = z.object({
  key: z.string().regex(/^[a-z0-9_]+$/).min(1).max(100),
  description: z.string().max(500).optional(),
  rollout_percent: z.number().int().min(0).max(100),
  environment: z.enum(['staging', 'production']).default('staging'),
  project: z.string().max(100).optional(),
  type: z.string().max(50).optional(),
  is_draft: z.boolean().optional(),
  region: z.string().max(10).optional(),
}).strict();

// Toggle flag / rollout güncelle
export async function PATCH(request: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const { data: yetkili } = await supabaseAny.rpc('has_permission_v1', { p_permission: 'page:feature-flags' });
  if (!yetkili) return NextResponse.json({ ok: false, error: 'forbidden' }, { status: 403 });

  const rawBody = await request.json().catch(() => null);
  const parsed = patchSchema.safeParse(rawBody);
  if (!parsed.success) return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  if (parsed.data.enabled === undefined && parsed.data.rollout_percent === undefined) {
    return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  }

  const update: Record<string, unknown> = { updated_at: new Date().toISOString(), updated_by: user.id };
  if (parsed.data.enabled !== undefined) update.enabled = parsed.data.enabled;
  if (parsed.data.rollout_percent !== undefined) update.rollout_percent = parsed.data.rollout_percent;

  const { error } = await supabaseAny
    .from('runtime_feature_flags')
    .update(update)
    .eq('key', parsed.data.id);

  if (error) return NextResponse.json({ ok: false, error: 'internal_error' }, { status: 500 });
  return NextResponse.json({ ok: true });
}

// Create flag
export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ ok: false, error: 'Forbidden' }, { status: 403 });

  const { data: yetkili } = await supabaseAny.rpc('has_permission_v1', { p_permission: 'page:feature-flags' });
  if (!yetkili) return NextResponse.json({ ok: false, error: 'forbidden' }, { status: 403 });

  const rl = await rateLimit(`feature-flag-create:${user.id}`, 20, 3_600_000);
  if (!rl.ok) return NextResponse.json({ ok: false, error: 'rate_limited' }, { status: 429 });

  // safeParse hiç yoktu — ham gövde (bozuk JSON, eksik rollout_percent →
  // NaN) doğrudan production kill-switch tablosuna yazılabiliyordu.
  const rawBody = await request.json().catch(() => null);
  const parsed = postSchema.safeParse(rawBody);
  if (!parsed.success) return NextResponse.json({ ok: false, error: 'invalid_input' }, { status: 400 });
  const body = parsed.data;

  const { error } = await supabaseAny.from('runtime_feature_flags').insert({
    key: body.key,
    enabled: false,
    rollout_percent: Math.min(100, Math.max(0, body.rollout_percent)),
    allowed_regions: body.region ? [body.region] : [],
    metadata: {
      description: body.description || null,
      environment: body.environment ?? 'staging',
      project: body.project || null,
      type: body.type || null,
      is_draft: body.is_draft ?? false,
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
