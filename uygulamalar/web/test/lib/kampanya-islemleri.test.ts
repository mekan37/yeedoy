import { describe, it, expect } from 'vitest';
import { KampanyaSemasi } from '@/app/sahip/pazarlama/kampanyalar/kampanya-islemleri';

describe('KampanyaSemasi', () => {
  const base = {
    business_id: '11111111-1111-4111-8111-111111111111',
    title: 'Kahvaltıda %20 İndirim',
    type: 'discount' as const,
    status: 'active' as const,
  };

  it('image_url olmadan kabul eder (opsiyonel)', () => {
    const result = KampanyaSemasi.safeParse(base);
    expect(result.success).toBe(true);
  });

  it('geçerli bir image_url kabul eder', () => {
    const result = KampanyaSemasi.safeParse({
      ...base,
      image_url: 'https://example.supabase.co/storage/v1/object/public/menu-media/businesses/x/campaigns/y.webp',
    });
    expect(result.success).toBe(true);
  });

  it('null image_url kabul eder (görsel kaldırıldığında)', () => {
    const result = KampanyaSemasi.safeParse({ ...base, image_url: null });
    expect(result.success).toBe(true);
  });

  it('geçersiz bir image_url (url formatında değil) reddedilir', () => {
    const result = KampanyaSemasi.safeParse({ ...base, image_url: 'not-a-url' });
    expect(result.success).toBe(false);
  });
});
