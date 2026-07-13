import type { Metadata } from 'next';
import { NotificationsClient } from './notifications-client';

export const metadata: Metadata = {
  title: 'Bildirimler | Owner Panel',
  robots: { index: false, follow: false },
};

export default function OwnerNotificationsPage() {
  return <NotificationsClient />;
}
