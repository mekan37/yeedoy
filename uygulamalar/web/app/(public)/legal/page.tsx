import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /(genel)/yasal (canonical, daha fazla belge iceriyor).
export default function LegalPage(): never {
  redirect('/yasal');
}
