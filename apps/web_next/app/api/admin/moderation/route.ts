import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { createSupabaseServiceClient } from '@/src/lib/supabase/service';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export const runtime = 'nodejs';

const ADMIN_ROLES = ['super_admin', 'admin', 'community_mod'] as const;

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
    ip: request.headers.get('x-forwarded-for'),
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

  // Check admin role
  const { data: profile, error: profileError } = await (supabase as any)
    .from('user_profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError || !profile) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  if (!ADMIN_ROLES.includes(profile.role)) {
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
    const { error } = await (serviceClient as any)
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

  // Log the moderation action to a moderation_logs table if available, silently ignore errors
  await (serviceClient as any)
    .from('moderation_logs')
    .insert({
      admin_id: user.id,
      action,
      target_type,
      target_id,
      reason: reason ?? null,
    })
    .then(() => null)
    .catch(() => null);

  return NextResponse.json({ data: { action, target_type, target_id, status: statusValue } });
}
