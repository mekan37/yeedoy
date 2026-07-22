import type { Metadata } from 'next';
import Link from 'next/link';
import { Heart, MessageCircle, MapPin, ThumbsUp, Users, Bell } from 'lucide-react';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { FavoriKarusel, type FavoriIsletme } from './favori-karusel';
import { AvatarYukleme } from './avatar-yukleme';

export const metadata: Metadata = {
  title: 'Profilim | Yeedoy',
  robots: { index: false, follow: false },
};

// ── Tipler ────────────────────────────────────────────────────────────────────

type Profile = {
  display_name: string | null; avatar_url: string | null;
  bio: string | null; city: string | null; created_at: string;
};

type Stats = {
  reviews_count: number; helpful_received: number;
  favorites_count: number; visits_count: number; contribution_score: number;
};

type YorumSatiri = {
  id: string; content: string | null; title: string | null;
  rating: number | null; overall_rating: number | null; created_at: string;
  businesses: { name: string; category: string | null; district: string | null; slug: string | null } | null;
};

// ── Sabitler ──────────────────────────────────────────────────────────────────

const AYLAR = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

const NAV_ITEMS = [
  { href: '/profil',          label: 'Profilim',        icon: <UserIcon /> },
  { href: '/favoriler',       label: 'Favorilerim',     icon: <HeartIcon /> },
  { href: '/onerilerim',      label: 'Önerilerim',      icon: <LightbulbIcon /> },
  { href: '/gelen-kutusu',    label: 'Bildirimlerim',   icon: <BellIcon /> },
  { href: '/profil/settings', label: 'Ayarlar',         icon: <SettingsIcon /> },
  { href: '/yardim',          label: 'Yardım & Destek', icon: <HelpIcon /> },
];

const HESAP_AYARLARI = [
  { href: '/profil/settings',         label: 'Kişisel Bilgilerim' },
  { href: '/bildirim-tercihleri',     label: 'Bildirim Tercihleri' },
  { href: '/yasal/gizlilik-ayarlari', label: 'Gizlilik Ayarları' },
  { href: '/hesap-sil',               label: 'Hesabımı Sil' },
];

// ── Yardımcılar ───────────────────────────────────────────────────────────────

function formatUyelik(iso: string): string {
  const d = new Date(iso);
  return `${AYLAR[d.getMonth()]} ${d.getFullYear()}'den beri üye`;
}

function formatZaman(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const gun = Math.floor(diff / 86_400_000);
  if (gun === 0) return 'Bugün';
  if (gun === 1) return 'Dün';
  if (gun < 7) return `${gun} gün önce`;
  if (gun < 30) return `${Math.floor(gun / 7)} hafta önce`;
  if (gun < 365) return `${Math.floor(gun / 30)} ay önce`;
  return `${Math.floor(gun / 365)} yıl önce`;
}

function uyeSuresi(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const gun = Math.floor(diff / 86_400_000);
  if (gun < 30) return `${gun} gün`;
  if (gun < 365) return `${Math.floor(gun / 30)} ay`;
  const yil = Math.floor(gun / 365);
  const kalanAy = Math.floor((gun % 365) / 30);
  return kalanAy > 0 ? `${yil} yıl ${kalanAy} ay` : `${yil} yıl`;
}

// ── Ana sayfa ─────────────────────────────────────────────────────────────────

