import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { IsletmeOnerFormu } from './isletme-oner-formu';

export const metadata: Metadata = {
  title: 'İşletme Öner | Yeedoy',
  description: 'Bildiğin kaliteli bir restoranı, kafe veya mekanı Yeedoy topluluğuyla paylaş.',
  alternates: { canonical: '/isletme-oner' },
};

export default function IsletmeOnerPage() {
  return (
    <PublicShell>
      <IsletmeOnerFormu />
    </PublicShell>
  );
}
