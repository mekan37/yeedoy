'use client';

import { useState, useCallback } from 'react';
import { compressToWebP } from '@/src/lib/gorsel-sikistir';

// Kampanya formu, işletme logosu/kapağı ve sahip fotoğrafları gibi tüm
// "sıkıştır → sunucuya yükle → URL al" akışlarının paylaştığı tek hook.
// Sunucu tarafındaki hata kodlarını (rate_limited, file_too_large, vb.)
// tutarlı Türkçe mesajlara çeviren tek yer de burası.

function hataMesaji(kod: string | undefined): string {
  switch (kod) {
    case 'rate_limited':
      return 'Çok fazla istek, bekleyin.';
    case 'file_too_large':
      return 'Dosya çok büyük.';
    case 'invalid_mime_type':
      return 'Desteklenmeyen dosya türü.';
    case 'forbidden':
      return 'Bu işletmeyi düzenleme yetkiniz yok.';
    case 'photo_limit_reached':
      return 'Fotoğraf limitine ulaşıldı.';
    default:
      return 'Yükleme başarısız.';
  }
}

export interface GorselYuklemeSecenekleri {
  /** Sunucu route'u, ör. '/sunucu/medya/yukleme'. */
  endpoint: string;
  /** FormData'ya eklenecek sabit alanlar, ör. { businessId, type: 'campaign' }. */
  extraFields?: Record<string, string>;
  /** Yüklemeden önce istemci tarafında küçültme sınırı (px). */
  maxPx?: number;
}

export function useGorselYukleme({ endpoint, extraFields, maxPx = 1600 }: GorselYuklemeSecenekleri) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const upload = useCallback(async (file: File): Promise<string | null> => {
    setError(null);
    setUploading(true);
    try {
      const compressed = await compressToWebP(file, maxPx);
      const fd = new FormData();
      for (const [key, value] of Object.entries(extraFields ?? {})) {
        fd.append(key, value);
      }
      fd.append('file', compressed);

      const response = await fetch(endpoint, { method: 'POST', body: fd });
      const result = await response.json().catch(() => null) as { data?: { url?: string }; error?: string } | null;

      if (!response.ok) {
        setError(hataMesaji(result?.error));
        return null;
      }
      const url = result?.data?.url;
      if (!url) {
        setError('Yükleme başarısız.');
        return null;
      }
      return url;
    } catch (err) {
      setError(
        err instanceof Error && ['compress_failed', 'load_failed'].includes(err.message)
          ? 'Görsel işlenemedi, farklı bir dosya deneyin.'
          : 'Yükleme sırasında bir bağlantı hatası oluştu. Lütfen tekrar deneyin.',
      );
      return null;
    } finally {
      setUploading(false);
    }
  }, [endpoint, extraFields, maxPx]);

  return { upload, uploading, error, setError };
}
