import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: taste-twin (social) is disabled for MVP per the final strategic
// decision report. Mirrors the TR /(kimlik)/tat-ikizi redirect.
// Page not deleted, only gated.
export default function TasteTwinPage(): never {
  redirect('/discover');
}
