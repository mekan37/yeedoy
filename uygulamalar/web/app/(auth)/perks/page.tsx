import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /(kimlik)/avantajlar (canonical).
export default function PerksRedirectPage(): never {
  redirect('/avantajlar');
}
