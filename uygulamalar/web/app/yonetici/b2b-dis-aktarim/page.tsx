import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'B2B Dışa Aktarma | Yonetici Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: B2B veri dışa aktarımı final stratejik karar raporuna göre
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2) kapsam dışıdır.
// Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function AdminB2bExportsPage(): never {
  redirect('/yonetici/gosterge-panosu');
}
