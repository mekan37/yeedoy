import { randomUUID } from 'node:crypto';
import { NextResponse } from 'next/server';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { gorselYukle, dosyaUzantisi } from '@/src/lib/medya/yukleme-yardimcisi';

// İşletme öner formu (submit_business_suggestion_v1 RPC) anon + authenticated
// herkese açık — henüz var olmayan bir işletme için gönderildiği için
// businessId/sahiplik kontrolü yapılamaz. Bu yüzden ayrı, kimliksiz ama
// sıkı rate-limitli bir route.
export async function POST(request: Request) {
  // Yalnızca IP ile anahtarla — User-Agent istemci kontrolünde, ekleyince
  // tek bir istekte 1 karakter değiştirmek yeni bir rate-limit kovası açar.
  const ip = getClientIp(request.headers) ?? 'unknown-ip';
  const limit = await rateLimit(`oneri-foto-upload:${ip}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const formData = await request.formData().catch(() => null);
  if (!formData) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const file = formData.get('file');
  const service = createSupabaseServiceClient();
  if (!service) {
    return NextResponse.json({ error: 'service_role_required' }, { status: 500 });
  }

  const extension = dosyaUzantisi(file instanceof File ? file.type : '');
  const path = `business-suggestions/${randomUUID()}/${randomUUID()}.${extension}`;

  const result = await gorselYukle({ service, bucket: 'menu-media', file, path });

  if (!result.ok) {
    return NextResponse.json({ error: result.error }, { status: result.status });
  }
  return NextResponse.json({ ok: true, data: result.data });
}
