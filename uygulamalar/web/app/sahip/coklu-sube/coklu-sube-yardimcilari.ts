export type CokluSubeBranch = {
  business_id: string;
  name: string;
  branch_label: string | null;
  city: string | null;
  district: string | null;
  is_active: boolean;
  logo_url: string | null;
  chain_sort_order: number;
  is_main_branch: boolean;
  views: number;
  reservations: number;
};

export type CokluSubeOverview = {
  chain_id: string | null;
  chain_name: string | null;
  branches: CokluSubeBranch[];
  total_views: number;
  total_reservations: number;
};

export type SubeTab = 'tumu' | 'aktif' | 'pasif';

export function branchMatchesTab(branch: CokluSubeBranch, tab: SubeTab): boolean {
  if (tab === 'tumu') return true;
  if (tab === 'aktif') return branch.is_active;
  return !branch.is_active;
}

export function filterBranches(branches: CokluSubeBranch[], search: string, tab: SubeTab): CokluSubeBranch[] {
  const q = search.trim().toLocaleLowerCase('tr');
  return branches
    .filter((b) => branchMatchesTab(b, tab))
    .filter((b) => {
      if (!q) return true;
      const haystack = `${b.name} ${b.branch_label ?? ''} ${b.city ?? ''}`.toLocaleLowerCase('tr');
      return haystack.includes(q);
    });
}

export function cityDistribution(branches: CokluSubeBranch[]): Array<{ city: string; count: number }> {
  const counts = new Map<string, number>();
  for (const b of branches) {
    const city = b.city ?? 'Bilinmiyor';
    counts.set(city, (counts.get(city) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .map(([city, count]) => ({ city, count }))
    .sort((a, b) => b.count - a.count);
}
