import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { ProfilSidebarNav } from '@/src/ui/acik/profil-sidebar-nav';
import { FavorilerListesi, type FavIsletme } from './favoriler-listesi';

export const metadata: Metadata = {
  title: 'Favorilerim | Yeedoy',
  robots: { index: false, follow: false },
};

// ── Sayfa ────────────────────────────────────────────────────────────────────

export default async function FavoritesPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  // Favoriler
  let favoriler: FavIsletme[] = [];
  try {
    const { data } = await (supabase as any)
      .from('favorites')
      .select('business_id, created_at, businesses!favorites_business_id_fkey(id, name, slug, category, city, district, logo_url, cover_url, is_verified)')
      .eq('user_id', user!.id)
      .order('created_at', { ascending: false })
      .limit(200) as { data: FavIsletme[] | null };
    favoriler = (data ?? []).filter((f) => f.businesses != null);
  } catch { /* ignore */ }

  // Yorum sayısı
  let yorumSayisi = 0;
  try {
    const { count } = await (supabase as any)
      .from('reviews')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', user!.id) as { count: number | null };
    yorumSayisi = count ?? 0;
  } catch { /* ignore */ }

  // Ziyaret sayısı
  let ziyaretSayisi = 0;
  try {
    const { count } = await (supabase as any)
      .from('visits')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', user!.id) as { count: number | null };
    ziyaretSayisi = count ?? 0;
  } catch { /* ignore */ }

  // Beğenilen yorum sayısı
  let helpfulSayisi = 0;
  try {
    const { data: hrData } = await (supabase as any)
      .from('reviews')
      .select('helpful_count')
      .eq('user_id', user!.id) as { data: { helpful_count: number }[] | null };
    helpfulSayisi = (hrData ?? []).reduce((s, r) => s + (r.helpful_count ?? 0), 0);
  } catch { /* ignore */ }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <div className="flex gap-6 lg:items-start">

          {/* ── Sol sidebar ────────────────────────────────────────────── */}
          <aside className="hidden w-56 shrink-0 lg:block lg:sticky lg:top-20 lg:self-start space-y-3">
            <ProfilSidebarNav active="/favoriler" />

            {/* Premium card */}
            <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
              <div className="mb-1 flex items-center gap-2">
                <span className="text-lg" aria-hidden="true">👑</span>
                <p className="text-sm font-black text-amber-900">Yeedoy Premium</p>
              </div>
              <p className="mb-3 text-[12px] font-bold leading-snug text-amber-700">
                Daha fazla ayrıcalık ve özel fırsatlar seni bekliyor!
              </p>
              <button type="button"
                className="flex h-9 w-full items-center justify-center rounded-xl border border-amber-300 bg-white text-[13px] font-black text-amber-700 transition hover:bg-amber-100">
                Premium&apos;a Geç
              </button>
            </div>
          </aside>

          {/* ── Ana içerik ─────────────────────────────────────────────── */}
          <div className="min-w-0 flex-1">
            <FavorilerListesi
              favoriler={favoriler}
              yorumSayisi={yorumSayisi}
              ziyaretSayisi={ziyaretSayisi}
            helpfulSayisi={helpfulSayisi}
            />
          </div>

        </div>
      </div>
    </main>
  );
}
