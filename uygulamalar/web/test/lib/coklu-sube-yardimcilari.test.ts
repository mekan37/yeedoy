import { describe, it, expect } from 'vitest';
import {
  branchMatchesTab,
  filterBranches,
  cityDistribution,
  type CokluSubeBranch,
} from '@/app/sahip/coklu-sube/coklu-sube-yardimcilari';

const BRANCHES: CokluSubeBranch[] = [
  {
    business_id: 'b1', name: 'No 18 Coffee - Merkez', branch_label: 'Merkez', city: 'Ankara',
    district: 'Çankaya', is_active: true, logo_url: null, chain_sort_order: 0, is_main_branch: true,
    views: 100, reservations: 10,
  },
  {
    business_id: 'b2', name: 'No 18 Coffee - Kadıköy', branch_label: 'Kadıköy', city: 'İstanbul',
    district: 'Kadıköy', is_active: true, logo_url: null, chain_sort_order: 1, is_main_branch: false,
    views: 50, reservations: 5,
  },
  {
    business_id: 'b3', name: 'No 18 Coffee - Alsancak', branch_label: 'Alsancak', city: 'İzmir',
    district: 'Konak', is_active: false, logo_url: null, chain_sort_order: 2, is_main_branch: false,
    views: 20, reservations: 0,
  },
];

describe('branchMatchesTab', () => {
  it('tumu her durumu kapsar', () => {
    expect(branchMatchesTab(BRANCHES[0], 'tumu')).toBe(true);
    expect(branchMatchesTab(BRANCHES[2], 'tumu')).toBe(true);
  });

  it('aktif sadece is_active=true olanları kapsar', () => {
    expect(branchMatchesTab(BRANCHES[0], 'aktif')).toBe(true);
    expect(branchMatchesTab(BRANCHES[2], 'aktif')).toBe(false);
  });

  it('pasif sadece is_active=false olanları kapsar', () => {
    expect(branchMatchesTab(BRANCHES[2], 'pasif')).toBe(true);
    expect(branchMatchesTab(BRANCHES[0], 'pasif')).toBe(false);
  });
});

describe('filterBranches', () => {
  it('arama metnine göre ada/etikete/şehre göre filtreler (case-insensitive)', () => {
    const result = filterBranches(BRANCHES, 'kadıköy', 'tumu');
    expect(result.map((b) => b.business_id)).toEqual(['b2']);
  });

  it('sekme ve arama birlikte AND mantığıyla uygulanır', () => {
    const result = filterBranches(BRANCHES, '', 'aktif');
    expect(result.map((b) => b.business_id).sort()).toEqual(['b1', 'b2']);
  });

  it('boş aramada sekmeye uyan tüm şubeleri döner', () => {
    const result = filterBranches(BRANCHES, '', 'tumu');
    expect(result).toHaveLength(3);
  });
});

describe('cityDistribution', () => {
  it('şehre göre sayarak azalan sırada döner', () => {
    const result = cityDistribution(BRANCHES);
    expect(result).toEqual([
      { city: 'Ankara', count: 1 },
      { city: 'İstanbul', count: 1 },
      { city: 'İzmir', count: 1 },
    ]);
  });

  it('aynı şehirdeki birden fazla şubeyi doğru sayar', () => {
    const twoInSameCity: CokluSubeBranch[] = [
      { ...BRANCHES[0], business_id: 'b4' },
      { ...BRANCHES[0], business_id: 'b5' },
    ];
    const result = cityDistribution(twoInSameCity);
    expect(result).toEqual([{ city: 'Ankara', count: 2 }]);
  });
});
