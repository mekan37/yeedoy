import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /(genel)/isletme-oner (canonical).
export default function SuggestRedirectPage(): never {
  redirect('/isletme-oner');
}
