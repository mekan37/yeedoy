import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Sponsorship Leads | Admin Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: sponsorship pipeline is disabled for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md §16).
// Mirrors the TR /yonetici/sponsor-adaylari redirect. Page not deleted, only gated.
export default function AdminSponsorshipLeadsPage(): never {
  redirect('/admin/dashboard');
}
