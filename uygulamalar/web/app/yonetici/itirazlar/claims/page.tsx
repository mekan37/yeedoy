import { redirect } from 'next/navigation';

// Sahiplenme Kuyruğu, İnceleme Kuyruğu ile birlikte tek çatı altında toplandı.
export default function AdminClaimsRedirect() {
  redirect('/yonetici/kuyruklar?tab=sahiplenme');
}
