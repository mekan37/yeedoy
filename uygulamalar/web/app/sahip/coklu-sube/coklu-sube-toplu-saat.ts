'use server';

import { saveHours } from '@/app/sahip/ayarlar/saatler/saat-islemleri';

const DAY_KEYS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] as const;
export type DayKey = (typeof DAY_KEYS)[number];
export type HoursTemplate = Partial<Record<DayKey, { open: string; close: string } | null>>;

export type TopluIslemSonucu = { successCount: number; failedBusinessIds: string[] };

export async function saatleriTopluUygula(
  businessIds: string[],
  template: HoursTemplate,
): Promise<TopluIslemSonucu> {
  let successCount = 0;
  const failedBusinessIds: string[] = [];

  for (const businessId of businessIds) {
    try {
      const fd = new FormData();
      for (const day of DAY_KEYS) {
        const value = template[day];
        if (value) {
          fd.set(`${day}_open`, value.open);
          fd.set(`${day}_close`, value.close);
        }
      }
      await saveHours(businessId, fd);
      successCount += 1;
    } catch {
      failedBusinessIds.push(businessId);
    }
  }

  return { successCount, failedBusinessIds };
}
