import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Sponsorship Packages | Admin Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: sponsorship packages are disabled for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md §16).
// Mirrors the TR /yonetici/sponsor-paketleri redirect. Page not deleted, only gated.
export default function AdminSponsorshipPackagesPage(): never {
  redirect('/admin/dashboard');
}
