import type { Metadata } from 'next';
import { IsletmeGirisFormu } from '@/src/ui/bolumler/isletme-giris-formu';

export const metadata: Metadata = {
  title: 'İşletme Paneline Giriş Yap | Yeedoy',
  robots: { index: false, follow: false },
  alternates: { canonical: '/isletme-giris' },
};

export default function IsletmeGirisPage() {
  return <IsletmeGirisFormu initialTab="giris" />;
}
