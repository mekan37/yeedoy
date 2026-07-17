import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/supabase/server';
import { getRequestIdentity, rateLimit } from '@/src/lib/rate-limit';
import { revalidatePath } from 'next/cache';

export const runtime = 'nodejs';

const bodySchema = z.object({
  business_id: z.string().uuid(),
});

export async function POST(
  request: Request,
  { params }: { params: Promise<{ menuId: string }> },
) {
  const identity = getRequestIdentity({
    ip: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-menu-activate:${identity}`, 20, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const { menuId } = await params;

  const rawBody = await request.json().catch(() => null);
  const parsed = bodySchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const { business_id } = parsed.data;

  const { error } = await supabase.rpc('set_active_menu_v1', {
    p_menu_id: menuId,
    p_business_id: business_id,
  } as any);

  if (error) {
    const status = error.code === 'P0002' ? 403 : error.code === 'P0001' ? 404 : 400;
    return NextResponse.json({ error: error.message }, { status });
  }

  // Revalidate the public menu pages so visitors see the change within seconds
  const { data: biz } = await (supabase as any)
    .from('businesses')
    .select('slug, public_slug')
    .eq('id', business_id)
    .maybeSingle() as { data: { slug: string | null; public_slug: string | null } | null };

  if (biz?.slug) revalidatePath(`/m/${biz.slug}`);
  if (biz?.public_slug && biz.public_slug !== biz.slug) revalidatePath(`/m/${biz.public_slug}`);

  return NextResponse.json({ data: { ok: true } });
}
