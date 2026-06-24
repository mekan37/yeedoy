import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Table Feedback | Admin Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: table ordering / table feedback is disabled for MVP per the
// final strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md).
// Mirrors the TR /yonetici/masa-geri-bildirimleri redirect. Page not deleted, only gated.
export default function AdminTableFeedbackPage(): never {
  redirect('/admin/dashboard');
}
