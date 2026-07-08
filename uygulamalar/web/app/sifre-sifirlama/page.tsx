import type { Metadata } from 'next';
import { PublicShell } from '@/src/ui/acik/yerlesim';
import { SifreSifirlamaFormu } from '@/src/ui/bolumler/sifre-sifirlama-formu';

export const metadata: Metadata = {
  title: 'Yeni Şifre Belirle | Yeedoy',
  robots: { index: false, follow: false },
};

export default function SifreSifirlamaPage() {
  return (
    <PublicShell footer={false}>
      <SifreSifirlamaFormu />
    </PublicShell>
  );
}
