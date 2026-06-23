import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Sponsorluklar | Yonetici Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: sponsorlu görünürlük final stratejik karar raporuna göre
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §16) MVP'de kapalıdır.
// Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function AdminSponsorshipsPage(): never {
  redirect('/yonetici/gosterge-panosu');
}
