import { describe, it, expect } from 'vitest';
import {
  bulkSetAvailability,
  bulkMoveSection,
  bulkDeleteItems,
  duplicateItem,
} from '@/app/sahip/menuler/[menuId]/duzenle/menu-islemleri';

describe('toplu işlem action ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof bulkSetAvailability).toBe('function');
    expect(typeof bulkMoveSection).toBe('function');
    expect(typeof bulkDeleteItems).toBe('function');
    expect(typeof duplicateItem).toBe('function');
  });

  it('boş itemIds listesiyle bulkSetAvailability erken döner (DB çağrısı yapmadan)', async () => {
    const result = await bulkSetAvailability([], 'menu-1', true);
    expect(result).toBeNull();
  });

  it('boş itemIds listesiyle bulkMoveSection erken döner', async () => {
    const result = await bulkMoveSection([], 'menu-1', 'section-1');
    expect(result).toBeNull();
  });

  it('boş itemIds listesiyle bulkDeleteItems erken döner', async () => {
    const result = await bulkDeleteItems([], 'menu-1');
    expect(result).toBeNull();
  });
});
