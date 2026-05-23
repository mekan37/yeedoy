import { describe, expect, it } from 'vitest';
import { getTranslationValue } from '@/src/lib/menu-metinleri';

describe('menu-metinleri', () => {
  it('prefers exact locale matches', () => {
    const result = getTranslationValue({
      translations: [
        {
          id: '1',
          entity_type: 'item',
          entity_id: 'item-1',
          locale: 'tr',
          name: 'Kahve',
          description: 'Sicak',
          created_at: '2026-01-01T00:00:00Z',
        },
        {
          id: '2',
          entity_type: 'item',
          entity_id: 'item-1',
          locale: 'en',
          name: 'Coffee',
          description: 'Hot',
          created_at: '2026-01-01T00:00:00Z',
        },
      ],
      entityType: 'item',
      entityId: 'item-1',
      locale: 'en',
      field: 'name',
      fallback: 'Fallback',
    });

    expect(result).toBe('Coffee');
  });

  it('falls back to language prefix and then fallback value', () => {
    const result = getTranslationValue({
      translations: [
        {
          id: '1',
          entity_type: 'business',
          entity_id: 'business-1',
          locale: 'en-US',
          name: 'Bistro',
          description: null,
          created_at: '2026-01-01T00:00:00Z',
        },
      ],
      entityType: 'business',
      entityId: 'business-1',
      locale: 'en-GB',
      field: 'name',
      fallback: 'Fallback',
    });

    expect(result).toBe('Bistro');
    expect(
      getTranslationValue({
        translations: [],
        entityType: 'business',
        entityId: 'business-1',
        locale: 'tr',
        field: 'name',
        fallback: 'Fallback',
      }),
    ).toBe('Fallback');
  });
});
