import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Grup İstekleri | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: grup istekleri final stratejik karar raporuna göre
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2) kapsam dışıdır.
// Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function OwnerGroupRequestsPage(): never {
  redirect('/sahip/gosterge-panosu');
}
