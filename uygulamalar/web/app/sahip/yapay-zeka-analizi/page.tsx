import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yapay Zeka Menü Analizi | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: AI menü analizi ürün kararı netleşmeden kapsam dışı
// tutulmuştur (docs/engineering/2026-yeedoy-mvp-scope-prune-audit.md
// NEEDS_HUMAN_DECISION). Sayfa silinmedi, sadece erişilemez hale getirildi.
export default function OwnerAiAnalysisPage(): never {
  redirect('/sahip/gosterge-panosu');
}
