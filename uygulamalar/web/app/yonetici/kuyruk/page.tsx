import { redirect } from 'next/navigation';

// İnceleme Kuyruğu, Sahiplenme Kuyruğu ile birlikte tek çatı altında toplandı.
export default function AdminQueueRedirect() {
  redirect('/yonetici/kuyruklar?tab=inceleme');
}
