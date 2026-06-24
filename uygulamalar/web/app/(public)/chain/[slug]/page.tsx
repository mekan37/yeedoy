import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: chain pages (social/discovery extra) are disabled for MVP
// per the final strategic decision report.
// Mirrors the TR /(genel)/zincir/[slug] redirect. Page not deleted, only gated.
export default function ChainPage(): never {
  redirect('/discover');
}
