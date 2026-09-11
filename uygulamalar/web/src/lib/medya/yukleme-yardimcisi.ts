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

const HEIC_BRANDS = ['heic', 'heix', 'heim', 'heis', 'hevc', 'hevx', 'mif1', 'msf1'];

/**
 * İstemcinin beyan ettiği Content-Type tamamen sahtelenebilir — bu yüzden
 * yükleme kabul edilmeden önce dosyanın ilk baytları (magic number) beyan
 * edilen türle eşleşiyor mu kontrol edilir. Yalnızca VARSAYILAN_IZINLI_MIME
 * setindeki türler için imza tanımlı; bilinmeyen bir mime zaten yukarıda
 * reddediliyor.
 */
async function magicBytesEslesiyorMu(file: File, mimeType: string): Promise<boolean> {
  const head = new Uint8Array(await file.slice(0, 32).arrayBuffer());
  const startsWith = (bytes: number[], offset = 0) =>
    bytes.every((b, i) => head[offset + i] === b);
  const asciiAt = (offset: number, len: number) =>
    String.fromCharCode(...head.slice(offset, offset + len));

  switch (mimeType) {
    case 'image/jpeg':
      return startsWith([0xff, 0xd8, 0xff]);
    case 'image/png':
      return startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    case 'image/gif':
      return asciiAt(0, 4) === 'GIF8';
    case 'image/webp':
      return asciiAt(0, 4) === 'RIFF' && asciiAt(8, 4) === 'WEBP';
    case 'image/heic':
    case 'image/heif': {
      // ISO-BMFF: bayt 4-7 'ftyp', ardından 4 baytlık major brand.
      if (asciiAt(4, 4) !== 'ftyp') return false;
      const brand = asciiAt(8, 4).toLowerCase();
      return HEIC_BRANDS.includes(brand);
    }
    default:
      return false;
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
  if (!(await magicBytesEslesiyorMu(file, file.type))) {
    return { ok: false, error: 'invalid_mime_type', status: 400 };
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
