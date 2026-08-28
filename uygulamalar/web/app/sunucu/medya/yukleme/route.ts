import { randomUUID } from 'node:crypto';
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/src/lib/taban/sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { logger } from '@/src/lib/kayitci';
import { getRequestIdentity, rateLimit, getClientIp } from '@/src/lib/oran-siniri';

export const uploadSchema = z.object({
  businessId: z.string().uuid(),
  type: z.enum(['logo', 'cover', 'background', 'item', 'campaign']),
});

const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
const maxBytes = 5 * 1024 * 1024;

export async function POST(request: Request) {
  const identity = getRequestIdentity({
    ip: getClientIp(request.headers),
    userAgent: request.headers.get('user-agent'),
  });
  const limit = rateLimit(`media-upload:${identity}`, 10, 60_000);
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
    type: formData.get('type'),
  });
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 });
  }

  const canManage = await hasOwnerBusiness(supabase as any, user.id, parsed.data.businessId);
  if (!canManage) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const file = formData.get('file');
  if (!(file instanceof File)) {
    return NextResponse.json({ error: 'file_required' }, { status: 400 });
  }

  if (!allowedMimeTypes.has(file.type)) {
    return NextResponse.json({ error: 'invalid_mime_type' }, { status: 400 });
  }

  if (file.size > maxBytes) {
    return NextResponse.json({ error: 'file_too_large' }, { status: 400 });
  }

  const service = createSupabaseServiceClient();
  if (!service) {
    return NextResponse.json({ error: 'service_role_required' }, { status: 500 });
  }

  const extension = extensionFromMimeType(file.type);
  const path =
    parsed.data.type === 'item'
      ? `businesses/${parsed.data.businessId}/items/${randomUUID()}.${extension}`
      : parsed.data.type === 'campaign'
        ? `businesses/${parsed.data.businessId}/campaigns/${randomUUID()}.${extension}`
        : `businesses/${parsed.data.businessId}/branding/${parsed.data.type}/${randomUUID()}.${extension}`;
  const { error } = await service.storage.from('menu-media').upload(path, file, {
    contentType: file.type,
    cacheControl: '3600',
    upsert: false,
  });

  if (error) {
    logger.warn('Failed to upload branding media', {
      businessId: parsed.data.businessId,
      type: parsed.data.type,
      error,
    });
    return NextResponse.json({ error: 'upload_failed' }, { status: 500 });
  }

  const { data } = service.storage.from('menu-media').getPublicUrl(path);
  return NextResponse.json({
    ok: true,
    data: {
      bucket: 'menu-media',
      path,
      url: data.publicUrl,
      mimeType: file.type,
      size: file.size,
    },
  });
}

function extensionFromMimeType(mimeType: string) {
  switch (mimeType) {
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/jpeg':
    default:
      return 'jpg';
  }
}
