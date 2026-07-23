import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /(kimlik)/profil/ayarlar (canonical).
export default function ProfileSettingsRedirectPage(): never {
  redirect('/profil/ayarlar');
}
