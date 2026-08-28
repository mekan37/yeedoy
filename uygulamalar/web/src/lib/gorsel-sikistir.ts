/**
 * @param maxPx En uzun kenar için piksel sınırı.
 * @param quality WebP kalitesi (0-1). Standart fotoğraflar için varsayılan
 *   0.85 yeterli; OCR'a gidecek görsellerde (menü/makbuz taraması) metin
 *   netliği için 0.92+ ve daha büyük bir maxPx kullanılmalı.
 */
export async function compressToWebP(file: File, maxPx: number, quality = 0.85): Promise<File> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const objectUrl = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(objectUrl);
      let { width, height } = img;
      if (width > maxPx || height > maxPx) {
        const ratio = Math.min(maxPx / width, maxPx / height);
        width = Math.round(width * ratio);
        height = Math.round(height * ratio);
      }
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      canvas.getContext('2d')!.drawImage(img, 0, 0, width, height);
      canvas.toBlob(
        (blob) => {
          if (!blob) { reject(new Error('compress_failed')); return; }
          resolve(new File([blob], file.name.replace(/\.[^.]+$/, '.webp'), { type: 'image/webp' }));
        },
        'image/webp',
        quality,
      );
    };
    img.onerror = () => { URL.revokeObjectURL(objectUrl); reject(new Error('load_failed')); };
    img.src = objectUrl;
  });
}
