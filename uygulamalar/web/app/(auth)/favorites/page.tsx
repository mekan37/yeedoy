import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { AppSectionHeader } from '@/src/ui/components/app-section-header';
import { BusinessTile } from '@/src/ui/components/business-tile';

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

export default async function FavoritesPage() {
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

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 pb-20 pt-10">

        {/* Back */}
        <Link href="/profile"
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

        {list.length === 0 ? (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[var(--yd-color-primary-soft)]">
              <svg viewBox="0 0 24 24" className="h-7 w-7 text-primary fill-none stroke-current" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
              </svg>
            </div>
            <p className="font-[900] text-textStrong mb-2">Henüz favori eklemediniz</p>
            <p className="mb-6 text-sm text-muted">Menüleri keşfedip favori işletmelerinizi buraya ekleyin.</p>
            <Link href="/discover"
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
      </div>
    </main>
  );
}
