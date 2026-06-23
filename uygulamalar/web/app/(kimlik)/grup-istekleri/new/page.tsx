import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// MVP scope dışı: bkz. app/(kimlik)/grup-istekleri/page.tsx
export default function GroupRequestNewPage(): never {
  redirect('/kesif');
}
