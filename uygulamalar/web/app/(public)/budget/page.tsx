import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: budget combos (social/discovery extra) are disabled for MVP
// per the final strategic decision report.
// Mirrors the TR /(genel)/butce redirect. Page not deleted, only gated.
export default function BudgetPage(): never {
  redirect('/discover');
}
