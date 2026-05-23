import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { AppSectionHeader } from '@/src/ui/bilesenler/uygulama-bolum-basligi';
import { BusinessTile } from '@/src/ui/bilesenler/isletme-karti';
import { CreateCollectionButton } from '@/src/ui/acik/eylem-istemcisi';

export const metadata: Metadata = {
  title: 'Favorilerim | Yeedoy',
  robots: { index: false, follow: false },
};

type BizInfo = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null;
  logo_url: string | null; is_verified?: boolean;
};

type FavRow = { business_id: string; businesses: BizInfo | null };

type Collection = {
  id: string;
  name: string;
  description: string | null;
  item_count: number;
  updated_at: string;
};

type TabKey = 'tumumu' | 'koleksiyonlar';

function formatDate(iso: string) {
  try {
    return new Date(iso).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });
  } catch {
    return '';
  }
}

export default async function FavoritesPage({
  searchParams,
}: {
  searchParams: Promise<{ tab?: string }>;
}) {
  const sp = await searchParams;
  const tab: TabKey = sp.tab === 'koleksiyonlar' ? 'koleksiyonlar' : 'tumumu';

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let list: FavRow[] = [];

  const TABLES = ['user_favorites', 'business_favorites'];
  for (const table of TABLES) {
    if (list.length > 0) break;
    try {
      const { data, error } = await (supabase as any)
        .from(table)
        .select('business_id, businesses(id, name, slug, category, city, logo_url, is_verified)')
        .eq('user_id', user!.id)
        .order('created_at', { ascending: false }) as { data: FavRow[] | null; error: { code?: string } | null };
      if (!error || error.code !== '42P01') {
        list = (data ?? []).filter((f) => f.businesses != null);
      }
    } catch { /* try next table */ }
  }

  // Fetch collections
  let collections: Collection[] = [];
  try {
    const { data } = await (supabase as any)
      .from('collections')
      .select('id, name, description, updated_at, item_count:collection_items(count)')
      .eq('user_id', user!.id)
      .order('updated_at', { ascending: false })
      .limit(20) as { data: Array<{ id: string; name: string; description: string | null; updated_at: string; item_count: Array<{ count: number }> }> | null };

    if (data) {
      collections = data.map((c) => ({
        id: c.id,
        name: c.name,
        description: c.description,
        updated_at: c.updated_at,
        item_count: c.item_count?.[0]?.count ?? 0,
      }));
    }
  } catch { /* collections table may not exist yet */ }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 pb-20 pt-10">

        {/* Back */}
        <Link href="/profil"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary">
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/>
          </svg>
          Profilime Dön
        </Link>

        <AppSectionHeader
          title="Favorilerim"
          subtitle={list.length > 0 ? `${list.length} işletme kaydedildi` : undefined}
          className="mb-6"
        />

        {/* Tab switcher */}
        <div className="mb-5 flex gap-1 rounded-2xl border border-border bg-cardAlt p-1">
          {([
            ['tumumu', 'Tümü', list.length] as const,
            ['koleksiyonlar', 'Koleksiyonlar', collections.length] as const,
          ]).map(([key, label, count]) => (
            <Link
              key={key}
              href={`?tab=${key}`}
              className={`flex flex-1 items-center justify-center gap-1.5 rounded-xl py-2 text-center text-sm font-[800] transition-all duration-[150ms] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 ${tab === key ? 'bg-card text-primary shadow-yd1' : 'text-muted hover:text-textStrong'}`}
            >
              {label}
              {count > 0 && (
                <span className={`rounded-full px-1.5 py-0.5 text-[10px] font-[900] leading-none ${tab === key ? 'bg-primary/10 text-primary' : 'bg-border text-muted'}`}>
                  {count}
                </span>
              )}
            </Link>
          ))}
        </div>

        {/* ── Tab: Tümü ── */}
        {tab === 'tumumu' && (
          <>
            {list.length === 0 ? (
              <div className="rounded-[20px] border border-border bg-card p-10 text-center">
                <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[var(--yd-color-primary-soft)]">
                  <svg viewBox="0 0 24 24" className="h-7 w-7 text-primary fill-none stroke-current" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                  </svg>
                </div>
                <p className="font-[900] text-textStrong mb-2">Henüz favori eklemediniz</p>
                <p className="mb-6 text-sm text-muted">Menüleri keşfedip favori işletmelerinizi buraya ekleyin.</p>
                <Link href="/kesif"
                  className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
                  style={{ background: 'var(--yd-gradient-primary)', boxShadow: 'var(--yd-shadow-primary)' }}>
                  Keşfetmeye Başla
                </Link>
              </div>
            ) : (
              <div className="flex flex-col gap-3">
                {list.map((fav) => {
                  const biz = fav.businesses!;
                  return (
                    <BusinessTile
                      key={fav.business_id}
                      slug={biz.slug}
                      name={biz.name}
                      category={biz.category ?? undefined}
                      subtitle={biz.city ?? undefined}
                      isVerified={biz.is_verified}
                    />
                  );
                })}
              </div>
            )}
          </>
        )}

        {/* ── Tab: Koleksiyonlar ── */}
        {tab === 'koleksiyonlar' && (
          <div>
            {/* Header row with create button */}
            <div className="mb-4 flex items-center justify-between gap-3">
              <p className="text-sm text-muted">
                {collections.length > 0
                  ? `${collections.length} koleksiyon`
                  : 'Henüz koleksiyon yok'}
              </p>
              <CreateCollectionButton />
            </div>

            {collections.length === 0 ? (
              <div className="rounded-[20px] border border-dashed border-border bg-card p-10 text-center">
                <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[var(--yd-color-primary-soft)]">
                  <svg viewBox="0 0 24 24" className="h-7 w-7 fill-current text-primary" aria-hidden="true">
                    <path d="M20 6h-2.18c.07-.44.18-.87.18-1.33C18 2.97 16.03 1 13.67 1c-1.33 0-2.42.57-3.17 1.47L10 3.1l-.5-.63C8.76 1.57 7.67 1 6.33 1 3.97 1 2 2.97 2 5.34c0 2.97 2.77 5.38 6.97 9.01L10 15.4l1.03-.97C15.23 10.72 18 8.31 18 5.34c0-.46-.11-.89-.18-1.34H20v14H4V8H2v12c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2z"/>
                  </svg>
                </div>
                <p className="font-[900] text-textStrong mb-2">İlk koleksiyonunuzu oluşturun</p>
                <p className="mb-6 text-sm text-muted">Favori işletmeleri temalı listelerde gruplandırın.</p>
                <CreateCollectionButton />
              </div>
            ) : (
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                {collections.map((col) => (
                  <div
                    key={col.id}
                    className="flex flex-col gap-2 rounded-[20px] border border-border bg-cardAlt p-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-yd2"
                  >
                    {/* Icon + name */}
                    <div className="flex items-start gap-3">
                      <div
                        className="flex h-12 w-12 shrink-0 items-center justify-center rounded-[14px] text-white"
                        style={{ background: 'linear-gradient(135deg, #5C1515 0%, #7F1D1D 100%)' }}
                        aria-hidden="true"
                      >
                        <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden="true">
                          <path d="M20 6h-2.18c.07-.44.18-.87.18-1.33C18 2.97 16.03 1 13.67 1c-1.33 0-2.42.57-3.17 1.47L10 3.1l-.5-.63C8.76 1.57 7.67 1 6.33 1 3.97 1 2 2.97 2 5.34c0 2.97 2.77 5.38 6.97 9.01L10 15.4l1.03-.97C15.23 10.72 18 8.31 18 5.34c0-.46-.11-.89-.18-1.34H20v14H4V8H2v12c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2z"/>
                        </svg>
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-[900] text-textStrong">{col.name}</p>
                        {col.description && (
                          <p className="mt-0.5 line-clamp-2 text-xs text-muted">{col.description}</p>
                        )}
                      </div>
                    </div>

                    {/* Footer: count + date */}
                    <div className="flex items-center justify-between gap-2 border-t border-border pt-2">
                      <span className="inline-flex items-center gap-1 rounded-full bg-[var(--yd-color-primary-soft)] px-2.5 py-1 text-xs font-[800] text-primary">
                        <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current" aria-hidden="true">
                          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                        </svg>
                        {col.item_count} işletme
                      </span>
                      <span className="text-[11px] text-muted">{formatDate(col.updated_at)}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
