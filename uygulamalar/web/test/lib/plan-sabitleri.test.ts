import { describe, expect, it } from 'vitest';
import { FEATURE_LABELS, TIER_LABELS, PLAN_FEATURE_KEYS } from '@/src/lib/plan/plan-sabitleri';

describe('plan-sabitleri', () => {
  it('her bilinen feature_key için bir Türkçe etiket tanımlar', () => {
    for (const key of PLAN_FEATURE_KEYS) {
      expect(FEATURE_LABELS[key], `FEATURE_LABELS eksik: ${key}`).toBeTruthy();
      expect(FEATURE_LABELS[key]).not.toBe(key);
    }
  });

  it('4 kademe için etiket tanımlar', () => {
    expect(Object.keys(TIER_LABELS).sort()).toEqual(['free', 'pro', 'standard', 'starter']);
  });

  it('sadakat_programi etiketi tanımlı (regresyon: önceden eksikti)', () => {
    expect(FEATURE_LABELS.sadakat_programi).toBe('Sadakat programı');
  });
});
