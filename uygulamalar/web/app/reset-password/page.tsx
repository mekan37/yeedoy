import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /sifre-sifirlama (canonical). Supabase recovery hash
// fragment redirect uzerinde korunur (server tarafina hic gonderilmez).
export default function ResetPasswordRedirectPage(): never {
  redirect('/sifre-sifirlama');
}
