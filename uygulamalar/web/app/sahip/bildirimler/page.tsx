import type { Metadata } from 'next';
import { NotificationsClient } from './bildirimler-istemcisi';

export const metadata: Metadata = {
  title: 'Bildirimler | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default function OwnerNotificationsPage() {
  return <NotificationsClient />;
}
