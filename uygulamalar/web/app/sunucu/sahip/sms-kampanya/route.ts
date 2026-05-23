import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { z } from 'zod';

const schema = z.object({
  bizIds: z.array(z.string().uuid()).min(1),
  segment: z.enum(['followers', 'loyalty', 'all']),
  message: z.string().min(1).max(480),
  scheduledAt: z.string().nullable().optional(),
});

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const parsed = schema.safeParse(await req.json());
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { bizIds, segment, message, scheduledAt } = parsed.data;

  // Count recipients
  let sentCount = 0;
  if (segment === 'followers' || segment === 'all') {
    const { count } = await (supabase as any)
      .from('business_follows')
      .select('id', { count: 'exact', head: true })
      .in('business_id', bizIds);
    sentCount = count ?? 0;
  }
  if (segment === 'loyalty') {
    const { count } = await (supabase as any)
      .from('loyalty_cards')
      .select('id', { count: 'exact', head: true })
      .in('business_id', bizIds);
    sentCount = count ?? 0;
  }

  // Insert campaign record
  const { error } = await (supabase as any)
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

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // TODO: integrate with Netgsm/Twilio for actual delivery
  return NextResponse.json({ ok: true, sentCount });
}
