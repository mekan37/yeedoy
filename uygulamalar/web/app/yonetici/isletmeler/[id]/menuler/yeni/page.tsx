import type { Metadata } from 'next';
import { YeniMenuIstemcisi } from './yeni-menu-istemcisi';

export const metadata: Metadata = {
  title: 'Yeni Menü Ekle | Yönetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { params: Promise<{ id: string }> };

export default async function YoneticiYeniMenuPage({ params }: Props) {
  const { id } = await params;
  return <YeniMenuIstemcisi businessId={id} />;
}
