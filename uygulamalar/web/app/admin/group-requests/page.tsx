import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Grup İstekleri | Admin Panel',
  robots: { index: false, follow: false },
};

// MVP scope dışı: grup istekleri sosyal/platform-ekonomisi özelliğidir ve
// final scope'ta tanımlanmamıştır (docs/product/2026-yeedoy-panel-scope-decisions.md
// REDIRECT_NOW). Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function AdminGroupRequestsPage(): never {
  redirect('/admin/dashboard');
}
