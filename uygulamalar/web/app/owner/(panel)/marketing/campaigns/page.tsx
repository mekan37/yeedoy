import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Campaigns | Owner Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: marketing campaigns are kept passive for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md §9).
// Mirrors the TR /sahip/pazarlama/kampanyalar redirect. Page not deleted, only gated.
export default function OwnerCampaignsPage(): never {
  redirect('/owner/dashboard');
}
