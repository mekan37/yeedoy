// Sabitler ve tipler — 'use server' değil, hem client hem server tarafında import edilebilir

export const DESTEKLENEN_DILLER = ['en', 'ar'] as const;
export type DestekDil = (typeof DESTEKLENEN_DILLER)[number];

export const DIL_ETIKETLERI: Record<DestekDil, string> = {
  en: 'English',
  ar: 'العربية',
};

export type CeviriSatiri = {
  itemId: string;
  itemNameTr: string;
  itemDescTr: string | null;
  sectionName: string;
  menuId: string;
  menuTitle: string;
  translations: Partial<
    Record<DestekDil, { name: string | null; description: string | null }>
  >;
};
