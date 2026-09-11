import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Yeedoy',
  robots: { index: false, follow: false },
};

type Props = { params: Promise<{ slug: string }> };

// /(genel)/zincir/[slug] artık gerçek bir özellik sayfası (yönlendirme değil) —
// bu İngilizce mirror güncellenmemiş, slug'ı hiç taşımadan /discover'a (iki
// sekmelik zincirle /kesif'e) düşüyordu. slug'ı koruyarak gerçek sayfaya yönlendir.
export default async function ChainPage({ params }: Props): Promise<never> {
  const { slug } = await params;
  redirect(`/zincir/${slug}`);
}
