import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Doğrulanmış İşletmeler | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default function AdminVerifiedPage() {
  redirect('/yonetici/isletmeler?status=verified');
}
