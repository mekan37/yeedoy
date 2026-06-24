import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// Out of MVP scope: contributor leaderboard (gamification) is disabled for MVP
// per the final strategic decision report
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2).
// Mirrors the TR /(genel)/liderler redirect. Page not deleted, only gated.
export default function HeroesPage(): never {
  redirect('/discover');
}
