import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Masa Geri Bildirimleri | Yonetici Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: masa siparişi/POS geri bildirimi final stratejik karar raporuna
// göre (docs/research/2026-yeedoy-stratejik-karar-raporu.md §23) kapsam dışıdır.
// Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function MasaGeriBildirimleriPage(): never {
  redirect('/yonetici/gosterge-panosu');
}
