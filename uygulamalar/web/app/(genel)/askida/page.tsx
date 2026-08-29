import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Askıda Öğünler | Yeedoy',
  robots: { index: false, follow: false },
};

// MVP scope dışı: askıda öğün bağışı (suspended meals) final strateji kararına göre
// kapsam dışı bırakıldı. Sayfa silinmedi, keşif sayfasına yönlendirildi.
export default async function SuspendedMealsPage(): Promise<never> {
  redirect('/kesif');
}
