import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'E-posta Kampanyaları | Sahip Paneli',
  robots: { index: false, follow: false },
};

// MVP scope dışı: bkz. app/sahip/pazarlama/page.tsx
export default function OwnerEmailCampaignsPage(): never {
  redirect('/sahip/gosterge-panosu');
}
