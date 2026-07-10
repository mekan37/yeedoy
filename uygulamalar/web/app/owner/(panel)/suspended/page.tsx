import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Askıya Alınan Yemekler | Owner Panel',
  robots: { index: false, follow: false },
};

// MVP scope dışı: askıya alınan yemekler sadakat/loyalty sistemi kapsamındadır
// ve final scope'ta açıkça KAPSAM DIŞI işaretlenmiştir
// (docs/product/2026-yeedoy-panel-scope-decisions.md REDIRECT_NOW).
// Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function OwnerSuspendedPage(): never {
  redirect('/owner/dashboard');
}
