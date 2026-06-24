import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: community/gourmet feed (gamification/social) is disabled for MVP
// per the final strategic decision report
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2).
// Mirrors the TR /(genel)/akis intent. Page not deleted, only gated.
export default function FeedPage(): never {
  redirect('/discover');
}
