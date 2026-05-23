import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { logger } from '@/src/lib/logger';

export const runtime = 'nodejs';

const updateBusinessSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).optional(),
  city: z.string().max(100).optional(),
  category: z.string().max(100).optional(),
  phone: z.string().max(30).optional(),
  website: z.string().url().max(500).optional(),
});

type RouteContext = { params: Promise<{ id: string }> };

export async function PATCH(request: Request, context: RouteContext) {
  const { id } = await context.params;

  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-business-patch:${identity}`, 20, 60_000);
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

  const rawBody = await request.json().catch(() => null);
  const parsed = updateBusinessSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  if (Object.keys(parsed.data).length === 0) {
    return NextResponse.json({ error: 'no_fields_to_update' }, { status: 400 });
  }

  // Verify ownership before applying update
  const { data: business, error: bizError } = await (supabase as any)
    .from('businesses')
    .select('id, owner_id')
    .eq('id', id)
    .maybeSingle();

  if (bizError || !business) {
    return NextResponse.json({ error: 'business_not_found' }, { status: 404 });
  }

  if ((business as { owner_id: string }).owner_id !== user.id) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const { data: updated, error } = await (supabase as any)
    .from('businesses')
    .update(parsed.data)
    .eq('id', id)
    .select('id, name, description, city, category, phone, is_active')
    .single();

  if (error) {
    logger.warn('Owner business update failed', {
      businessId: id,
      error: (error as { message: string }).message,
    });
    return NextResponse.json({ error: 'update_failed' }, { status: 500 });
  }

  return NextResponse.json({ data: updated });
}
