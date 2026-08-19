import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';

const reportSchema = z.object({
  targetType: z.enum(['business', 'review', 'menu_item_photo']),
  targetId: z.string().uuid(),
  reason: z.string().min(1).max(100),
  details: z.string().max(500).optional(),
});

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const limit = rateLimit(`rapor-et:${user.id}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = reportSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { targetType, targetId, reason, details } = parsed.data;

  const insertRow: Record<string, unknown> = {
    reporter_user_id: user.id,
    target_type: targetType,
    target_id: targetId,
    reason,
    details: details?.trim() || null,
  };
  if (targetType === 'business') insertRow.business_id = targetId;
  if (targetType === 'review') insertRow.review_id = targetId;
  if (targetType === 'menu_item_photo') insertRow.menu_item_photo_id = targetId;

  const { error } = await (supabase as any).from('reports').insert(insertRow);

  if (error) {
    logger.warn('Rapor eklenemedi', { targetType, targetId, error: error.message });
    return NextResponse.json({ error: 'insert_failed' }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
