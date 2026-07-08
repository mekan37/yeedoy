import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Pazarlama | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: pazarlama otomasyonu (push/e-posta/sadakat) final stratejik
// karar raporuna göre (docs/research/2026-yeedoy-stratejik-karar-raporu.md §9)
// MVP'de pasif tutulmalıdır. Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function OwnerMarketingPage(): never {
  redirect('/sahip/gosterge-panosu');
}
