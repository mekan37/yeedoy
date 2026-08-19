import type { Metadata } from 'next';
import { IsletmeGirisFormu } from '@/src/ui/bolumler/isletme-giris-formu';

export const metadata: Metadata = {
  title: 'İşletme Paneline Kayıt Ol | Yeedoy',
  description: 'İşletmeni Yeedoy\'a ekle, menünü yönet, yorumları takip et ve istatistiklerle büyü.',
  robots: { index: false, follow: false },
  alternates: { canonical: '/isletme-kayit' },
};

export default function IsletmeKayitPage() {
  return <IsletmeGirisFormu initialTab="kayit" />;
}
