import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Büyüme | Yönetici Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: gelişmiş büyüme/dönüşüm analitiği final stratejik karar
// raporuna göre (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2)
// kapsam dışıdır. Sayfa silinmedi, sadece erişilemez hale getirildi
// (bkz. app/sahip/buyume/page.tsx — aynı karar owner tarafında zaten uygulanmıştı).
export default function AdminGrowthPage(): never {
  redirect('/yonetici/gosterge-panosu');
}
