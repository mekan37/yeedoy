import type { Metadata } from 'next';
import { NewMenuClient } from './new-menu-client';

export const metadata: Metadata = {
  title: 'Yeni Menü Ekle | Admin Panel',
  robots: { index: false, follow: false },
};

type Props = { params: Promise<{ id: string }> };

export default async function AdminNewMenuPage({ params }: Props) {
  const { id } = await params;
  return <NewMenuClient businessId={id} />;
}
