import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Müşteri CRM | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: gelişmiş CRM/segmentasyon final stratejik karar raporuna göre
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2) kapsam dışıdır.
// Sayfa silinmedi, sadece erişilemez hale getirildi (genel bakışa yönlendirme).
export default function CrmPage(): never {
  redirect('/sahip/gosterge-panosu');
}
