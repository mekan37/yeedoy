import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Sadakat Programı | Owner Panel',
  robots: { index: false, follow: false },
};

// MVP scope dışı: bkz. docs/engineering/2026-yeedoy-loyalty-mvp-defer-decision.md
export default function OwnerLoyaltyPage(): never {
  redirect('/owner/dashboard');
}
