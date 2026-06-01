import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { z } from 'zod';

const schema = z.object({
  bizIds: z.array(z.string().uuid()).min(1),
  segment: z.enum(['followers', 'loyalty', 'all']),
  message: z.string().min(1).max(480),
  scheduledAt: z.string().nullable().optional(),
});

export async function POST(req: Request) {
  const identity = getRequestIdentity({
    ip: req.headers.get('x-forwarded-for'),
    userAgent: req.headers.get('user-agent'),
  });

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  // 3 SMS campaigns per user per hour
  const limit = rateLimit(`sms-kampanya:${user.id}:${identity}`, 3, 3_600_000);
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { bizIds, segment, message, scheduledAt } = parsed.data;

  // Verify ownership of the target business
  const owned = await hasOwnerBusiness(supabase as any, user.id, bizIds[0]); // supabase as any needed for helper signature
  if (!owned) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });

  // business_follows / loyalty_cards / sms_campaigns are not in Database types yet
  const supabaseAny = supabase as unknown as { from: (t: string) => any };

  // Count recipients
  let sentCount = 0;
  if (segment === 'followers' || segment === 'all') {
    const { count } = await supabaseAny
      .from('business_follows')
      .select('id', { count: 'exact', head: true })
      .in('business_id', bizIds);
    sentCount = count ?? 0;
  }
  if (segment === 'loyalty') {
    const { count } = await supabaseAny
      .from('loyalty_cards')
      .select('id', { count: 'exact', head: true })
      .in('business_id', bizIds);
    sentCount = count ?? 0;
  }

  // Insert campaign record
  const { error } = await supabaseAny
    .from('sms_campaigns')
    .insert({
      business_id: bizIds[0],
      message,
      segment,
      sent_count: sentCount,
      status: scheduledAt ? 'scheduled' : 'queued',
      scheduled_at: scheduledAt ?? null,
      created_by: user.id,
    });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  // TODO: integrate with Netgsm/Twilio for actual delivery
  return NextResponse.json({ ok: true, sentCount });
}
