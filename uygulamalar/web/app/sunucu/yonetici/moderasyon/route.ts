import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import { logAudit, AUDIT } from '@/src/lib/denetim';

export const runtime = 'nodejs';

const moderationSchema = z.object({
  action: z.enum(['approve', 'reject', 'suspend']),
  target_type: z.string().min(1).max(100),
  target_id: z.string().uuid(),
  reason: z.string().max(1000).optional(),
});

// Maps target_type to the table name and status column
const TARGET_TABLE_MAP: Record<string, { table: string; statusColumn: string }> = {
  business: { table: 'businesses', statusColumn: 'is_active' },
  menu: { table: 'menus', statusColumn: 'status' },
  business_media: { table: 'business_media', statusColumn: 'status' },
};

// Maps action to the value written per target_type
function resolveStatusValue(
  action: 'approve' | 'reject' | 'suspend',
  targetType: string,
): unknown {
  if (targetType === 'business') {
    if (action === 'approve') return true;
    if (action === 'reject') return false;
    if (action === 'suspend') return false;
  }
  if (targetType === 'menu') {
    if (action === 'approve') return 'published';
    if (action === 'reject') return 'archived';
    if (action === 'suspend') return 'archived';
  }
  if (targetType === 'business_media') {
    if (action === 'approve') return 'approved';
    if (action === 'reject') return 'rejected';
    if (action === 'suspend') return 'rejected';
  }
  // Generic fallback for unknown target types
  if (action === 'approve') return 'approved';
  if (action === 'reject') return 'rejected';
  return 'suspended';
}

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`admin-moderation:${identity}`, 30, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = moderationSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { action, target_type, target_id, reason } = parsed.data;
  const tableConfig = TARGET_TABLE_MAP[target_type];

  const serviceClient = createSupabaseServiceClient();
  if (!serviceClient) {
    logger.warn('Admin moderation: no service client available');
    return NextResponse.json({ error: 'service_unavailable' }, { status: 503 });
  }

  const statusValue = resolveStatusValue(action, target_type);

  if (tableConfig) {
    const serviceClientAny = serviceClient as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
    const { error } = await serviceClientAny
      .from(tableConfig.table)
      .update({ [tableConfig.statusColumn]: statusValue })
      .eq('id', target_id);

    if (error) {
      logger.warn('Admin moderation update failed', {
        action,
        target_type,
        target_id,
        error: error.message,
      });
      return NextResponse.json({ error: 'update_failed' }, { status: 500 });
    }
  }

  logAudit({
    supabase: serviceClient as any,
    userId: user.id,
    action: AUDIT.MODERATION_ACTION,
    resourceType: target_type,
    resourceId: target_id,
    metadata: { moderation_action: action, reason: reason ?? null },
    request,
  });

  return NextResponse.json({ data: { action, target_type, target_id, status: statusValue } });
}
