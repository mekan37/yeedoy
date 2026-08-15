import { describe, it, expect } from 'vitest';
import { epostaKampanyaGovdesi } from '@/app/sunucu/sahip/eposta-kampanya/sema';

describe('epostaKampanyaGovdesi', () => {
  it('geçerli bir gövdeyi kabul eder', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      subject: 'Yeni Kampanya',
      body: 'Merhaba, size özel bir teklifimiz var.',
      targetSegment: 'tag:VIP',
    });
    expect(result.success).toBe(true);
  });

  it('boş subject reddedilir', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      subject: '',
      body: 'Merhaba',
      targetSegment: 'all_followers',
    });
    expect(result.success).toBe(false);
  });

  it('geçersiz businessId (uuid değil) reddedilir', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: 'not-a-uuid',
      subject: 'Test',
      body: 'Merhaba',
      targetSegment: 'all_followers',
    });
    expect(result.success).toBe(false);
  });
});
