import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'B2B Exports | Admin Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: B2B data exports are disabled for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md).
// Mirrors the TR /yonetici/b2b-dis-aktarim redirect. Page not deleted, only gated.
export default function AdminB2bExportsPage(): never {
  redirect('/admin/dashboard');
}
