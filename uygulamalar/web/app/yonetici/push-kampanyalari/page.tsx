import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Push Kampanyaları | Admin Panel',
  robots: { index: false, follow: false },
};

// MVP scope dışı: kitlesel push pazarlama final stratejik karar raporuna göre
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §9) MVP'de pasif
// tutulmalıdır. Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function PushKampanyalariPage(): never {
  redirect('/yonetici/gosterge-panosu');
}
