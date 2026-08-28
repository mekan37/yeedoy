import Image from 'next/image';
import type { ReactNode } from 'react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

// Görsel gösterilen her yerin (kart, galeri, popup, avatar) paylaştığı tek
// bileşen: en/boy oranını sabitler, buildMenuImageUrl ile Supabase Storage
// transform'unu (yeniden boyutlandırma + kalite) uygular, kaynak yoksa
// fallback gösterir. Görsel yükleme tarafının karşılığı — orası
// useGorselYukleme (src/lib/medya/kullanim-yukleme.ts).

interface OptimizeGorselProps {
  src: string | null | undefined;
  alt: string;
  /** CSS aspect-ratio değeri, ör. '16/10', '4/3', '1/1'. */
  aspect?: string;
  /** Storage transform genişliği (px) — gerçek render boyutuna yakın tutun. */
  width?: number;
  quality?: number;
  sizes?: string;
  className?: string;
  priority?: boolean;
  /** src yoksa veya çözülemezse gösterilecek içerik. */
  fallback?: ReactNode;
}

export function OptimizeGorsel({
  src,
  alt,
  aspect = '4/3',
  width = 640,
  quality = 78,
  sizes = '(max-width: 640px) 100vw, 400px',
  className = '',
  priority,
  fallback = null,
}: OptimizeGorselProps) {
  const url = buildMenuImageUrl(src, { width, quality });
  if (!url) return <>{fallback}</>;

  return (
    <div className={`relative overflow-hidden ${className}`} style={{ aspectRatio: aspect }}>
      <Image src={url} alt={alt} fill sizes={sizes} priority={priority} className="object-cover" />
    </div>
  );
}
