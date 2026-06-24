import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Askıya Alınan Yemekler | Admin Panel',
  robots: { index: false, follow: false },
};

// MVP scope dışı: askıya alınan yemekler sadakat/loyalty sistemi kapsamındadır
// ve final scope'ta açıkça KAPSAM DIŞI işaretlenmiştir
// (docs/product/2026-yeedoy-panel-scope-decisions.md REDIRECT_NOW).
// Owner muadili app/owner/suspended/page.tsx ile aynı pattern (commit 43e9fec, 9c44c7d).
// Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function AdminSuspendedPage(): never {
  redirect('/admin/dashboard');
}
