import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: collaborative lists (social) are disabled for MVP per the final
// strategic decision report. Mirrors the TR /(kimlik)/ortak-listeler/[id] redirect.
// Page not deleted, only gated.
export default function CollabListDetailPage(): never {
  redirect('/discover');
}
