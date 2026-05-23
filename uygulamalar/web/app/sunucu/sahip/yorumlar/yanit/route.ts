import { z } from 'zod';
import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

const schema = z.object({
  reviewId: z.string().uuid(),
  reply: z.string().min(1).max(2000).transform((s) => s.trim()),
});

const deleteSchema = z.object({
  reviewId: z.string().uuid(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-review-reply:${identity}`, 20, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const body = await request.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const review = await getOwnedReview(supabase as any, user.id, parsed.data.reviewId);
  if (!review) {
    return NextResponse.json({ error: 'review_not_found' }, { status: 404 });
  }

  const repliedAt = new Date().toISOString();
  const { error } = await (supabase as any)
    .from('reviews')
    .update({
      owner_reply: parsed.data.reply,
      owner_replied_at: repliedAt,
    })
    .eq('id', parsed.data.reviewId);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true, repliedAt });
}

export async function DELETE(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-review-reply-delete:${identity}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const body = await request.json().catch(() => null);
  const parsed = deleteSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const review = await getOwnedReview(supabase as any, user.id, parsed.data.reviewId);
  if (!review) {
    return NextResponse.json({ error: 'review_not_found' }, { status: 404 });
  }

  const { error } = await (supabase as any)
    .from('reviews')
    .update({ owner_reply: null, owner_replied_at: null })
    .eq('id', parsed.data.reviewId);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}

async function getOwnedReview(
  supabase: any,
  userId: string,
  reviewId: string,
): Promise<{ id: string; business_id: string } | null> {
  const { data: review, error } = await supabase
    .from('reviews')
    .select('id, business_id')
    .eq('id', reviewId)
    .maybeSingle();

  if (error || !review?.business_id) return null;

  const canManageBusiness = await hasOwnerBusiness(supabase, userId, review.business_id);
  return canManageBusiness ? review : null;
}
