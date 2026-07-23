import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /(kimlik)/favoriler (canonical).
export default function FavoritesRedirectPage(): never {
  redirect('/favoriler');
}
