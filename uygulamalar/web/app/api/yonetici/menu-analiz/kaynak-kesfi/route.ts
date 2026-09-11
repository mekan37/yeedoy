import { NextResponse } from 'next/server';
import { z } from 'zod';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';
import { menuExtractorStartSourceDiscoveryJob } from '@/src/lib/menu-analiz/disari-cagri';
import { getClientIp, getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';

export const runtime = 'nodejs';

export const sourceDiscoveryRequestSchema = z.object({
  business_id: z.string().uuid(),
  website_url: z.string().trim().url().max(2048),
}).strict();

type SbRpc = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

function mapCreateJobError(message: string | undefined): { status: number; error: string } {
  if (message?.includes('not_found')) return { status: 404, error: 'not_found' };
  if (message?.includes('validation_error')) return { status: 400, error: 'invalid_payload' };
  if (message?.includes('unauthorized')) return { status: 403, error: 'forbidden' };
  return { status: 500, error: 'internal_error' };
}

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = await rateLimit(`menu-kaynak-kesfi:${identity}`, 10, 60_000);
  if (!limit.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return NextResponse.json({ error: guard.status === 401 ? 'unauthorized' : 'forbidden' }, { status: guard.status });
  }

  const parsed = sourceDiscoveryRequestSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });
  }

  const started = await menuExtractorStartSourceDiscoveryJob(parsed.data.website_url);
  if (!started.ok) {
    const error = started.code === 'AUTH_ERROR' ? 'auth_error' : started.code === 'JOB_FAILED' ? 'job_failed' : 'extractor_unavailable';
    return NextResponse.json({ error }, { status: started.code === 'AUTH_ERROR' ? 502 : 503 });
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;
  const { data: jobId, error } = await sb.rpc('admin_create_menu_extract_job_v1', {
    p_business_id: parsed.data.business_id,
    p_source_type: 'website_discovery',
    p_external_job_id: started.jobId,
    p_source_url: parsed.data.website_url,
    p_source_file_name: null,
  });
  if (error || !jobId) {
    logger.error('menu-analiz/kaynak-kesfi: job kayıt RPC hatası', { error, businessId: parsed.data.business_id });
    const mapped = mapCreateJobError((error as { message?: string } | null)?.message);
    return NextResponse.json({ error: mapped.error }, { status: mapped.status });
  }

  return NextResponse.json({ data: { job_id: jobId } }, { status: 201 });
}
