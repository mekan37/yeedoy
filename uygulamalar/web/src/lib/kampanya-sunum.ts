// Kampanya rozeti/renk/süre hesaplama — /kampanyalar genel listesi (kampanyalar-canli.tsx)
// ve işletme detay sayfasındaki "Kampanyalar" sekmesi (isletme-detay-tablari.tsx) arasında
// paylaşılan tek kaynak. İkisi de aynı public.campaigns şemasını (type/discount_percent/
// ends_at) aynı görsel dille sunmalı.

export type KampanyaTuru = 'discount' | 'special_offer' | 'loyalty' | 'announcement';

export type BadgeLine = { metin: string; buyuk?: boolean };

export const TUR_ETIKETLER: Record<KampanyaTuru, string> = {
  discount:      'İndirim',
  special_offer: 'Özel Fırsat',
  loyalty:       'Sadakat',
  announcement:  'Duyuru',
};

export const TUR_RENK: Record<KampanyaTuru, string> = {
  discount:      '#7f1d1d',
  special_offer: '#b45309',
  loyalty:       '#0e7490',
  announcement:  '#16a34a',
};

export function gunKaldiHesapla(endsAt: string | null): number | null {
  if (!endsAt) return null;
  const fark = new Date(endsAt).getTime() - Date.now();
  return Math.max(0, Math.ceil(fark / 86_400_000));
}

export function kampanyaBadge(tur: KampanyaTuru, discountPercent: number | null): BadgeLine[] {
  if (tur === 'discount' && discountPercent != null) {
    return [{ metin: `%${discountPercent}`, buyuk: true }, { metin: 'İNDİRİM' }];
  }
  return [{ metin: TUR_ETIKETLER[tur].toLocaleUpperCase('tr'), buyuk: true }];
}
