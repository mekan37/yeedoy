import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// MVP scope dışı: bkz. app/(kimlik)/ortak-listeler/page.tsx
export default function CollabListJoinPage(): never {
  redirect('/kesif');
}
