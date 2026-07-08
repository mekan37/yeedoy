import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { SifremiUnuttumFormu } from '@/src/ui/bolumler/sifremi-unuttum-formu';

export const metadata: Metadata = {
  title: 'Şifremi Unuttum | Yeedoy',
  robots: { index: false, follow: false },
};

export default function SifremiUnuttumPage() {
  return (
    <PublicShell footer={false}>
      <SifremiUnuttumFormu />
    </PublicShell>
  );
}
