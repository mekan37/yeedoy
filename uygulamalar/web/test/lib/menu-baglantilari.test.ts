import { describe, expect, it } from 'vitest';
import {
  buildBusinessMenuHref,
  buildMenuHref,
  normalizeBusinessMenuPathKey,
  resolveBusinessMenuPathKey,
} from '@/src/lib/menu-baglantilari';

describe('menu-baglantilari', () => {
  it('prefers public slug over legacy slug and id', () => {
    expect(
      resolveBusinessMenuPathKey({
        businessId: '123e4567-e89b-42d3-a456-426614174000',
        businessSlug: 'legacy-slug',
        businessPublicSlug: 'Public-Slug',
      }),
    ).toBe('public-slug');
  });

  it('falls back to business id when no slug is available', () => {
    expect(
      buildMenuHref({
        businessId: '123e4567-e89b-42d3-a456-426614174000',
        lang: 'tr',
        theme: 'bold',
      }),
    ).toBe('/m/123e4567-e89b-42d3-a456-426614174000?lang=tr&theme=bold');
  });

  it('builds canonical menu hrefs with the resolved public slug', () => {
    expect(
      buildBusinessMenuHref({
        business: {
          id: '123e4567-e89b-42d3-a456-426614174000',
          slug: 'legacy-slug',
          public_slug: 'demo-cafe',
        },
        itemId: '223e4567-e89b-42d3-a456-426614174000',
        lang: 'en',
        theme: 'minimal',
        preview: true,
      }),
    ).toBe('/m/demo-cafe/i/223e4567-e89b-42d3-a456-426614174000?lang=en&theme=minimal&preview=1');
  });

  it('normalizes menu path keys defensively', () => {
    expect(normalizeBusinessMenuPathKey(' Demo-Cafe ')).toBe('demo-cafe');
    expect(normalizeBusinessMenuPathKey('')).toBeNull();
  });
});
