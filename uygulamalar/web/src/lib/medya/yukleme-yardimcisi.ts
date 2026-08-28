import { logger } from '@/src/lib/kayitci';

// Tüm görsel yükleme route'larının (kampanya, branding, yorum fotoğrafı,
// işletme galerisi, admin stok görsel kütüphanesi) paylaştığı tek doğrulama +
// Storage yazma katmanı. Her route kendi auth/sahiplik/rate-limit mantığını
// korur, sadece "dosyayı doğrula ve yaz" kısmı burada tekilleşir.

// Sıkıştırma <canvas> üzerinden çalışıyor: JPEG/PNG/WebP/GIF her tarayıcıda
// güvenilir şekilde açılır. HEIC/HEIF (iPhone varsayılanı) sadece Safari'de
// <img> ile açılabiliyor — Chrome/Firefox'ta reddedilebilir, bu yüzden burada
// kabul edilse de istemci tarafında "görsel işlenemedi" hatasına düşebilir.
export const VARSAYILAN_IZINLI_MIME = new Set([
  'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif',
]);
// İstemci tarafında zaten WebP'ye sıkıştırılıp küçültülmüş dosya bu limite
// tabi olur — gerçek dünyada buraya yaklaşan neredeyse hiç dosya olmaz, bu
// sadece kötüye kullanıma karşı bir güvenlik tavanı.
export const VARSAYILAN_MAX_BAYT = 20 * 1024 * 1024;

export type GorselYuklemeSonucu =
  | { ok: true; data: { bucket: string; path: string; url: string; mimeType: string; size: number } }
  | { ok: false; error: string; status: number };

export function dosyaUzantisi(mimeType: string): string {
  switch (mimeType) {
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    case 'image/heic':
      return 'heic';
    case 'image/heif':
      return 'heif';
    case 'image/jpeg':
    default:
      return 'jpg';
  }
}

interface SupabaseStorageLike {
  storage: {
    from(bucket: string): {
      upload(path: string, file: File, opts: { contentType: string; cacheControl: string; upsert: boolean }): Promise<{ error: unknown }>;
      getPublicUrl(path: string): { data: { publicUrl: string } };
    };
  };
}

/**
 * Bir form alanından gelen dosyayı doğrular (mime/boyut) ve service-role
 * istemcisiyle Storage'a yazar. Auth/sahiplik/rate-limit kontrolü çağıran
 * route'un sorumluluğunda — burası sadece dosya ile ilgilenir.
 */
export async function gorselYukle({
  service,
  bucket,
  file,
  path,
  allowedMime = VARSAYILAN_IZINLI_MIME,
  maxBytes = VARSAYILAN_MAX_BAYT,
  logContext,
}: {
  service: SupabaseStorageLike;
  bucket: string;
  file: FormDataEntryValue | null;
  path: string;
  allowedMime?: Set<string>;
  maxBytes?: number;
  logContext?: Record<string, unknown>;
}): Promise<GorselYuklemeSonucu> {
  if (!(file instanceof File)) {
    return { ok: false, error: 'file_required', status: 400 };
  }
  if (!allowedMime.has(file.type)) {
    return { ok: false, error: 'invalid_mime_type', status: 400 };
  }
  if (file.size > maxBytes) {
    return { ok: false, error: 'file_too_large', status: 413 };
  }

  const { error } = await service.storage.from(bucket).upload(path, file, {
    contentType: file.type,
    cacheControl: '3600',
    upsert: false,
  });

  if (error) {
    logger.warn('Görsel yükleme başarısız', { bucket, path, error, ...logContext });
    return { ok: false, error: 'upload_failed', status: 500 };
  }

  const { data } = service.storage.from(bucket).getPublicUrl(path);
  return {
    ok: true,
    data: { bucket, path, url: data.publicUrl, mimeType: file.type, size: file.size },
  };
}
