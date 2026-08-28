import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { ProfilSidebarNav } from '@/src/ui/acik/profil-sidebar-nav';
import { YorumKarti, type YorumSatiri } from '@/src/ui/acik/yorum-karti';

export const metadata: Metadata = {
  title: 'Yorumlarım | Yeedoy',
  robots: { index: false, follow: false },
};

export default async function YorumlarimPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const yorumlarRes = await ((supabase as any)
    .from('reviews')
    .select('id, content, title, rating, overall_rating, created_at, businesses ( name, category, district, slug )')
    .eq('user_id', user!.id)
    .order('created_at', { ascending: false })
    .limit(100)) as { data: YorumSatiri[] | null };
  const yorumlar: YorumSatiri[] = yorumlarRes.data ?? [];

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <div className="flex gap-6 lg:items-start">

          {/* ── Sol sidebar ────────────────────────────────────────────── */}
          <aside className="hidden w-56 shrink-0 lg:block lg:sticky lg:top-20 lg:self-start">
            <ProfilSidebarNav active="/yorumlarim" />
          </aside>

          {/* ── Ana içerik ─────────────────────────────────────────────── */}
          <div className="min-w-0 flex-1">
            <div className="rounded-2xl border border-border bg-card p-5 shadow-yd1">
              <div className="mb-4 flex items-center justify-between">
                <h1 className="text-xl font-black text-textStrong">Yorumlarım</h1>
                <span className="text-[13px] font-bold text-muted">{yorumlar.length} yorum</span>
              </div>

              {yorumlar.length === 0 ? (
                <div className="flex flex-col items-center gap-3 py-14 text-center">
                  <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-cardAlt border border-border">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" className="text-muted" aria-hidden="true">
                      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                    </svg>
                  </div>
                  <div>
                    <p className="text-sm font-black text-textStrong">Henüz yorum yapmadın</p>
                    <p className="mt-0.5 text-[12px] font-bold text-muted">Gittiğin mekanları değerlendir, topluma katkıda bulun.</p>
                  </div>
                  <Link href="/kesif" className="mt-1 inline-flex h-9 items-center gap-1.5 rounded-xl bg-primary px-4 text-sm font-black text-white transition hover:brightness-110">
                    Mekan Keşfet
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                  </Link>
                </div>
              ) : (
                <div className="space-y-3">
                  {yorumlar.map((y) => (
                    <YorumKarti key={y.id} y={y} />
                  ))}
                </div>
              )}
            </div>
          </div>

        </div>
      </div>
    </main>
  );
}
