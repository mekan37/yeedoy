import type { Metadata } from 'next';
import { NewBusinessClient } from './new-business-client';

export const metadata: Metadata = {
  title: 'Yeni İşletme Ekle | Admin Panel',
  robots: { index: false, follow: false },
};

export default function AdminNewBusinessPage() {
  return <NewBusinessClient />;
}
