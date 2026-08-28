import { randomUUID } from 'node:crypto';
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { canManageBusiness } from '@/src/lib/karekod-erisimi';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';
import { gorselYukle, dosyaUzantisi } from '@/src/lib/medya/yukleme-yardimcisi';

const BUCKET = 'menu-media';
const PHOTO_LIMIT = 10;

const uploadSchema = z.object({
  businessId: z.string().uuid(),
});

const deleteSchema = z.object({
  id: z.string().uuid(),
});

// ── POST: Fotoğraf yükle ─────────────────────────────────────────────────────

export async function POST(req: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(req.headers),
    userAgent: req.headers.get('user-agent'),
  });
  const rl = rateLimit(`owner-photo-upload:${identity}`, 15, 60_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  const formData = await req.formData().catch(() => null);
  if (!formData) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const parsed = uploadSchema.safeParse({ businessId: formData.get('businessId') });
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const canManage = await canManageBusiness(parsed.data.businessId);
  if (!canManage) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  // 10 fotoğraf limiti (rejected olmayanlar)
  const { count: existingCount } = await (supabase as any)
    .from('business_media')
    .select('id', { count: 'exact', head: true })
    .eq('business_id', parsed.data.businessId)
    .neq('status', 'rejected')
    .eq('is_hidden', false) as { count: number | null };

  if ((existingCount ?? 0) >= PHOTO_LIMIT) {
    return NextResponse.json({ error: 'photo_limit_reached' }, { status: 422 });
  }

  const file = formData.get('file');
  const service = createSupabaseServiceClient();
  if (!service) return NextResponse.json({ error: 'service_unavailable' }, { status: 500 });

  const extension = dosyaUzantisi(file instanceof File ? file.type : '');
  const path = `businesses/${parsed.data.businessId}/gallery/${randomUUID()}.${extension}`;

  const uploadResult = await gorselYukle({
    service,
    bucket: BUCKET,
    file,
    path,
    logContext: { businessId: parsed.data.businessId },
  });
  if (!uploadResult.ok) {
    return NextResponse.json({ error: uploadResult.error }, { status: uploadResult.status });
  }
  const url = uploadResult.data.url;

  // DB kaydı: add_business_media_v1 RPC
  const { data: rpcResult } = await (supabase as any).rpc('add_business_media_v1', {
    p_business_id: parsed.data.businessId,
    p_url: url,
    p_url_large: url,
    p_url_thumb: url,
    p_provider: 'supabase_storage',
    p_kind: 'gallery',
  }) as { data: { ok: boolean; error?: string } | null };

  if (!rpcResult?.ok) {
    // Storage'a yüklendi ama DB'ye kaydedilemedi — storage'ı temizle
    await service.storage.from(BUCKET).remove([path]);
    return NextResponse.json({ error: rpcResult?.error ?? 'db_error' }, { status: 422 });
  }

  // Yeni eklenen kaydı geri döndür
  const { data: inserted } = await (supabase as any)
    .from('business_media')
    .select('id, url, url_thumb, status, kind, created_at')
    .eq('business_id', parsed.data.businessId)
    .eq('url', url)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle() as { data: Record<string, unknown> | null };

  return NextResponse.json({ ok: true, photo: inserted, storagePath: path }, { status: 200 });
}

// ── DELETE: Fotoğrafı sil ────────────────────────────────────────────────────

export async function DELETE(req: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(req.headers),
    userAgent: req.headers.get('user-agent'),
  });
  const rl = rateLimit(`owner-photo-delete:${identity}`, 20, 60_000);
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const body = await req.json().catch(() => null);
  const parsed = deleteSchema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  // Fotoğrafın sahibini kontrol et
  const { data: photo } = await (supabase as any)
    .from('business_media')
    .select('id, url, business_id')
    .eq('id', parsed.data.id)
    .maybeSingle() as { data: { id: string; url: string; business_id: string } | null };

  if (!photo) return NextResponse.json({ error: 'not_found' }, { status: 404 });

  const canManage = await canManageBusiness(photo.business_id);
  if (!canManage) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  const service = createSupabaseServiceClient();
  if (!service) return NextResponse.json({ error: 'service_unavailable' }, { status: 500 });

  // DB'den sil
  await service.from('business_media').delete().eq('id', parsed.data.id);

  // Storage'dan sil (best effort — yol URL'den çıkarılır)
  try {
    const marker = `/${BUCKET}/`;
    const idx = photo.url.indexOf(marker);
    if (idx !== -1) {
      const storagePath = photo.url.slice(idx + marker.length);
      await service.storage.from(BUCKET).remove([storagePath]);
    }
  } catch { /* storage temizliği opsiyonel */ }

  return NextResponse.json({ ok: true }, { status: 200 });
}
