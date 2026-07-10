import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Automations | Owner Panel',
  robots: { index: false, follow: false },
};

// Out of MVP scope: marketing automations are kept passive for MVP per the final
// strategic decision report (docs/research/2026-yeedoy-stratejik-karar-raporu.md §9).
// Mirrors the TR /sahip/pazarlama/otomasyonlar redirect. Page not deleted, only gated.
export default function OwnerAutomationsPage(): never {
  redirect('/owner/dashboard');
}
