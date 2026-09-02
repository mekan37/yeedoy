import { randomUUID } from 'node:crypto';
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { gorselYukle, dosyaUzantisi } from '@/src/lib/medya/yukleme-yardimcisi';

const uploadSchema = z.object({
  businessId: z.string().uuid(),
  kind: z.enum(['logo', 'kapak']),
});

// Admin panelindeki işletme düzenleme modalı için logo/kapak görseli yükler.
// menu-media bucket'ı bu projedeki tek PUBLIC bucket olduğu için kullanılıyor
// (claim-evidence, menu-media-private, temp public değil) — işletme logosu/kapağı
// herkese açık sitede görüntülenebilmeli.
export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`media-upload-business:${identity}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return NextResponse.json({ error: 'unauthorized' }, { status: guard.status });
  }

  const formData = await request.formData().catch(() => null);
  if (!formData) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const parsed = uploadSchema.safeParse({
    businessId: formData.get('businessId'),
    kind: formData.get('kind'),
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
  const path = `isletmeler/${parsed.data.businessId}/${parsed.data.kind}-${randomUUID()}.${extension}`;

  const result = await gorselYukle({
    service,
    bucket: 'menu-media',
    file,
    path,
    logContext: { businessId: parsed.data.businessId, kind: parsed.data.kind },
  });

  if (!result.ok) {
    return NextResponse.json({ error: result.error }, { status: result.status });
  }
  return NextResponse.json({ ok: true, data: result.data });
}
