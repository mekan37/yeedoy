import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Finansal Raporlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: finansal raporlama (sipariş gelirine dayalı) final stratejik
// karar raporuna göre (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2)
// kapsam dışıdır. Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function FinansalRaporlarPage(): never {
  redirect('/sahip/gosterge-panosu');
}
