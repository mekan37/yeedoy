import { describe, expect, it } from 'vitest';
import { menuExtractorPollJob, menuExtractorStartSourceDiscoveryJob } from '@/src/lib/menu-analiz/disari-cagri';
import { normalizeExtractResult, parseDiscoveryOutcome } from '@/app/yonetici/isletmeler/[id]/menu-analiz/menu-analiz-yardimcilari';

const liveIt = process.env.MENU_EXTRACTOR_LIVE_E2E === '1' ? it : it.skip;

describe('Cafevisal canlı Menu Extractor server entegrasyonu', () => {
  liveIt('source-discovery sonucunu 141 review adayına normalize eder', { timeout: 120_000 }, async () => {
    const started = await menuExtractorStartSourceDiscoveryJob('https://menumgelsin.com/visalcafe/menulerim');
    expect(started.ok).toBe(true);
    if (!started.ok) return;

    let finishedResult: unknown = null;
    for (let attempt = 0; attempt < 60; attempt += 1) {
      const poll = await menuExtractorPollJob(started.jobId);
      if (poll.status === 'failed' || poll.status === 'error') throw new Error(poll.error);
      if (poll.status === 'finished') {
        finishedResult = poll.result;
        break;
      }
      await new Promise((resolve) => setTimeout(resolve, 1_000));
    }

    expect(finishedResult).not.toBeNull();
    const outcome = parseDiscoveryOutcome(finishedResult);
    const items = normalizeExtractResult(finishedResult);
    expect(outcome).toEqual(expect.objectContaining({
      status: 'SOURCE_FOUND_ITEMS_FOUND',
      totalItems: 141,
      pricedItems: 141,
      missingPriceItems: 0,
      categoryCount: 21,
    }));
    expect(items).toHaveLength(141);
    expect(items).toEqual(expect.arrayContaining([
      expect.objectContaining({ category_name: 'MAKARNALAR', name: 'PENNE PESTO', price_cents: 25000 }),
      expect.objectContaining({ category_name: 'MAKARNALAR', name: 'KÖRİ SOSLU PENNE', price_cents: 25000 }),
      expect.objectContaining({ category_name: 'TOSTLAR', name: 'KARIŞIK TOST', price_cents: 19000 }),
      expect.objectContaining({ category_name: 'TOSTLAR', name: 'KAŞARLI TOST', price_cents: 18000 }),
    ]));
  });
});
