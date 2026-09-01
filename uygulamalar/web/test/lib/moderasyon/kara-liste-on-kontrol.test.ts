import { describe, expect, it } from 'vitest';
import { normalizeForModeration, matchesBlacklist } from '@/src/lib/moderasyon/kara-liste-on-kontrol';

describe('kara-liste-on-kontrol', () => {
  it('normalizes obfuscated characters', () => {
    expect(normalizeForModeration('4mk')).toBe('amk');
    expect(normalizeForModeration('ÇÖPLÜK')).toBe('copluk');
  });

  it('detects a blacklisted term regardless of case/spacing', () => {
    expect(matchesBlacklist('Bu bir SIKTIR yorumu', ['siktir'])).toBe(true);
    expect(matchesBlacklist('bu s i k t i r yorumu', ['siktir'])).toBe(true);
  });

  it('does not flag clean text', () => {
    expect(matchesBlacklist('gayet güzel bir mekan', ['siktir', 'amk'])).toBe(false);
  });

  it('handles an empty blacklist safely', () => {
    expect(matchesBlacklist('herhangi bir metin', [])).toBe(false);
  });
});
