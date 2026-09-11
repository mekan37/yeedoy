import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: business compare (social/discovery extra) is disabled for MVP
// per the final strategic decision report.
// Mirrors the TR /(genel)/karsilastir redirect target directly (avoids the
// extra /discover→/kesif hop that /karsilastir itself already resolves through).
export default function ComparePage(): never {
  redirect('/kesif');
}
