import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /sifremi-unuttum (canonical).
export default function ForgotPasswordRedirectPage(): never {
  redirect('/sifremi-unuttum');
}
