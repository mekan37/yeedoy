export type Section = { id: string; title: string; sort_order: number };

export type Item = {
  id: string;
  name: string;
  description: string | null;
  image_url: string | null;
  price_cents: number;
  currency: string;
  is_available: boolean;
  section_id: string;
  sort_order: number;
  calories_min: number | null;
  portion_size: number | null;
  portion_unit: string | null;
  updated_at: string;
};

export function formatPrice(cents: number): string {
  return (cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2 }) + ' ₺';
}

export interface MenuStats {
  toplamKategori: number;
  toplamUrun: number;
  aktifUrun: number;
  pasifUrun: number;
  sonGuncelleme: string | null;
}

export function computeStats(sections: Section[], items: Item[]): MenuStats {
  const aktifUrun = items.filter((i) => i.is_available).length;
  let sonGuncelleme: string | null = null;
  for (const item of items) {
    if (sonGuncelleme === null || item.updated_at > sonGuncelleme) {
      sonGuncelleme = item.updated_at;
    }
  }
  return {
    toplamKategori: sections.length,
    toplamUrun: items.length,
    aktifUrun,
    pasifUrun: items.length - aktifUrun,
    sonGuncelleme,
  };
}

export type StatusFilter = 'all' | 'active' | 'passive';

export interface ItemFilters {
  search: string;
  sectionId: string | null;
  status: StatusFilter;
}

export function filterItems(items: Item[], filters: ItemFilters): Item[] {
  const search = filters.search.trim().toLowerCase();
  return items.filter((item) => {
    if (filters.sectionId && item.section_id !== filters.sectionId) return false;
    if (filters.status === 'active' && !item.is_available) return false;
    if (filters.status === 'passive' && item.is_available) return false;
    if (search) {
      const haystack = `${item.name} ${item.description ?? ''}`.toLowerCase();
      if (!haystack.includes(search)) return false;
    }
    return true;
  });
}

export type SortMode = 'manual' | 'name' | 'price' | 'updated';

export function sortItems(items: Item[], mode: SortMode): Item[] {
  const copy = [...items];
  switch (mode) {
    case 'name':
      return copy.sort((a, b) => a.name.localeCompare(b.name, 'tr'));
    case 'price':
      return copy.sort((a, b) => a.price_cents - b.price_cents);
    case 'updated':
      return copy.sort((a, b) => (a.updated_at < b.updated_at ? 1 : a.updated_at > b.updated_at ? -1 : 0));
    case 'manual':
    default:
      return copy.sort((a, b) => a.sort_order - b.sort_order);
  }
}
