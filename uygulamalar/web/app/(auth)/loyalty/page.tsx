import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = { title: 'Puan Kartlarım | Yeedoy', robots: { index: false, follow: false } };

// MVP scope dışı: bkz. docs/engineering/2026-yeedoy-loyalty-mvp-defer-decision.md
export default function LoyaltyPage(): never {
  redirect('/discover');
}
