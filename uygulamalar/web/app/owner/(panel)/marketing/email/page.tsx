import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Email Campaigns | Owner Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: email marketing is kept passive for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md §9).
// Mirrors the TR /sahip/pazarlama/e-posta redirect. Page not deleted, only gated.
export default function OwnerEmailCampaignsPage(): never {
  redirect('/owner/dashboard');
}
