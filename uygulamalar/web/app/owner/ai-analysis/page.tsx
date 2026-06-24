import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'AI Menü Analizi | Owner Panel',
  robots: { index: false, follow: false },
};

// MVP scope dışı: AI menü analizi ürün kararı netleşmeden kapsam dışı
// tutulmuştur (docs/product/2026-yeedoy-panel-scope-decisions.md
// NEEDS_HUMAN_DECISION → REDIRECT_NOW). Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function OwnerAiAnalysisPage(): never {
  redirect('/owner/dashboard');
}
