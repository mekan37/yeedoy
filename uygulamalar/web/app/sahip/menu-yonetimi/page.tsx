import { redirect } from 'next/navigation';
import { resolveHedefMenuId } from './hedef-menu';

export default async function MenuYonetimiPage() {
  const menuId = await resolveHedefMenuId();
  redirect(menuId ? `/sahip/menuler/${menuId}/duzenle` : '/sahip/menuler');
}
