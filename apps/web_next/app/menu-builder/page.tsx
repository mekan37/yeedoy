import { redirect } from 'next/navigation';
import { panelUrl } from '@/src/lib/panelUrl';

export default function MenuBuilderPage() {
  redirect(panelUrl('/owner/menus'));
}
