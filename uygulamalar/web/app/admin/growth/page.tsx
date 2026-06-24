import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Growth | Admin Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: growth/revenue surfaces are disabled for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md).
// Page not deleted, only gated.
export default function AdminGrowthPage(): never {
  redirect('/admin/dashboard');
}
