import type Supercluster from 'supercluster';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

export function toGeoJSONPoints(
  businesses: HaritaIsletme[],
): Array<Supercluster.PointFeature<HaritaIsletme>> {
  return businesses.map((b) => ({
    type: 'Feature' as const,
    properties: b,
    geometry: { type: 'Point' as const, coordinates: [b.lng, b.lat] },
  }));
}

export type ClusterSizeTier = 'sm' | 'md' | 'lg';

export function clusterSizeTier(count: number): ClusterSizeTier {
  if (count < 10) return 'sm';
  if (count < 50) return 'md';
  return 'lg';
}
