import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

// MVP scope dışı: liderlik tablosu/gamification final stratejik karar raporuna
// göre (docs/research/2026-yeedoy-stratejik-karar-raporu.md §7 P2) merkezi
// mekanik olmamalıdır. Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function HeroesPage(): never {
  redirect('/kesif');
}
