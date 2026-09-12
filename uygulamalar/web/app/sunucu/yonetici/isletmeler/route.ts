import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import type { TablesInsert } from '@/src/lib/taban/veri-tanimlari';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import { logAudit, AUDIT } from '@/src/lib/denetim';

export const runtime = 'nodejs';


const CreateBusinessSchema = z.object({
  name: z.string().min(2).max(200),
  category: z.string().min(1),
  city: z.string().min(1),
  district: z.string().optional(),
  address: z.string().optional(),
  phone: z.string().optional(),
  website: z
    .string()
    .url()
    .optional()
    .or(z.literal(''))
    .transform((v) => (v === '' ? undefined : v)),
  description: z.string().optional(),
  lat: z.number().optional(),
  lng: z.number().optional(),
  price_level: z.enum(['budget', 'mid', 'premium']).optional(),
  is_active: z.boolean().default(true),
});

async function assertAdmin(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { ok: false as const, status: 401, identity };
  }

  // 'user_profiles' tablosunda 'role' kolonu yok — admin kontrolü diğer
  // yonetici route'larıyla tutarlı şekilde is_admin() RPC'si üzerinden yapılıyor.
  const { data: isAdmin } = await (supabase).rpc('is_admin');

  if (!isAdmin) {
    return { ok: false as const, status: 403, identity };
  }

  return { ok: true as const, userId: user.id, identity };
}

// POST — yeni işletme oluştur
export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });

  const rl = await rateLimit(`admin-business-create:${identity}`, 20, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const guard = await assertAdmin(request);
  if (!guard.ok) {
    return NextResponse.json(
      { error: guard.status === 401 ? 'unauthorized' : 'forbidden' },
      { status: guard.status },
    );
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = CreateBusinessSchema.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors },
      { status: 400 },
    );
  }

  const serviceClient = createSupabaseServiceClient();
  if (!serviceClient) {
    logger.warn('Admin business create: no service client available');
    return NextResponse.json({ error: 'service_unavailable' }, { status: 503 });
  }

  const {
    name,
    category,
    city,
    district,
    address,
    phone,
    website,
    description,
    lat,
    lng,
    price_level,
    is_active,
  } = parsed.data;

  // slug oluştur — name'i normalize et
  const slugBase = name
    .toLowerCase()
    .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
    .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  const slug = `${slugBase}-${Date.now().toString(36)}`;

  const insertRow: TablesInsert<'businesses'> = {
    name,
    category,
    city,
    district: district ?? null,
    address: address ?? null,
    phone: phone ?? null,
    description: description ?? null,
    lat: lat ?? null,
    lng: lng ?? null,
    price_level: price_level ?? null,
    is_active,
    slug,
    source: 'admin',
  };

  if (lat != null && lng != null) {
    // geography point — PostGIS WKT format
    insertRow.geog = `SRID=4326;POINT(${lng} ${lat})`;
  }

  if (website) {
    insertRow.reservation_url = website;
  }

  const { data: created, error: insertError } = await (serviceClient)
    .from('businesses')
    .insert(insertRow)
    .select('id, name, slug')
    .single();

  if (insertError) {
    logger.warn('Admin business create failed', { error: insertError.message });
    return NextResponse.json({ error: 'create_failed' }, { status: 500 });
  }

  logAudit({
    supabase: serviceClient,
    userId: guard.userId,
    action: AUDIT.BUSINESS_CREATE,
    resourceType: 'business',
    resourceId: created.id,
    newData: { name, category, city, is_active },
    request,
  });

  return NextResponse.json({ data: { id: created.id, name: created.name, slug: created.slug } }, { status: 201 });
}
