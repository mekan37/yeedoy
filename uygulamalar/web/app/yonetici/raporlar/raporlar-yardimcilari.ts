export type RaporDurumu = 'open' | 'reviewing' | 'closed';

export const DURUM_ETIKETLERI: Record<RaporDurumu, string> = {
  open: 'Beklemede',
  reviewing: 'İnceleniyor',
  closed: 'Kapatıldı',
};

export const DURUM_RENKLERI: Record<RaporDurumu, string> = {
  open: 'bg-amber-50 text-amber-700',
  reviewing: 'bg-blue-50 text-blue-700',
  closed: 'bg-zinc-100 text-zinc-600',
};

export type HedefTuru = 'business' | 'review' | 'menu_item_photo';

export const HEDEF_ETIKETLERI: Record<HedefTuru, string> = {
  business: 'İşletme',
  review: 'Yorum',
  menu_item_photo: 'Menü Fotoğrafı',
};

export interface RaporSatiri {
  id: string;
  reason: string;
  details: string | null;
  status: string;
  targetType: string;
  createdAt: string;
  reporterName: string | null;
  targetLabel: string | null;
  ageHours: number;
  slaBreached: boolean;
}

export function raporNoOlustur(id: string): string {
  return `#R-${id.replace(/-/g, '').slice(0, 5).toUpperCase()}`;
}

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}
