'use client';

import { useCallback, useMemo, useState } from 'react';
import Image from 'next/image';

type Category = { id: string; sort_order: number; name?: string | null };
type Item = {
  id: string;
  category_id: string;
  name?: string | null;
  description?: string | null;
  price_cents: number;
  is_available: boolean;
  image_url: string | null;
  tags: string[] | null;
};
type Translation = {
  entity_type: 'business' | 'category' | 'item';
  entity_id: string;
  locale: string;
  name: string;
  description: string | null;
};

export function PublicMenuClient({
  locale,
  showPrices,
  theme,
  categories,
  items,
  translations,
}: {
  locale: string;
  showPrices: boolean;
  theme: 'minimal' | 'bold';
  categories: Category[];
  items: Item[];
  translations: Translation[];
}) {
  const [query, setQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState<string | null>(categories[0]?.id ?? null);

  const categoryName = (id: string) =>
    translations.find((t) => t.entity_type === 'category' && t.entity_id === id && t.locale === locale)?.name ??
    categories.find((c) => c.id === id)?.name ??
    'Category';

  const itemName = useCallback(
    (id: string) =>
      translations.find((t) => t.entity_type === 'item' && t.entity_id === id && t.locale === locale)?.name ??
      items.find((i) => i.id === id)?.name ??
      'Item',
    [items, locale, translations],
  );

  const itemDescription = useCallback(
    (id: string) =>
      translations.find((t) => t.entity_type === 'item' && t.entity_id === id && t.locale === locale)?.description ??
      items.find((i) => i.id === id)?.description ??
      '',
    [items, locale, translations],
  );

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return items.filter((i) => {
      if (activeCategory && i.category_id !== activeCategory) return false;
      if (!q) return true;
      const text = `${itemName(i.id)} ${itemDescription(i.id)}`.toLowerCase();
      return text.includes(q);
    });
  }, [items, query, activeCategory, itemDescription, itemName]);

  return (
    <div className="space-y-4">
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={locale === 'tr' ? 'Menude ara...' : 'Search menu...'}
        className="w-full rounded-xl border border-slate-200 px-4 py-3"
      />

      <div className="sticky top-0 z-10 flex gap-2 overflow-x-auto bg-slate-50 py-2">
        {categories.map((c) => (
          <button
            key={c.id}
            onClick={() => setActiveCategory(c.id)}
            className={`rounded-full px-3 py-1.5 text-sm ${
              activeCategory === c.id
                ? theme === 'bold'
                  ? 'bg-slate-900 text-white'
                  : 'bg-emerald-700 text-white'
                : 'bg-white text-slate-600 border border-slate-200'
            }`}
          >
            {categoryName(c.id)}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {filtered.map((item) => {
          const imageUrl = normalizeImageUrl(item.image_url);
          return (
            <article
              key={item.id}
              className={`rounded-2xl border p-4 ${
                theme === 'bold' ? 'bg-slate-900 text-white border-slate-800' : 'bg-white border-slate-200'
              }`}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex min-w-0 items-start gap-3">
                  {imageUrl ? (
                    <Image
                      src={imageUrl}
                      alt={itemName(item.id)}
                      width={64}
                      height={64}
                      unoptimized
                      className="h-16 w-16 shrink-0 rounded-xl border border-slate-200 object-cover"
                    />
                  ) : null}
                  <div className="min-w-0">
                    <h3 className="truncate text-lg font-bold">{itemName(item.id)}</h3>
                    {itemDescription(item.id) && (
                      <p className={`mt-1 text-sm ${theme === 'bold' ? 'text-slate-300' : 'text-slate-600'}`}>
                        {itemDescription(item.id)}
                      </p>
                    )}
                    <div className="mt-2 flex flex-wrap gap-2">
                      {!item.is_available && (
                        <span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-700">
                          Not available
                        </span>
                      )}
                      {(item.tags ?? []).slice(0, 3).map((tag) => (
                        <span
                          key={tag}
                          className={`rounded-full px-2 py-0.5 text-xs ${
                            theme === 'bold' ? 'bg-slate-700 text-slate-100' : 'bg-slate-100 text-slate-600'
                          }`}
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
                {showPrices && <p className="text-lg font-extrabold">{(item.price_cents / 100).toFixed(2)} TL</p>}
              </div>
            </article>
          );
        })}
      </div>
    </div>
  );
}

function normalizeImageUrl(url: string | null | undefined): string | null {
  const value = String(url ?? '').trim();
  if (!value) return null;
  try {
    const parsed = new URL(value);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null;
    return parsed.toString();
  } catch {
    return null;
  }
}
