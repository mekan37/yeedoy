import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';
import { getSegmentTokens } from '@/src/lib/push/get-segment-tokens';
import { sendFcmBatch } from '@/src/lib/push/fcm-client';

const schema = z.object({
  businessId: z.string().uuid(),
  title: z.string().min(1).max(80),
  body: z.string().min(1).max(200),
  segment: z.enum(['all_followers', 'loyal_top20', 'inactive_30d', 'new_30d']),
  scheduledAt: z.string().nullable().optional(),
});

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: isAdmin } = await supabaseAny.rpc('is_admin');
  if (!isAdmin) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { businessId, title, body, segment, scheduledAt } = parsed.data;

  // Count target users for the segment
  const { data: estimate } = await supabaseAny
    .rpc('estimate_campaign_segment_v1', { p_business_id: businessId, p_segment: segment });

  const { error } = await supabaseAny
    .from('push_campaigns')
    .insert({
      business_id: businessId,
      title,
      body,
      target_segment: segment,
      sent_count: estimate ?? 0,
      sent_at: scheduledAt ? null : new Date().toISOString(),
      scheduled_at: scheduledAt ?? null,
      created_by: user.id,
    });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  // Attempt FCM delivery (fail-safe: returns provider_not_configured if secrets missing)
  const tokens = await getSegmentTokens(businessId, segment);
  const fcmResult = await sendFcmBatch(tokens, { title, body });

  // Update sent_count with actual delivery result when FCM is active
  if (!fcmResult.provider_not_configured && fcmResult.success_count > 0) {
    await supabaseAny
      .from('push_campaigns')
      .update({ sent_count: fcmResult.success_count, sent_at: new Date().toISOString() })
      .eq('business_id', businessId)
      .eq('title', title)
      .order('created_at', { ascending: false })
      .limit(1);
  }

  return NextResponse.json({
    ok: true,
    sentCount: fcmResult.provider_not_configured ? (estimate ?? 0) : fcmResult.success_count,
    providerNotConfigured: fcmResult.provider_not_configured ?? false,
  });
}
