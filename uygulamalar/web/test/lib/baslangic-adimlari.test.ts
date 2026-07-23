import { describe, it, expect } from 'vitest';
import { computeOnboardingComplete } from '@/app/sahip/baslangic/baslangic-adimlari';

describe('computeOnboardingComplete', () => {
  it('hiçbir adım tamamlanmadıysa false döner', () => {
    expect(computeOnboardingComplete({ hasBusiness: false, hasPublishedMenu: false, hasQrCode: false, hasTeamMember: false })).toBe(false);
  });

  it('sadece bazı adımlar tamamlandıysa false döner', () => {
    expect(computeOnboardingComplete({ hasBusiness: true, hasPublishedMenu: true, hasQrCode: false, hasTeamMember: false })).toBe(false);
  });

  it('tüm adımlar tamamlandıysa true döner', () => {
    expect(computeOnboardingComplete({ hasBusiness: true, hasPublishedMenu: true, hasQrCode: true, hasTeamMember: true })).toBe(true);
  });
});
