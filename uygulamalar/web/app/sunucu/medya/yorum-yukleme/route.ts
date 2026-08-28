import { randomUUID } from 'node:crypto';
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { gorselYukle, dosyaUzantisi } from '@/src/lib/medya/yukleme-yardimcisi';

const uploadSchema = z.object({
  businessId: z.string().uuid(),
});

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`review-photo-upload:${identity}`, 15, 60_000);
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

  const formData = await request.formData().catch(() => null);
  if (!formData) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const parsed = uploadSchema.safeParse({
    businessId: formData.get('businessId'),
  });
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const file = formData.get('file');
  const service = createSupabaseServiceClient();
  if (!service) {
    return NextResponse.json({ error: 'service_role_required' }, { status: 500 });
  }

  const extension = dosyaUzantisi(file instanceof File ? file.type : '');
  const path = `businesses/${parsed.data.businessId}/review-photos/${user.id}/${randomUUID()}.${extension}`;

  const result = await gorselYukle({
    service,
    bucket: 'menu-media',
    file,
    path,
    logContext: { businessId: parsed.data.businessId },
  });

  if (!result.ok) {
    return NextResponse.json({ error: result.error }, { status: result.status });
  }
  return NextResponse.json({ ok: true, data: result.data });
}
