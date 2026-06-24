import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Sponsorships | Admin Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: sponsored visibility is disabled for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md §16).
// Mirrors the TR /yonetici/sponsorluklar redirect. Page not deleted, only gated.
export default function AdminSponsorshipsPage(): never {
  redirect('/admin/dashboard');
}
