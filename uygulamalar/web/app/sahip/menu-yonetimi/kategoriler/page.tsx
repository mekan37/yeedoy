import { redirect } from 'next/navigation';
import { resolveHedefMenuId } from '../hedef-menu';

export default async function MenuYonetimiKategorilerPage() {
  const menuId = await resolveHedefMenuId();
  redirect(menuId ? `/sahip/menuler/${menuId}/kategoriler` : '/sahip/menuler');
}
