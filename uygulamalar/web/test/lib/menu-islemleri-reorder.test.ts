import { describe, it, expect } from 'vitest';
import { reorderItem } from '@/app/sahip/menuler/[menuId]/duzenle/menu-islemleri';

describe('reorderItem', () => {
  it('bir fonksiyon olarak export edilir', () => {
    expect(typeof reorderItem).toBe('function');
  });
});
