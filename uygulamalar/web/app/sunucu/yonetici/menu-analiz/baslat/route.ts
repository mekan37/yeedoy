// "Menü Analiz Et" — dosya yükleme ile job başlatma. URL ile başlatma
// (app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-islemleri.ts içindeki
// menuAnalizBaslatUrl) küçük bir JSON gövdesi olduğu için Server Action olarak
// kalabiliyor; dosya yükleme burada route.ts olarak ayrı tutuluyor çünkü
// Server Action'ların varsayılan body-size limiti (~1MB) 30MB'a kadar dosya
// kabul etmemiz gereken bu akış için yetersiz — route.ts bu kısıtı taşımıyor
// (bkz. app/sunucu/makbuz-ocr/route.ts, aynı desenin başka bir örneği).

import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { logger } from '@/src/lib/kayitci';
import { menuExtractorStartUploadJob, MENU_EXTRACTOR_MAX_UPLOAD_BYTES } from '@/src/lib/menu-analiz/disari-cagri';

export const runtime = 'nodejs';

const BusinessIdSchema = z.string().uuid();

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
  const limit = await rateLimit(`menu-analiz-baslat:${identity}`, 10, 60_000);
  if (!limit.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  const guard = await checkAdminAccess();
  if (!guard.authorized) {
    return NextResponse.json({ error: guard.status === 401 ? 'unauthorized' : 'forbidden' }, { status: guard.status });
  }

  const supabase = await createSupabaseServerClient();
  const { data: yetkili } = await supabase.rpc('has_permission_v1', { p_permission: 'page:isletmeler' });
  if (!yetkili) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const formData = await request.formData().catch(() => null);
  if (!formData) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const rawBusinessId = formData.get('business_id');
  const parsedBusinessId = typeof rawBusinessId === 'string' ? BusinessIdSchema.safeParse(rawBusinessId) : null;
  if (!parsedBusinessId?.success) {
    return NextResponse.json({ error: 'invalid_payload', issues: { business_id: ['Geçersiz işletme ID'] } }, { status: 400 });
  }

  const file = formData.get('file');
  if (!(file instanceof Blob)) {
    return NextResponse.json({ error: 'invalid_payload', issues: { file: ['Dosya bulunamadı'] } }, { status: 400 });
  }
  if (file.size > MENU_EXTRACTOR_MAX_UPLOAD_BYTES) {
    return NextResponse.json({ error: 'size_limit' }, { status: 413 });
  }
  const mime = file.type;
  if (!(mime === 'application/pdf' || mime.startsWith('image/'))) {
    return NextResponse.json({ error: 'invalid_payload', issues: { file: ['Sadece PDF veya görsel dosyalar kabul edilir'] } }, { status: 400 });
  }

  const businessId = parsedBusinessId.data;
  const fileName = file instanceof File && file.name ? file.name : 'menu-upload';

  // DB kaydı dış çağrıdan ÖNCE oluşturuluyor — eskiden dış extractor job'ı
  // önce başlatılıyor, DB insert'i sonra yapılıyordu; DB adımı başarısız
  // olduğunda dış iş hiçbir yerde iz bırakmadan (orphan) kalıyordu.
  const { data: jobId, error: createError } = await supabase.rpc('admin_create_menu_extract_job_v1', {
    p_business_id: businessId,
    p_source_type: 'upload',
    p_external_job_id: '',
    p_source_url: undefined,
    p_source_file_name: fileName,
  });
  if (createError || !jobId) {
    logger.error('menu-analiz/baslat: job kayıt RPC hatası', { error: createError, businessId });
    const mapped = mapCreateJobError((createError as { message?: string } | null)?.message);
    return NextResponse.json({ error: mapped.error }, { status: mapped.status });
  }

  const started = await menuExtractorStartUploadJob(file, fileName);
  if (!started.ok) {
    await supabase.rpc('admin_fail_menu_extract_job_v1', { p_job_id: jobId, p_error_message: started.error });
    return NextResponse.json({ error: started.error }, { status: 502 });
  }

  await supabase.rpc('admin_set_menu_extract_job_external_id_v1', { p_job_id: jobId, p_external_job_id: started.jobId });

  return NextResponse.json({ data: { job_id: jobId } }, { status: 201 });
}
