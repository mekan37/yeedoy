import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  return { title: `${slug} | Yeedoy`, robots: { index: false, follow: false } };
}

// MVP scope dışı: sipariş/sepet/ödeme final stratejik karar raporuna göre
// (docs/research/2026-yeedoy-stratejik-karar-raporu.md §23 Yapılmayacaklar)
// asla kapsama girmemelidir. Sayfa silinmedi, menü görüntülemeye yönlendirildi.
export default async function SiparisPage({ params }: Props): Promise<never> {
  const { slug } = await params;
  redirect(`/isletme/${slug}`);
}
