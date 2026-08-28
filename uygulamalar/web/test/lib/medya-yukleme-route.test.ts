import { describe, it, expect } from 'vitest';
import { uploadSchema } from '@/app/sunucu/medya/yukleme/route';

describe('uploadSchema', () => {
  it('campaign tipini kabul eder', () => {
    const result = uploadSchema.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      type: 'campaign',
    });
    expect(result.success).toBe(true);
  });

  it('bilinmeyen bir tipi reddeder', () => {
    const result = uploadSchema.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      type: 'brochure',
    });
    expect(result.success).toBe(false);
  });

  it('geçersiz businessId (uuid değil) reddedilir', () => {
    const result = uploadSchema.safeParse({
      businessId: 'not-a-uuid',
      type: 'campaign',
    });
    expect(result.success).toBe(false);
  });
});
