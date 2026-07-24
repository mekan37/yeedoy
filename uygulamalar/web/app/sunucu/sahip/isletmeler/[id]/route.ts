import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';

export const runtime = 'nodejs';

const updateBusinessSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).optional(),
  city: z.string().max(100).optional(),
  district: z.string().max(100).optional(),
  neighborhood: z.string().max(120).optional(),
  address: z.string().max(500).optional(),
  category: z.string().max(100).optional(),
  phone: z.string().max(30).optional(),
  lat: z.number().min(-90).max(90).nullable().optional(),
  lng: z.number().min(-180).max(180).nullable().optional(),
  logo_url: z.string().url().max(1000).nullable().optional(),
  cover_url: z.string().url().max(1000).nullable().optional(),
  reservation_url: z.string().url().max(1000).nullable().optional(),
  order_yemeksepeti_url: z.string().url().max(1000).nullable().optional(),
  order_trendyolgo_url: z.string().url().max(1000).nullable().optional(),
  order_getir_url: z.string().url().max(1000).nullable().optional(),
});

type RouteContext = { params: Promise<{ id: string }> };

export async function PATCH(request: Request, context: RouteContext) {
  const { id } = await context.params;

  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`owner-business-patch:${identity}`, 20, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const supabase = await createSupabaseServerClient();
  const supabaseAny = supabase as unknown as { from: (t: string) => any; rpc: (fn: string, args?: any) => any; storage: any; auth: any };
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

  const canManageBusiness = await hasOwnerBusiness(supabaseAny, user.id, id);
  if (!canManageBusiness) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const { data: updated, error } = await supabaseAny
    .from('businesses')
    .update(parsed.data)
    .eq('id', id)
    .select('id, name, description, city, district, neighborhood, address, lat, lng, category, phone, is_active, logo_url, cover_url')
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
