import { redirect } from 'next/navigation';
import { panelUrl } from '@/src/lib/panelUrl';

export default function OwnerPage() {
  redirect(panelUrl('/owner'));
}
