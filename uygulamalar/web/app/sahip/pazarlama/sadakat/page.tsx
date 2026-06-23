import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Sadakat Programı | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: bkz. app/sahip/pazarlama/page.tsx
export default function SadakatPage(): never {
  redirect('/sahip/gosterge-panosu');
}
