import rawCatalog from '@/src/data/yemek.v4.json';

type RawCatalog = {
  categories?: Array<{
    id?: string;
    name?: string;
    items?: Array<{
      name?: string;
      slug?: string;
      aliases?: string[];
      tags?: string[];
    }>;
  }>;
};

export type MenuCatalogHit = {
  id: number;
  name: string;
  categoryId: string;
  categoryName: string;
  slug: string;
  tags: string[];
};

type IndexedItem = MenuCatalogHit & { searchText: string };

let cache: IndexedItem[] | null = null;

export function searchMenuCatalog(query: string, limit = 12): MenuCatalogHit[] {
  const q = normalizeText(query);
  if (q.length < 2) return [];
  const index = getCatalogIndex();

  const scored: Array<{ score: number; item: IndexedItem }> = [];
  for (const item of index) {
    const score = scoreMatch(item.searchText, q);
    if (score <= 0) continue;
    scored.push({ score, item });
  }

  scored.sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name, 'tr'));
  return scored.slice(0, limit).map(({ item: { searchText, ...rest } }) => rest);
}

function getCatalogIndex(): IndexedItem[] {
  if (cache) return cache;
  const parsed = rawCatalog as RawCatalog;
  const items: IndexedItem[] = [];
  let seq = 1;

  for (const category of parsed.categories ?? []) {
    const categoryId = (category.id ?? '').trim();
    const categoryName = fixMojibake(category.name ?? '').trim();
    for (const item of category.items ?? []) {
      const name = fixMojibake(item.name ?? '').trim();
      if (!name) continue;
      const aliases = (item.aliases ?? [])
        .map((x) => fixMojibake(x ?? '').trim())
        .filter(Boolean);
      const slug = fixMojibake(item.slug ?? '').trim();
      const tags = (item.tags ?? []).map((x) => String(x));
      const searchText = normalizeText([name, ...aliases, slug, ...tags].join(' '));
      items.push({
        id: seq++,
        name,
        categoryId,
        categoryName,
        slug,
        tags,
        searchText,
      });
    }
  }

  cache = items;
  return items;
}

function scoreMatch(haystack: string, query: string): number {
  if (haystack === query) return 120;
  if (haystack.startsWith(query)) return 95;
  if (haystack.includes(` ${query}`)) return 80;
  if (haystack.includes(query)) return 65;
  return 0;
}

function normalizeText(input: string): string {
  const fixed = fixMojibake(input).toLocaleLowerCase('tr');
  return fixed
    .replace(/ı/g, 'i')
    .replace(/ğ/g, 'g')
    .replace(/ş/g, 's')
    .replace(/ç/g, 'c')
    .replace(/ö/g, 'o')
    .replace(/ü/g, 'u')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function fixMojibake(input: string): string {
  if (!input) return '';
  if (!/[ÃÄÅ]/.test(input)) return input;
  try {
    return Buffer.from(input, 'latin1').toString('utf8');
  } catch {
    return input;
  }
}