export default async function ProfilPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const [profileRes, statsRes, followersRes, followingRes] = await Promise.all([
    (supabase as any).from('user_profiles').select('display_name, avatar_url, bio, city, created_at').eq('user_id', user!.id).maybeSingle() as Promise<{ data: Profile | null }>,
    (supabase as any).rpc('get_my_profile_stats') as Promise<{ data: Stats[] | null }>,
    (supabase as any).from('user_follows').select('id', { count: 'exact', head: true }).eq('followed_id', user!.id) as Promise<{ count: number | null }>,
    (supabase as any).from('user_follows').select('id', { count: 'exact', head: true }).eq('follower_id', user!.id) as Promise<{ count: number | null }>,
  ]);

  const profile = profileRes.data;
  const stats: Stats = statsRes.data?.[0] ?? { reviews_count: 0, helpful_received: 0, favorites_count: 0, visits_count: 0, contribution_score: 0 };
  const takipci = followersRes.count ?? 0;
  const takip = followingRes.count ?? 0;

  // Son yorumlar
  const yorumlarRes = await ((supabase as any)
    .from('business_reviews')
    .select('id, content, title, rating, overall_rating, created_at, businesses ( name, category, district, slug )')
    .eq('user_id', user!.id)
    .order('created_at', { ascending: false })
    .limit(4)) as { data: YorumSatiri[] | null };
  const yorumlar: YorumSatiri[] = yorumlarRes.data ?? [];

  // Favori işletmeler
  const favIdlerRes = await ((supabase as any)
    .from('favorites')
    .select('business_id')
    .eq('user_id', user!.id)
    .order('created_at', { ascending: false })
    .limit(10)) as { data: { business_id: string }[] | null };

  let favIsletmeler: FavoriIsletme[] = [];
  const ids = (favIdlerRes.data ?? []).map((r: { business_id: string }) => r.business_id);
  if (ids.length > 0) {
    const bizRes = await ((supabase as any)
      .from('businesses')
      .select('id, name, category, district, slug, logo_url, cover_url')
      .in('id', ids)
      .eq('is_active', true)) as { data: FavoriIsletme[] | null };
    favIsletmeler = bizRes.data ?? [];
  }

  // Hesaplamalar
  const displayName = profile?.display_name ?? 'Kullanıcı';
  const initials = displayName[0]?.toUpperCase() ?? 'U';
  const memberSince = profile?.created_at ? formatUyelik(profile.created_at) : null;
  const sure = profile?.created_at ? uyeSuresi(profile.created_at) : null;

  const STAT_SATIRLARI = [
    { value: stats.favorites_count,  label: 'Favori Mekan',    icon: Heart },
    { value: stats.reviews_count,    label: 'Yorum',            icon: MessageCircle },
    { value: stats.visits_count,     label: 'Ziyaret Edildi',   icon: MapPin },
    { value: stats.helpful_received, label: 'Beğeni',           icon: ThumbsUp },
    { value: takipci,                label: 'Takipçi',          icon: Users },
  ];

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <div className="flex gap-6 lg:items-start">

          {/* ── Sol sidebar (desktop) ───────────────────────────────────── */}
          <aside className="hidden w-60 shrink-0 lg:block lg:sticky lg:top-20 lg:self-start space-y-4">

            {/* Avatar + isim */}
            <div className="rounded-2xl border border-border bg-card p-5 shadow-yd1 text-center">
              <div className="flex justify-center">
                <div className="h-16 w-16 overflow-hidden rounded-full border-2 border-primary/20 bg-primary/10 shadow-yd1">
                  {profile?.avatar_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={profile.avatar_url} alt={displayName} className="h-full w-full object-cover" />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center text-xl font-[900] text-primary">{initials}</div>
                  )}
                </div>
              </div>
              <p className="mt-3 text-sm font-[900] text-textStrong truncate">{displayName}</p>
              <p className="mt-0.5 text-xs font-[700] text-muted truncate">{user!.email}</p>
              {sure && (
                <p className="mt-1.5 text-[11px] font-[700] text-muted">{sure} süredir üye</p>
              )}
            </div>

            {/* Nav */}
            <nav className="rounded-2xl border border-border bg-card shadow-yd1 overflow-hidden">
              {NAV_ITEMS.map(({ href, label, icon }) => (
                <Link key={href} href={href}
                  className="flex items-center gap-3 px-4 py-3 text-sm font-[800] text-textStrong transition-colors hover:bg-cardAlt hover:text-primary border-b border-border last:border-0">
                  <span className="w-5 shrink-0 text-muted">{icon}</span>
                  {label}
                </Link>
              ))}
              <button type="button"
                className="flex w-full items-center gap-3 px-4 py-3 text-sm font-[800] text-danger transition-colors hover:bg-danger/5">
                <span className="w-5 shrink-0"><LogoutIcon /></span>
                Çıkış Yap
              </button>
            </nav>

            {/* Davet et kartı */}
            <div className="rounded-2xl border border-primary/20 bg-primary/5 p-5 shadow-yd1">
              <div className="text-center mb-3">
                <div className="mx-auto mb-2 text-3xl">🎁</div>
                <p className="text-sm font-[900] text-textStrong">Arkadaşlarını Davet Et</p>
                <p className="mt-1 text-[12px] font-[700] text-muted leading-snug">Arkadaşlarını davet et, birlikte keşfet!</p>
              </div>
              <button type="button"
                className="flex h-10 w-full items-center justify-center rounded-xl bg-primary text-sm font-[900] text-white transition hover:brightness-110">
                Davet Et →
              </button>
            </div>
          </aside>

          {/* ── Ana içerik ──────────────────────────────────────────────── */}
          <div className="min-w-0 flex-1 space-y-5">

            {/* Profil başlık kartı */}
            <div className="rounded-2xl border border-border bg-card p-6 shadow-yd1">
              <div className="flex flex-col gap-5 sm:flex-row sm:items-start">

                {/* Sol: avatar + bilgi */}
                <div className="flex flex-1 items-start gap-4">
                  {/* Avatar — tıklanabilir upload */}
                  <AvatarYukleme
                    userId={user!.id}
                    avatarUrl={profile?.avatar_url ?? null}
                    displayName={displayName}
                    initials={initials}
                    size="lg"
                  />

                  {/* Bilgi */}
                  <div className="min-w-0 flex-1">
                    <h1 className="text-xl font-[900] text-textStrong">{displayName}</h1>
                    <div className="mt-1.5 flex flex-wrap items-center gap-x-4 gap-y-1 text-[13px] font-[700] text-muted">
                      {profile?.city && (
                        <span className="flex items-center gap-1">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                          {profile.city}
                        </span>
                      )}
                      {memberSince && (
                        <span className="flex items-center gap-1">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                          {memberSince}
                        </span>
                      )}
                    </div>
                    {profile?.bio && (
                      <p className="mt-2 text-[13px] font-[700] leading-relaxed text-text">{profile.bio}</p>
                    )}
                    <Link href="/profil/settings"
                      className="mt-3 inline-flex items-center gap-1.5 rounded-xl border border-border bg-cardAlt px-4 py-2 text-sm font-[900] text-textStrong transition hover:border-primary/30 hover:text-primary shadow-yd1">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                      Profili Düzenle
                    </Link>
                  </div>
                </div>

                {/* Sağ: Hakkımda kartı */}
                <div className="w-full rounded-2xl border border-border bg-cardAlt p-4 shadow-yd1 sm:w-52 shrink-0 space-y-3">
                  <p className="text-[11px] font-[900] uppercase tracking-wide text-muted">Hesap Bilgileri</p>

                  <div className="flex items-center gap-2 text-[12px] font-[700]">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="shrink-0 text-muted" aria-hidden="true"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                    <span className="truncate text-text">{user!.email}</span>
                  </div>

                  {profile?.city && (
                    <div className="flex items-center gap-2 text-[12px] font-[700]">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="shrink-0 text-muted" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                      <span className="text-text">{profile.city}</span>
                    </div>
                  )}

                  {memberSince && (
                    <div className="flex items-center gap-2 text-[12px] font-[700]">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="shrink-0 text-muted" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                      <span className="text-text">{sure} üye</span>
                    </div>
                  )}

                  <div className="pt-1 border-t border-border">
                    <p className="text-[11px] font-[700] text-muted">
                      {!profile?.bio ? (
                        <Link href="/profil/settings" className="text-primary hover:underline font-[900]">Biyografi ekle →</Link>
                      ) : (
                        <span className="line-clamp-3 leading-snug text-text">{profile.bio}</span>
                      )}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* İstatistik satırı */}
            <div className="grid grid-cols-3 gap-3 sm:grid-cols-5">
              {STAT_SATIRLARI.map(({ value, label, icon: StatIcon }) => (
                <div key={label} className="flex flex-col items-center rounded-2xl border border-border bg-card py-4 shadow-yd1 transition hover:shadow-yd2">
                  <div className="mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-cardAlt">
                    <StatIcon className="h-5 w-5" aria-hidden="true" />
                  </div>
                  <p className="text-xl font-[900] text-textStrong tabular-nums">{value}</p>
                  <p className="mt-0.5 text-[11px] font-[700] text-muted">{label}</p>
                </div>
              ))}
            </div>

            {/* Favori mekanlarım */}
            <div className="rounded-2xl border border-border bg-card p-5 shadow-yd1">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-base font-[900] text-textStrong">Favori Mekanlarım</h2>
                <Link href="/favoriler" className="text-[13px] font-[900] text-primary hover:underline">Tümünü Gör</Link>
              </div>
              <FavoriKarusel isletmeler={favIsletmeler} />
            </div>

            {/* Alt iki kolon */}
            <div className="flex flex-col gap-5 lg:flex-row lg:items-start">

              {/* Son yorumlarım */}
              <div className="flex-[3] rounded-2xl border border-border bg-card p-5 shadow-yd1">
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="text-base font-[900] text-textStrong">Son Yorumlarım</h2>
                  <Link href="/onerilerim" className="text-[13px] font-[900] text-primary hover:underline">Tümünü Gör</Link>
                </div>

                {yorumlar.length === 0 ? (
                  <div className="flex flex-col items-center gap-3 py-10 text-center">
                    <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-cardAlt border border-border">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" className="text-muted" aria-hidden="true">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                      </svg>
                    </div>
                    <div>
                      <p className="text-sm font-[900] text-textStrong">Henüz yorum yapmadın</p>
                      <p className="mt-0.5 text-[12px] font-[700] text-muted">Gittiğin mekanları değerlendir, topluma katkıda bulun.</p>
                    </div>
                    <Link href="/kesif" className="mt-1 inline-flex h-9 items-center gap-1.5 rounded-xl bg-primary px-4 text-sm font-[900] text-white transition hover:brightness-110">
                      Mekan Keşfet
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                    </Link>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {yorumlar.map((y) => {
                      const b = y.businesses;
                      const bizHref = b?.slug ? `/isletme/${b.slug}` : '/kesif';
                      const rating = y.rating ?? 0;
                      const ratingColor = rating >= 4
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        : rating === 3
                        ? 'bg-amber-50 text-amber-700 border-amber-200'
                        : rating > 0
                        ? 'bg-red-50 text-red-600 border-red-200'
                        : 'bg-cardAlt text-muted border-border';
                      return (
                        <div key={y.id} className="rounded-2xl border border-border bg-cardAlt overflow-hidden transition hover:border-primary/20 hover:shadow-yd1">
                          {/* Header */}
                          <div className="flex items-center gap-3 px-4 py-3 bg-card border-b border-border/60">
                            {/* Rating badge */}
                            <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border text-base font-[900] ${ratingColor}`}>
                              {rating > 0 ? rating : '—'}
                            </div>
                            {/* Stars + date */}
                            <div className="min-w-0 flex-1">
                              <div className="flex items-center gap-0.5">
                                {Array.from({ length: 5 }, (_, i) => (
                                  <svg key={i} width="13" height="13" viewBox="0 0 24 24"
                                    fill={i < rating ? '#f59e0b' : '#e2e8f0'} aria-hidden="true">
                                    <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                                  </svg>
                                ))}
                                <span className="ml-1.5 text-[11px] font-[700] text-muted">{formatZaman(y.created_at)}</span>
                              </div>
                            </div>
                            {/* Business link */}
                            <Link href={bizHref} className="shrink-0 text-right group max-w-[130px]">
                              <p className="text-[12px] font-[900] text-textStrong group-hover:text-primary transition-colors leading-tight line-clamp-1">{b?.name ?? 'İşletme'}</p>
                              {(b?.category || b?.district) && (
                                <p className="text-[10px] font-[700] text-muted leading-tight line-clamp-1">{[b?.category, b?.district].filter(Boolean).join(' · ')}</p>
                              )}
                            </Link>
                          </div>
                          {/* Review body */}
                          {(y.title || y.content) && (
                            <div className="flex gap-3 px-4 py-3">
                              <div className="w-0.5 shrink-0 rounded-full bg-primary/30 self-stretch" />
                              <div className="min-w-0 space-y-0.5">
                                {y.title && (
                                  <p className="text-[13px] font-[900] text-textStrong leading-snug">{y.title}</p>
                                )}
                                {y.content && (
                                  <p className="text-[12px] font-[700] leading-relaxed text-text line-clamp-2">{y.content}</p>
                                )}
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}

                {yorumlar.length > 0 && (
                  <Link href="/onerilerim"
                    className="mt-4 flex h-10 w-full items-center justify-center gap-2 rounded-xl border border-border bg-cardAlt text-sm font-[800] text-textStrong transition hover:border-primary/30 hover:text-primary">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                    Tüm yorumlarımı gör
                  </Link>
                )}
              </div>

              {/* Sağ kolon */}
              <div className="flex-[2] space-y-4">

                {/* Katkı İstatistiklerim */}
                <div className="rounded-2xl border border-border bg-card p-5 shadow-yd1">
                  <h2 className="mb-4 text-base font-[900] text-textStrong">Katkı İstatistiklerim</h2>

                  <div className="space-y-3">
                    <div className="flex items-center justify-between rounded-xl bg-cardAlt px-4 py-3">
                      <div className="flex items-center gap-2.5">
                        <span className="text-lg" aria-hidden="true">💬</span>
                        <span className="text-sm font-[800] text-textStrong">Yazılan Yorum</span>
                      </div>
                      <span className="text-xl font-[900] text-textStrong tabular-nums">{stats.reviews_count}</span>
                    </div>

                    <div className="flex items-center justify-between rounded-xl bg-cardAlt px-4 py-3">
                      <div className="flex items-center gap-2.5">
                        <span className="text-lg" aria-hidden="true">👍</span>
                        <span className="text-sm font-[800] text-textStrong">Beğenilen Yorum</span>
                      </div>
                      <span className="text-xl font-[900] text-textStrong tabular-nums">{stats.helpful_received}</span>
                    </div>

                    <div className="flex items-center justify-between rounded-xl bg-cardAlt px-4 py-3">
                      <div className="flex items-center gap-2.5">
                        <span className="text-lg" aria-hidden="true">❤️</span>
                        <span className="text-sm font-[800] text-textStrong">Favori Mekan</span>
                      </div>
                      <span className="text-xl font-[900] text-textStrong tabular-nums">{stats.favorites_count}</span>
                    </div>

                    <div className="flex items-center justify-between rounded-xl bg-cardAlt px-4 py-3">
                      <div className="flex items-center gap-2.5">
                        <span className="text-lg" aria-hidden="true">👥</span>
                        <span className="text-sm font-[800] text-textStrong">Takipçi</span>
                      </div>
                      <span className="text-xl font-[900] text-textStrong tabular-nums">{takipci}</span>
                    </div>

                    <div className="flex items-center justify-between rounded-xl bg-cardAlt px-4 py-3">
                      <div className="flex items-center gap-2.5">
                        <Bell className="h-5 w-5" aria-hidden="true" />
                        <span className="text-sm font-[800] text-textStrong">Takip Edilen</span>
                      </div>
                      <span className="text-xl font-[900] text-textStrong tabular-nums">{takip}</span>
                    </div>
                  </div>
                </div>

                {/* Hesap ayarları */}
                <div className="rounded-2xl border border-border bg-card shadow-yd1 overflow-hidden">
                  <div className="px-5 pt-4 pb-2">
                    <h2 className="text-base font-[900] text-textStrong">Hesap Ayarları</h2>
                  </div>
                  {HESAP_AYARLARI.map(({ href, label }) => (
                    <Link key={href} href={href}
                      className="flex items-center justify-between border-t border-border px-5 py-3.5 text-sm font-[700] text-textStrong transition hover:bg-cardAlt hover:text-primary">
                      {label}
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-muted" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
                    </Link>
                  ))}
                </div>
              </div>
            </div>

            {/* Premium banner */}
            <div className="flex flex-col items-start gap-4 rounded-2xl border border-emerald-200 bg-emerald-50 p-5 shadow-yd1 sm:flex-row sm:items-center">
              <div className="flex items-center gap-3 flex-1">
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-emerald-100 text-2xl">🎁</div>
                <div>
                  <p className="font-[900] text-emerald-900">Yeedoy Premium&apos;a Geç!</p>
                  <p className="mt-0.5 text-[13px] font-[700] text-emerald-700">Özel kampanyalar, reklamsız deneyim ve daha fazlası seni bekliyor.</p>
                </div>
              </div>
              <button type="button"
                className="flex h-11 items-center gap-2 rounded-xl bg-emerald-600 px-6 text-sm font-[900] text-white shadow-sm transition hover:bg-emerald-700 shrink-0">
                Premium&apos;a Geç →
              </button>
            </div>

            {/* Mobil nav */}
            <nav className="lg:hidden rounded-2xl border border-border bg-card shadow-yd1 overflow-hidden">
              <p className="px-5 pt-4 pb-2 text-[11px] font-[900] uppercase tracking-wide text-muted">Hızlı Erişim</p>
              {NAV_ITEMS.map(({ href, label, icon }) => (
                <Link key={href} href={href}
                  className="flex items-center gap-3 border-t border-border px-5 py-3.5 text-sm font-[800] text-textStrong transition hover:bg-cardAlt hover:text-primary">
                  <span className="w-5 shrink-0 text-muted">{icon}</span>
                  {label}
                </Link>
              ))}
            </nav>

          </div>
        </div>
      </div>
    </main>
  );
}

// ── İkon bileşenleri ──────────────────────────────────────────────────────────

function UserIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>;
}
function HeartIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>;
}
function LightbulbIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><line x1="9" y1="18" x2="15" y2="18"/><line x1="10" y1="22" x2="14" y2="22"/><path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1 .23 2.23 1.5 3.5A4.61 4.61 0 0 1 8.91 14"/></svg>;
}
function BellIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>;
}
function SettingsIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>;
}
function HelpIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>;
}
function LogoutIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>;
}
