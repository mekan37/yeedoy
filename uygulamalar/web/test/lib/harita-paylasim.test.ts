import { describe, expect, it } from 'vitest';
import { buildClusterBadgeEl } from '@/src/lib/harita-paylasim';

describe('buildClusterBadgeEl', () => {
  it('renders the count as text content', () => {
    const el = buildClusterBadgeEl(24);
    expect(el.textContent).toBe('24');
  });

  it('tags the element with a stable test id for e2e targeting', () => {
    const el = buildClusterBadgeEl(5);
    expect(el.dataset.testid).toBe('harita-cluster');
  });

  it('sizes large clusters (>=50) bigger than small clusters (<10)', () => {
    const small = buildClusterBadgeEl(3);
    const large = buildClusterBadgeEl(120);
    const smallWidth = parseInt(small.style.width, 10);
    const largeWidth = parseInt(large.style.width, 10);
    expect(largeWidth).toBeGreaterThan(smallWidth);
  });
});
