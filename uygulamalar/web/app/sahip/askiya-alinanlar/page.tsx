import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Askıya Alınan Yemekler | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: askıya alınan yemekler sadakat/loyalty sistemi kapsamındadır
// ve final scope'ta açıkça KAPSAM DIŞI işaretlenmiştir
// (docs/product/2026-yeedoy-panel-scope-decisions.md REDIRECT_NOW).
// Admin muadili app/admin/suspended/page.tsx ile aynı pattern (commit 43e9fec).
// Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function SahipAskiyaAlinanlarSayfasi(): never {
  redirect('/sahip/gosterge-panosu');
}
