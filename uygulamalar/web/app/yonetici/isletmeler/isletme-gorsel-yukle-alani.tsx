'use client';

import Image from 'next/image';
import { useState } from 'react';
import { compressToWebP } from '@/src/lib/gorsel-sikistir';

const MAX_PX: Record<'logo' | 'kapak', number> = { logo: 800, kapak: 1600 };
const ALAN_ETIKETI: Record<'logo' | 'kapak', string> = { logo: 'Logo önizleme', kapak: 'Kapak önizleme' };

/**
 * "Genel Bilgiler" sekmesindeki logo/kapak URL alanlarının yanına eklenen
 * dosya yükleme widget'ı. URL alanını değiştirmiyor — yalnızca yüklenen
 * görselin public URL'ini onUploaded ile forma yazdırıyor, kaydetme akışı
 * (admin_update_business_v1 çağrısı) hiç değişmiyor.
 */
export function IsletmeGorselYukleAlani({
  businessId,
  kind,
  currentUrl,
  onUploaded,
}: {
  businessId: string;
  kind: 'logo' | 'kapak';
  currentUrl: string;
  onUploaded: (url: string) => void;
}) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function dosyaYukle(file: File | null) {
    if (!file) return;
    setUploading(true);
    setError(null);
    try {
      const compressed = await compressToWebP(file, MAX_PX[kind]);
      const formData = new FormData();
      formData.set('file', compressed);
      formData.set('businessId', businessId);
      formData.set('kind', kind);
      const response = await fetch('/sunucu/medya/isletme-yukleme', { method: 'POST', body: formData });
      const payload = (await response.json().catch(() => null)) as { data?: { url?: string } } | null;
      if (!response.ok || !payload?.data?.url) throw new Error('upload_failed');
      onUploaded(payload.data.url);
    } catch {
      setError('Görsel yüklenemedi, tekrar deneyin.');
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="flex items-center gap-2">
      {currentUrl && (
        <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-lg border border-border bg-bg">
          <Image src={currentUrl} alt={ALAN_ETIKETI[kind]} fill sizes="40px" className="object-cover" unoptimized />
        </div>
      )}
      <label className="inline-flex min-h-9 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-extrabold text-textStrong transition-colors hover:bg-black/4">
        {uploading ? 'Yükleniyor...' : 'Görsel Yükle'}
        <input
          type="file"
          accept="image/png,image/jpeg,image/webp,image/gif,image/heic,image/heif"
          disabled={uploading}
          onChange={(e) => dosyaYukle(e.target.files?.[0] ?? null)}
          className="sr-only"
        />
      </label>
      {error && <p className="text-xs font-bold text-(--yd-color-danger)">{error}</p>}
    </div>
  );
}
