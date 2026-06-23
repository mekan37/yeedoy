import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Masa Siparişleri | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: sipariş/POS özelliği final stratejik karar raporuna göre
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §23) kapsam dışıdır.
// Sayfa silinmedi, sadece erişilemez hale getirildi (genel bakışa yönlendirme).
export default function SiparislerPage(): never {
  redirect('/sahip/gosterge-panosu');
}
