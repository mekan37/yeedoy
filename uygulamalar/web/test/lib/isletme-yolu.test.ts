import { describe, expect, it } from 'vitest';
import { isBusinessMenuPathKey, isUuid, normalizeBusinessMenuPathKey } from '@/src/lib/isletme-yolu';

describe('isletme-yolu', () => {
  it('accepts canonical slug style menu paths', () => {
    expect(isBusinessMenuPathKey('demo-cafe')).toBe(true);
    expect(isBusinessMenuPathKey('Demo-Cafe')).toBe(true);
  });

  it('accepts uuid fallback menu paths', () => {
    expect(isBusinessMenuPathKey('123e4567-e89b-42d3-a456-426614174000')).toBe(true);
    expect(isUuid('123e4567-e89b-42d3-a456-426614174000')).toBe(true);
  });

  it('rejects invalid business menu paths', () => {
    expect(isBusinessMenuPathKey('demo cafe')).toBe(false);
    expect(isBusinessMenuPathKey('../demo')).toBe(false);
  });

  it('normalizes path keys defensively', () => {
    expect(normalizeBusinessMenuPathKey(' Demo-Cafe ')).toBe('demo-cafe');
    expect(normalizeBusinessMenuPathKey('')).toBeNull();
  });
});
