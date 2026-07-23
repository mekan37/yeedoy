import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /(kimlik)/askiya-alinma-talepleri (canonical).
export default function ClaimsRedirectPage(): never {
  redirect('/askiya-alinma-talepleri');
}
