import { redirect } from 'next/navigation';

export default function AdminAuditLegacyRedirect() {
  redirect('/yonetici/olaylar');
}
