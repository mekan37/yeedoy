import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: budget combos (social/discovery extra) are disabled for MVP
// per the final strategic decision report.
// Mirrors the TR /(genel)/butce redirect target directly (avoids the extra
// /discover→/kesif hop that /butce itself already resolves through).
export default function BudgetPage(): never {
  redirect('/kesif');
}
