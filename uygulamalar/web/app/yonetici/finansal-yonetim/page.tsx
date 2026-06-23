import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Finansal Yönetim | Admin Panel',
  robots: { index: false, follow: false },
};

// MVP scope dışı: sponsorluk gelirine dayalı finansal yönetim final stratejik
// karar raporuna göre (docs/research/2026-yeedoy-stratejik-karar-raporu.md §16)
// MVP'de kapalıdır. Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function FinansalYonetimPage(): never {
  redirect('/yonetici/gosterge-panosu');
}
