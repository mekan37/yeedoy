import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export const runtime = 'nodejs';

const aiAnalyzeSchema = z
  .object({
    business_id: z.string().uuid(),
    file_url: z.string().url().optional(),
    raw_text: z.string().min(1).max(50_000).optional(),
  })
  .refine((d) => d.file_url !== undefined || d.raw_text !== undefined, {
    message: 'file_url or raw_text is required',
  });

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });

  // 5 requests per hour
  const limit = rateLimit(`owner-ai-analyze:${identity}`, 5, 3_600_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const rawBody = await request.json().catch(() => null);
  if (!rawBody) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const parsed = aiAnalyzeSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  // Verify business ownership
  const { data: business, error: bizError } = await (supabase as any)
    .from('businesses')
    .select('id, owner_id')
    .eq('id', parsed.data.business_id)
    .maybeSingle();

  if (bizError || !business) {
    return NextResponse.json({ error: 'business_not_found' }, { status: 404 });
  }

  if ((business as { owner_id: string }).owner_id !== user.id) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  // Insert menu_ocr_jobs row
  const { data: job, error: jobError } = await (supabase as any)
    .from('menu_ocr_jobs')
    .insert({
      business_id: parsed.data.business_id,
      owner_id: user.id,
      file_url: parsed.data.file_url ?? null,
      raw_text: parsed.data.raw_text ?? null,
      status: 'pending',
    })
    .select('id')
    .single();

  if (jobError || !job) {
    logger.warn('Failed to insert menu_ocr_jobs', {
      userId: user.id,
      businessId: parsed.data.business_id,
      error: (jobError as { message?: string } | null)?.message,
    });
    return NextResponse.json({ error: 'job_creation_failed' }, { status: 500 });
  }

  const jobId = (job as { id: string }).id;

  // Get session token for edge function auth
  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session?.access_token) {
    return NextResponse.json({ error: 'session_expired' }, { status: 401 });
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  if (!supabaseUrl) {
    logger.warn('NEXT_PUBLIC_SUPABASE_URL not configured');
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  // Call edge function
  let edgeStatus: number;
  let edgeData: Record<string, unknown>;

  try {
    const res = await fetch(`${supabaseUrl}/functions/v1/ai-menu-analyze`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ job_id: jobId }),
      signal: AbortSignal.timeout(140_000),
    });
    edgeStatus = res.status;
    edgeData = (await res.json()) as Record<string, unknown>;
  } catch {
    logger.warn('Edge function call failed (timeout or network)', { jobId });
    return NextResponse.json({ error: 'analysis_timeout' }, { status: 500 });
  }

  if (edgeStatus === 200 && edgeData.ok === true) {
    const itemCount =
      typeof edgeData.item_count === 'number' ? edgeData.item_count : 0;
    return NextResponse.json({ data: { job_id: jobId, item_count: itemCount } });
  }

  const errCode = String(edgeData.error ?? '');
  logger.warn('Edge function returned non-200', { jobId, edgeStatus, errCode });

  if (edgeStatus === 409 && errCode === 'already_processing') {
    return NextResponse.json({ error: 'already_processing' }, { status: 409 });
  }
  if (edgeStatus === 409 && errCode === 'already_completed') {
    return NextResponse.json({ error: 'already_completed' }, { status: 409 });
  }
  if (edgeStatus === 422) {
    return NextResponse.json(
      { error: errCode || 'unprocessable' },
      { status: 422 },
    );
  }

  return NextResponse.json({ error: 'analysis_failed' }, { status: 500 });
}
