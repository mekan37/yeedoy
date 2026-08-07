'use server';

import { kampanyaKaydet } from '@/app/sahip/pazarlama/kampanyalar/kampanya-islemleri';
import type { TopluIslemSonucu } from './coklu-sube-toplu-saat';

export type KampanyaSablonu = {
  title: string;
  type: 'discount' | 'special_offer' | 'loyalty' | 'announcement';
  status: 'draft' | 'planned' | 'active' | 'completed';
  description?: string;
  discountPercent?: number;
  startsAt?: string;
  endsAt?: string;
};

export async function kampanyaTopluOlustur(
  businessIds: string[],
  template: KampanyaSablonu,
): Promise<TopluIslemSonucu> {
  let successCount = 0;
  const failedBusinessIds: string[] = [];

  for (const businessId of businessIds) {
    const fd = new FormData();
    fd.set('business_id', businessId);
    fd.set('title', template.title);
    fd.set('type', template.type);
    fd.set('status', template.status);
    if (template.description) fd.set('description', template.description);
    if (template.discountPercent != null) fd.set('discount_percent', String(template.discountPercent));
    if (template.startsAt) fd.set('starts_at', template.startsAt);
    if (template.endsAt) fd.set('ends_at', template.endsAt);

    const result = await kampanyaKaydet(null, fd);
    if (result?.error) {
      failedBusinessIds.push(businessId);
    } else {
      successCount += 1;
    }
  }

  return { successCount, failedBusinessIds };
}
