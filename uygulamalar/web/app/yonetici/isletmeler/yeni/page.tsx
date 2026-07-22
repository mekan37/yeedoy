import type { Metadata } from 'next';
import { YeniIsletmeIstemcisi } from './yeni-isletme-istemcisi';

export const metadata: Metadata = {
  title: 'Yeni İşletme Ekle | Yönetici Paneli',
  robots: { index: false, follow: false },
};

export default function YoneticiYeniIsletmePage() {
  return <YeniIsletmeIstemcisi />;
}
