import { describe, expect, it } from 'vitest';
import { clusterSizeTier, toGeoJSONPoints } from '@/src/lib/harita-cluster';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

const isletme = (overrides: Partial<HaritaIsletme> = {}): HaritaIsletme => ({
  id: 'id-1',
  name: 'Test İşletme',
  slug: 'test-isletme',
  category: 'Kafe',
  lat: 39.9,
  lng: 32.8,
  avg_rating: 4.5,
  logo_url: null,
  cover_url: null,
  is_verified: false,
  is_open_now: null,
  ...overrides,
});

describe('harita-cluster', () => {
  describe('toGeoJSONPoints', () => {
    it('converts businesses into GeoJSON point features with lng/lat coordinates', () => {
      const businesses = [isletme({ id: 'a', lat: 39.9, lng: 32.8 })];
      const points = toGeoJSONPoints(businesses);

      expect(points).toHaveLength(1);
      expect(points[0].type).toBe('Feature');
      expect(points[0].geometry).toEqual({ type: 'Point', coordinates: [32.8, 39.9] });
      expect(points[0].properties).toEqual(businesses[0]);
    });

    it('returns an empty array for an empty input', () => {
      expect(toGeoJSONPoints([])).toEqual([]);
    });
  });

  describe('clusterSizeTier', () => {
    it('returns sm for counts under 10', () => {
      expect(clusterSizeTier(1)).toBe('sm');
      expect(clusterSizeTier(9)).toBe('sm');
    });

    it('returns md for counts between 10 and 49', () => {
      expect(clusterSizeTier(10)).toBe('md');
      expect(clusterSizeTier(49)).toBe('md');
    });

    it('returns lg for counts 50 and above', () => {
      expect(clusterSizeTier(50)).toBe('lg');
      expect(clusterSizeTier(1000)).toBe('lg');
    });
  });
});
