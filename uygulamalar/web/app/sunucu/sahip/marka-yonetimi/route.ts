import { randomUUID } from 'node:crypto';
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { getRequestIdentity, rateLimit } from '@/src/lib/oran-siniri';

const BUCKET   = 'menu-media';
const MAX_BYTES = 8 * 1024 * 1024;
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

const uploadSchema = z.object({
  businessId: z.string().uuid(),
  type: z.enum(['logo', 'cover']),
});

export async function POST(req: Request) {
  const identity = getRequestIdentity({
    ip: req.headers.get('x-forwarded-for'),
    userAgent: req.headers.get('user-agent'),
  });
  const rl = rateLimit(`owner-branding:${identity}`, 10, 60_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const supabase = await createSupabaseServerClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const formData = await req.formData().catch(() => null);
  if (!formData) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const parsed = uploadSchema.safeParse({
    businessId: formData.get('businessId'),
    type: formData.get('type'),
  });
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const permissionResult = await (supabase as unknown as {
    rpc: (
      fn: 'has_business_permission_v1',
      args: { p_business_id: string; p_permission: 'business_write' },
    ) => Promise<{ data: unknown; error: unknown }>;
  }).rpc('has_business_permission_v1', {
    p_business_id: parsed.data.businessId,
    p_permission: 'business_write',
  });
  if (permissionResult.error || permissionResult.data !== true) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const file = formData.get('file');
  if (!(file instanceof File)) return NextResponse.json({ error: 'file_required' }, { status: 400 });
  if (!ALLOWED_MIME.has(file.type)) return NextResponse.json({ error: 'invalid_mime_type' }, { status: 400 });
  if (file.size > MAX_BYTES) return NextResponse.json({ error: 'file_too_large' }, { status: 413 });

  const service = createSupabaseServiceClient();
  if (!service) return NextResponse.json({ error: 'service_unavailable' }, { status: 500 });

  const ext = file.type === 'image/webp' ? 'webp' : file.type === 'image/png' ? 'png' : 'jpg';
  // Sabit yol: her yüklemede üzerine yazar (upsert: true)
  const fixedPath  = `businesses/${parsed.data.businessId}/branding/${parsed.data.type}.${ext}`;
  // Yedek yol: cache buster için UUID (CDN önbellek sorunu yaşanırsa fallback)
  const uniquePath = `businesses/${parsed.data.businessId}/branding/${parsed.data.type}_${randomUUID().slice(0, 8)}.${ext}`;

  // Önce sabit yola upsert dene
  const { error: storageErr } = await service.storage
    .from(BUCKET)
    .upload(fixedPath, file, { contentType: file.type, cacheControl: '3600', upsert: true });

  const storagePath = storageErr ? uniquePath : fixedPath;

  if (storageErr) {
    // Sabit yol başarısız olduysa unique yola yükle
    const { error: err2 } = await service.storage
      .from(BUCKET)
      .upload(uniquePath, file, { contentType: file.type, cacheControl: '3600', upsert: false });
    if (err2) return NextResponse.json({ error: 'upload_failed' }, { status: 500 });
  }

  const { data: publicData } = service.storage.from(BUCKET).getPublicUrl(storagePath);
  const url = publicData.publicUrl;

  // DB güncelle
  const column = parsed.data.type === 'logo' ? 'logo_url' : 'cover_url';
  const { error: dbErr } = await (service as any)
    .from('businesses')
    .update({ [column]: url })
    .eq('id', parsed.data.businessId) as { error: { message: string } | null };

  if (dbErr) {
    await service.storage.from(BUCKET).remove([storagePath]);
    return NextResponse.json({ error: 'db_error' }, { status: 500 });
  }

  return NextResponse.json({ ok: true, url }, { status: 200 });
}
