import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { rateLimit, getRequestIdentity } from '@/src/lib/rate-limit';

const submitSchema = z.object({
  reviewId: z.string().uuid(),
  content:  z.string().min(10).max(2000).trim(),
});

const deleteSchema = z.object({
  reviewId: z.string().uuid(),
});

export async function POST(req: Request) {
  const identity = getRequestIdentity({ ip: req.headers.get('x-forwarded-for'), userAgent: req.headers.get('user-agent') });
  const rl = rateLimit(`review-reply:post:${identity}`, 10, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const body = await req.json().catch(() => null);
  const parsed = submitSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data, error } = await (supabase as any).rpc('submit_review_reply', {
    p_review_id: parsed.data.reviewId,
    p_content:   parsed.data.content,
  }) as { data: { ok: boolean; error?: string; reply_id?: string } | null; error: unknown };

  if (error || !data?.ok) {
    const msg = data?.error ?? 'rpc_error';
    const status = msg === 'not_authorized' ? 403 : msg === 'review_not_found' ? 404 : 400;
    return NextResponse.json({ error: msg }, { status });
  }

  return NextResponse.json({ reply_id: data.reply_id }, { status: 200 });
}

export async function DELETE(req: Request) {
  const identity = getRequestIdentity({ ip: req.headers.get('x-forwarded-for'), userAgent: req.headers.get('user-agent') });
  const rl = rateLimit(`review-reply:delete:${identity}`, 10, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const body = await req.json().catch(() => null);
  const parsed = deleteSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const { data, error } = await (supabase as any).rpc('delete_review_reply', {
    p_review_id: parsed.data.reviewId,
  }) as { data: { ok: boolean; error?: string } | null; error: unknown };

  if (error || !data?.ok) {
    const msg = data?.error ?? 'rpc_error';
    const status = msg === 'not_found' ? 404 : msg === 'not_authorized' ? 403 : 400;
    return NextResponse.json({ error: msg }, { status });
  }

  return NextResponse.json({ ok: true }, { status: 200 });
}
