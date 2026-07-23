import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Yeedoy', robots: { index: false, follow: false } };

// Turkce karsiligi: /(kimlik)/fiyat-uyarilari (canonical).
export default function PriceAlertsRedirectPage(): never {
  redirect('/fiyat-uyarilari');
}
