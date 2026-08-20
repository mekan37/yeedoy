import { NextResponse } from 'next/server';
import { rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const metricEnum = z.enum(['event_rate_1h', 'rate_limit_events_1h', 'active_users_24h']);
const severityEnum = z.enum(['info', 'warning', 'critical']);

const upsertSchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(1).max(80),
  metric: metricEnum,
  threshold: z.number().int().min(0),
  severity: severityEnum,
  enabled: z.boolean(),
  notifyEmail: z.boolean(),
  notifySlack: z.boolean(),
});
const deleteSchema = z.object({ id: z.string().uuid() });

type SupabaseAny = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }> };

async function guard(sb: SupabaseAny, userId: string): Promise<NextResponse | null> {
  const { data: isAdmin } = await sb.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const rl = rateLimit(`gozlem-uyari:${userId}`, 30, 3_600_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const { data: dbRate } = await sb.rpc('consume_rate_limit_v1', { p_action: 'admin_alert_rule_write', p_daily_limit: 30 });
  if (dbRate && (dbRate as { ok?: boolean }).ok === false) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }
  return null;
}

function mapPgError(error: { message?: string } | null): { status: number; error: string } {
  const msg = error?.message ?? '';
  if (msg.includes('unauthorized')) return { status: 403, error: 'forbidden' };
  if (msg.includes('not_found')) return { status: 404, error: 'not_found' };
  if (msg.includes('validation_error')) return { status: 422, error: msg.replace('validation_error: ', '') };
  return { status: 500, error: 'internal_error' };
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = upsertSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });

  const { data, error } = await sb.rpc('admin_upsert_alert_rule_v1', {
    p_id: parsed.data.id ?? null,
    p_name: parsed.data.name,
    p_metric: parsed.data.metric,
    p_threshold: parsed.data.threshold,
    p_severity: parsed.data.severity,
    p_enabled: parsed.data.enabled,
    p_notify_email: parsed.data.notifyEmail,
    p_notify_slack: parsed.data.notifySlack,
  });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { id: data } }, { status: 200 });
}

export async function DELETE(request: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const guardRes = await guard(sb, user.id);
  if (guardRes) return guardRes;

  const parsed = deleteSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const { error } = await sb.rpc('admin_delete_alert_rule_v1', { p_id: parsed.data.id });
  if (error) {
    const m = mapPgError(error);
    return NextResponse.json({ error: m.error }, { status: m.status });
  }
  return NextResponse.json({ data: { ok: true } }, { status: 200 });
}
