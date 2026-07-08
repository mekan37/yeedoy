import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { FavorilerListesi, type FavIsletme } from './favoriler-listesi';

export const metadata: Metadata = {
  title: 'Favorilerim | Yeedoy',
  robots: { index: false, follow: false },
};

// ── Sidebar sabitler ─────────────────────────────────────────────────────────

const NAV_SIDEBAR = [
  { href: '/profil',          label: 'Profilim' },
  { href: '/favoriler',       label: 'Favorilerim', active: true },
  { href: '/onerilerim',      label: 'Yorumlarım' },
  { href: '/gelen-kutusu',    label: 'Bildirimlerim' },
  { href: '/profil/settings', label: 'Ayarlar' },
  { href: '/yardim',          label: 'Yardım & Destek' },
];

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
      .from('business_reviews')
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
      .from('business_reviews')
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
            <nav className="rounded-2xl border border-border bg-card shadow-yd1 overflow-hidden">
              {NAV_SIDEBAR.map(({ href, label, active }) => (
                <Link key={label} href={href}
                  className={`flex items-center gap-3 px-4 py-3 text-sm font-[800] border-b border-border last:border-0 transition-colors ${
                    active
                      ? 'bg-primary/8 text-primary'
                      : 'text-textStrong hover:bg-cardAlt hover:text-primary'
                  }`}>
                  {active && (
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" className="shrink-0 text-primary" aria-hidden="true">
                      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                    </svg>
                  )}
                  {label}
                </Link>
              ))}
              <button type="button"
                className="flex w-full items-center gap-3 px-4 py-3 text-sm font-[800] text-danger transition-colors hover:bg-danger/5">
                Çıkış Yap
              </button>
            </nav>

            {/* Premium card */}
            <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
              <div className="mb-1 flex items-center gap-2">
                <span className="text-lg" aria-hidden="true">👑</span>
                <p className="text-sm font-[900] text-amber-900">Yeedoy Premium</p>
              </div>
              <p className="mb-3 text-[12px] font-[700] leading-snug text-amber-700">
                Daha fazla ayrıcalık ve özel fırsatlar seni bekliyor!
              </p>
              <button type="button"
                className="flex h-9 w-full items-center justify-center rounded-xl border border-amber-300 bg-white text-[13px] font-[900] text-amber-700 transition hover:bg-amber-100">
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
