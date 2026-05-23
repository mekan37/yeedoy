import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import {
  ADMIN_SEARCH_CATEGORY_BADGES,
  ADMIN_SEARCH_CATEGORY_LABELS,
  normalizeAdminSearchType,
  searchAdminIndex,
  type AdminSearchResult,
} from '@/src/lib/veri/admin/yonetici-arama';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';

export const metadata: Metadata = {
  title: 'Arama | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ q?: string; type?: string }> };

const TYPE_FILTERS = [
  { value: 'businesses', label: 'İşletmeler' },
  { value: 'users', label: 'Kullanıcılar' },
  { value: 'all', label: 'Tümü' },
];

export default async function AdminSearchPage({ searchParams }: Props) {
  const { q: rawQ = '', type: rawType = 'businesses' } = await searchParams;
  const q = rawQ.trim();
  const type = normalizeAdminSearchType(rawType);
  const supabase = await createSupabaseServerClient();
  const serviceClient = createSupabaseServiceClient();

  let results: AdminSearchResult[] = [];

  if (q.length >= 2) {
    results = await searchAdminIndex((serviceClient ?? supabase) as any, q, {
      type,
      limit: 30,
    });
  }

  const groupedResults = results.reduce<Record<string, AdminSearchResult[]>>((acc, item) => {
    const key = item.category || 'other';
    acc[key] = [...(acc[key] ?? []), item];
    return acc;
  }, {});
  const totalResults = results.length;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Admin"
        title="Arama"
        description={q ? `"${q}" için ${totalResults} sonuç` : 'Platform genelinde arama yapın'}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-4">
          <form method="get" className="flex flex-wrap gap-3">
            <input
              name="q"
              defaultValue={q}
              placeholder="İşletme adı, kullanıcı, şehir..."
              autoFocus
              className="min-h-11 flex-1 rounded-xl border border-border bg-card px-4 py-2.5 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
            <div className="flex flex-wrap gap-1">
              {TYPE_FILTERS.map(({ value, label }) => (
                <button
                  key={value}
                  type="submit"
                  name="type"
                  value={value}
                  className={`min-h-11 rounded-xl px-3 py-2 text-xs font-[700] transition-colors ${
                    type === value
                      ? 'bg-primary text-white'
                      : 'border border-border bg-card text-muted hover:text-textStrong'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
            <button
              type="submit"
              name="type"
              value={type}
              className="min-h-11 rounded-xl bg-primary px-4 py-2 text-sm font-[700] text-white transition-opacity hover:opacity-90"
            >
              Ara
            </button>
          </form>

          {q.length < 2 && (
            <p className="py-8 text-center text-sm text-muted">En az 2 karakter girin.</p>
          )}

          {Object.entries(groupedResults).map(([category, items]) => (
            <PanelBolumKarti key={category} title={`${ADMIN_SEARCH_CATEGORY_LABELS[category] ?? 'Diğer'} (${items.length})`} noPadding>
              <ul className="divide-y divide-border">
                {items.map((item) => (
                  <li key={`${item.category}-${item.item_id}`}>
                    <Link
                      href={item.href}
                      className="flex items-center justify-between gap-4 px-5 py-3 transition-colors hover:bg-black/[0.02]"
                    >
                      <div className="min-w-0">
                        <p className="truncate font-[700] text-textStrong">{item.title}</p>
                        <p className="truncate text-xs text-muted">{item.subtitle}</p>
                      </div>
                      <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-[700] ${ADMIN_SEARCH_CATEGORY_BADGES[item.category] ?? 'bg-zinc-100 text-zinc-600'}`}>
                        {ADMIN_SEARCH_CATEGORY_LABELS[item.category] ?? item.category}
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            </PanelBolumKarti>
          ))}

          {q.length >= 2 && totalResults === 0 && (
            <PanelEmptyState
              icon={<SearchIcon />}
              title="Sonuç bulunamadı"
              description={`"${q}" için sonuç yok.`}
            />
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function SearchIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></svg>;
}
