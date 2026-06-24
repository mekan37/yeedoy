import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Growth | Owner Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: growth/revenue surfaces are kept passive for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md).
// Mirrors the TR /sahip/buyume redirect. Page not deleted, only gated.
export default function OwnerGrowthPage(): never {
  redirect('/owner/dashboard');
}
