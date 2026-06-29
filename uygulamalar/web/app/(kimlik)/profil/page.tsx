import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { Container } from '@/src/ui/acik/ortak';

export const metadata: Metadata = {
  title: 'Profilim | Yeedoy',
  robots: { index: false, follow: false },
};

type Profile = {
  display_name: string | null; avatar_url: string | null;
  bio: string | null; city: string | null; created_at: string;
};

type Achievement = {
  id: string; title: string; description: string; icon: string; color: string;
  xp: number; unlocked: boolean; current_value: number; target_value: number;
};

type DailyTask = {
  task_key: string; title: string; description: string;
  current_value: number; target_value: number; completed: boolean;
};

type Progress = {
  total_xp: number; level: number; xp_in_level: number;
  next_level_xp: number; unlocked_count: number;
};

type Stats = {
  reviews_count: number; helpful_received: number;
  favorites_count: number; contribution_score: number;
};

type TabKey = 'profile' | 'achievements' | 'feed';

const NAV_LINKS = [
  { href: '/favoriler', label: 'Favorilerim', icon: 'heart' },
  { href: '/takip', label: 'Takip Ettiklerim', icon: 'users' },
  { href: '/ortak-listeler', label: 'Kolaborasyon Listeleri', icon: 'list' },
  { href: '/grup-istekleri', label: 'Grup Talepleri', icon: 'people' },
  { href: '/onerilerim', label: 'Önerilerim', icon: 'lightbulb' },
  { href: '/gelen-kutusu', label: 'Bildirimler', icon: 'bell' },
  { href: '/diyet-profili', label: 'Diyet Tercihlerim', icon: 'leaf' },
  { href: '/bildirim-ayarlari', label: 'Bildirim Ayarları', icon: 'bell' },
  { href: '/hesap-sil', label: 'Hesabımı Sil', icon: 'trash' },
];

const FEED_LINKS = [
  { href: '/akilli-akis', label: 'Akıllı Besleme', description: 'Tercihlerine göre kişisel öneriler' },
  { href: '/tat-ikizi', label: 'Taste Twin', description: 'Benzer zevkteki gurmeleri keşfet' },
  { href: '/fiyat-uyarilari', label: 'Fiyat Alarmları', description: 'Takip ettiğin fiyat değişimleri' },
];

export default async function ProfilePage({
  searchParams,
}: {
  searchParams: Promise<{ tab?: string }>;
}) {
  const sp = await searchParams;
  const tab: TabKey = ['profile', 'achievements', 'feed'].includes(sp.tab ?? '')
    ? (sp.tab as TabKey)
    : 'profile';

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  // Always fetch profile + followers
  const [profileRes, followersRes, followingRes] = await Promise.all([
    (supabase as any).from('user_profiles').select('display_name, avatar_url, bio, city, created_at').eq('id', user!.id).maybeSingle() as Promise<{ data: Profile | null }>,
    (supabase as any).from('user_follows').select('id', { count: 'exact', head: true }).eq('followed_id', user!.id) as Promise<{ count: number | null; error: { code?: string } | null }>,
    (supabase as any).from('user_follows').select('id', { count: 'exact', head: true }).eq('follower_id', user!.id) as Promise<{ count: number | null; error: { code?: string } | null }>,
  ]);

  const profile = profileRes.data;
  const followersCount = followersRes.count ?? 0;
  const followingCount = followingRes.count ?? 0;

  // Tab-specific data — only fetch what's needed
  let stats: Stats | null = null;
  let progress: Progress | null = null;
  let dailyTask: DailyTask | null = null;
  let achievements: Achievement[] = [];
  let reputation = 0;

  if (tab === 'profile') {
    const [statsRes, progressRes, taskRes, repRes] = await Promise.all([
      (supabase as any).rpc('get_my_profile_stats') as Promise<{ data: Stats[] | null }>,
      (supabase as any).rpc('get_my_profile_progress_v1') as Promise<{ data: Progress[] | null }>,
      (supabase as any).rpc('get_my_daily_micro_task_v1') as Promise<{ data: DailyTask[] | null }>,
      (supabase as any).rpc('get_my_reputation_score_v1') as Promise<{ data: number | null }>,
    ]);
    stats = statsRes.data?.[0] ?? null;
    progress = progressRes.data?.[0] ?? null;
    dailyTask = taskRes.data?.[0] ?? null;
    reputation = repRes.data ?? 0;
  }

  if (tab === 'achievements') {
    const achRes = await ((supabase as any).rpc('get_my_achievements_v2') as Promise<{ data: Achievement[] | null }>);
    achievements = achRes.data ?? [];
  }

  const displayName = profile?.display_name ?? 'Kullanıcı';
  const initials = displayName[0]?.toUpperCase() ?? 'U';
  const xpPct = progress
    ? Math.round((progress.xp_in_level / Math.max(1, progress.next_level_xp)) * 100)
    : 0;

  return (
    <main className="min-h-screen bg-bg">
      <Container className="pb-20 pt-10">

        {/* ── Identity card ──────────────────────────────────────────────── */}
        <div className="mb-4 rounded-[20px] border border-border bg-cardAlt p-6 shadow-yd2">
          <div className="flex items-start gap-4">
            {/* Avatar */}
            <div className="h-[72px] w-[72px] shrink-0 overflow-hidden rounded-[18px] border-2 border-border bg-primary/10 shadow-yd1">
              {profile?.avatar_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img loading="lazy" src={profile.avatar_url} alt={displayName} className="h-full w-full object-cover" />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-2xl font-[900] text-primary">{initials}</div>
              )}
            </div>

            {/* Info */}
            <div className="min-w-0 flex-1">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <h1 className="truncate text-xl font-[900] text-textStrong">{displayName}</h1>
                  <p className="truncate text-sm text-muted">{user!.email}</p>
                  {profile?.city && <p className="text-xs text-muted">{profile.city}</p>}
                </div>
                <Link href="/profil/settings"
                  className="shrink-0 rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[800] text-textStrong transition-colors hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                  Düzenle
                </Link>
              </div>

              {/* Level + XP bar */}
              {progress && (
                <div className="mt-3">
                  <div className="mb-1 flex items-center justify-between text-[11px] font-[800]">
                    <span className="text-primary">Seviye {progress.level}</span>
                    <span className="text-muted">{progress.total_xp} XP</span>
                  </div>
                  <div className="h-2 w-full overflow-hidden rounded-full bg-border">
                    <div className="h-full rounded-full transition-all duration-500" style={{ width: `${xpPct}%`, background: 'var(--yd-gradient-primary)' }} />
                  </div>
                </div>
              )}
            </div>
          </div>

          {profile?.bio && (
            <p className="mt-4 rounded-xl border border-border bg-bg px-4 py-2.5 text-sm text-textStrong">
              {profile.bio}
            </p>
          )}

          {/* Stats row */}
          <div className="mt-4 grid grid-cols-3 gap-2">
            {[
              { value: stats?.reviews_count ?? followersCount, label: 'Yorum' },
              { value: followersCount, label: 'Takipçi' },
              { value: followingCount, label: 'Takip' },
            ].map(({ value, label }) => (
              <div key={label} className="rounded-xl border border-border bg-bg py-2.5 text-center">
                <p className="text-2xl font-[900] text-textStrong">{value}</p>
                <p className="text-[11px] text-muted">{label}</p>
              </div>
            ))}
          </div>

          {/* Reputation */}
          {reputation > 0 && (
            <div className="mt-3 flex items-center gap-2 rounded-xl border border-[var(--yd-color-primary-soft)] bg-[var(--yd-color-primary-soft)] px-4 py-2">
              <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 text-primary fill-current" aria-hidden="true"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <span className="text-sm font-[800] text-primary">{reputation} İtibar Puanı</span>
            </div>
          )}
        </div>

        {/* ── Tabs ───────────────────────────────────────────────────────── */}
        <div className="mb-5 flex gap-1 rounded-2xl border border-border bg-cardAlt p-1">
          {([
            ['profile', 'Profilim', null] as [TabKey, string, number | null],
            ['achievements', 'Başarımlar', tab === 'achievements' ? achievements.filter((a) => a.unlocked).length : null] as [TabKey, string, number | null],
            ['feed', 'Besleme', null] as [TabKey, string, number | null],
          ]).map(([key, label, badge]) => (
            <Link key={key} href={`?tab=${key}`}
              className={`flex flex-1 items-center justify-center gap-1.5 rounded-xl py-2 text-center text-sm font-[800] transition-all duration-[150ms] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 ${tab === key ? 'bg-card text-primary shadow-yd1' : 'text-muted hover:text-textStrong'}`}>
              {label}
              {badge !== null && (
                <span className={`rounded-full px-1.5 py-0.5 text-[10px] font-[900] leading-none ${tab === key ? 'bg-primary/10 text-primary' : 'bg-border text-muted'}`}>
                  {badge}
                </span>
              )}
            </Link>
          ))}
        </div>

        {/* ── Tab: Profile ───────────────────────────────────────────────── */}
        {tab === 'profile' && (
          <div className="space-y-4">

            {/* Daily task */}
            {dailyTask && !dailyTask.completed && (
              <div className="rounded-[20px] border border-primary/25 bg-[var(--yd-color-primary-soft)] p-5 shadow-yd1">
                {/* Header */}
                <div className="mb-3 flex items-start justify-between gap-3">
                  <div className="flex items-center gap-2">
                    <span className="text-xl" aria-hidden="true">🎯</span>
                    <div>
                      <p className="text-[11px] font-[900] uppercase tracking-wide text-primary">Bugünün Görevi</p>
                      <p className="mt-0.5 font-[900] leading-tight text-textStrong">{dailyTask.title}</p>
                    </div>
                  </div>
                  {/* XP reward badge */}
                  <span className="shrink-0 rounded-full border border-primary/25 bg-white px-2.5 py-1 text-xs font-[900] text-primary">
                    +XP
                  </span>
                </div>

                {dailyTask.description && (
                  <p className="mb-3 text-xs leading-relaxed text-muted">{dailyTask.description}</p>
                )}

                {/* Progress bar */}
                <div>
                  <div className="mb-1.5 flex items-center justify-between text-[11px] font-[800]">
                    <span className="text-primary">
                      {dailyTask.current_value} / {dailyTask.target_value}
                    </span>
                    <span className="text-muted">
                      {Math.min(100, Math.round((dailyTask.current_value / Math.max(1, dailyTask.target_value)) * 100))}%
                    </span>
                  </div>
                  <div className="h-2.5 w-full overflow-hidden rounded-full bg-primary/20">
                    <div
                      className="h-full rounded-full bg-primary transition-all duration-500"
                      style={{ width: `${Math.min(100, Math.round((dailyTask.current_value / Math.max(1, dailyTask.target_value)) * 100))}%` }}
                    />
                  </div>
                </div>
              </div>
            )}

            {dailyTask?.completed && (
              <div className="rounded-[20px] border border-green-200 bg-green-50 p-5 shadow-yd1">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 border-green-300 bg-green-100">
                    <svg viewBox="0 0 24 24" className="h-5 w-5 text-green-600 fill-none stroke-current" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <polyline points="20 6 9 17 4 12"/>
                    </svg>
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="font-[900] text-green-700">Günlük görev tamamlandı!</p>
                    <p className="mt-0.5 text-xs text-green-600">{dailyTask.title}</p>
                  </div>
                  <span className="shrink-0 rounded-full border border-green-300 bg-green-100 px-2.5 py-1 text-xs font-[900] text-green-700">
                    +XP
                  </span>
                </div>
              </div>
            )}

            {/* Contribution stats */}
            {stats && (
              <div className="rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1">
                <div className="mb-4 flex items-center gap-2">
                  <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current text-primary shrink-0" aria-hidden="true">
                    <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 14l-5-5 1.41-1.41L12 14.17l7.59-7.59L21 8l-9 9z"/>
                  </svg>
                  <p className="text-sm font-[900] text-textStrong">Katkı Özeti</p>
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  {[
                    { value: stats.reviews_count, label: 'Yorum', icon: '✍️' },
                    { value: stats.helpful_received, label: 'Yardımcı Bulundu', icon: '👍' },
                    { value: stats.favorites_count, label: 'Favori', icon: '❤️' },
                    { value: stats.contribution_score, label: 'Katkı Puanı', icon: '⭐' },
                  ].map(({ value, label, icon }) => (
                    <div key={label} className="flex flex-col gap-1.5 rounded-2xl border border-border bg-bg px-4 py-3.5 shadow-yd1">
                      <span className="text-base leading-none" aria-hidden="true">{icon}</span>
                      <p className="text-2xl font-[900] leading-tight text-textStrong">{value}</p>
                      <p className="text-[11px] font-[700] text-muted">{label}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Quick nav links */}
            <div className="flex flex-col gap-2">
              {NAV_LINKS.map(({ href, label }) => (
                <Link key={href} href={href}
                  className="flex items-center justify-between rounded-[20px] border border-border bg-cardAlt px-5 py-3.5 text-sm font-[700] text-textStrong shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-yd2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                  {label}
                  <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current text-muted" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
                </Link>
              ))}
            </div>
          </div>
        )}

        {/* ── Tab: Achievements ──────────────────────────────────────────── */}
        {tab === 'achievements' && (
          <div>
            {achievements.length === 0 ? (
              <div className="rounded-[20px] border border-border bg-card p-10 text-center text-muted">
                Başarım verisi yüklenemedi.
              </div>
            ) : (
              <>
                {/* Summary banner */}
                <div className="mb-4 flex items-center justify-between rounded-2xl border border-border bg-cardAlt px-4 py-3">
                  <div className="flex items-center gap-2">
                    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current text-primary" aria-hidden="true">
                      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                    </svg>
                    <span className="text-sm font-[900] text-textStrong">
                      {achievements.filter((a) => a.unlocked).length} / {achievements.length} başarım kazanıldı
                    </span>
                  </div>
                  <span className="rounded-full bg-[var(--yd-color-primary-soft)] px-2.5 py-1 text-xs font-[900] text-primary">
                    {Math.round((achievements.filter((a) => a.unlocked).length / Math.max(1, achievements.length)) * 100)}%
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  {achievements.map((ach) => (
                    <div key={ach.id}
                      className={`flex flex-col gap-2 rounded-[20px] border p-4 shadow-yd1 transition-all ${
                        ach.unlocked
                          ? 'border-primary/30 bg-cardAlt ring-1 ring-primary/10'
                          : 'border-dashed border-border bg-bg opacity-55'
                      }`}>
                      {/* Icon row */}
                      <div className="flex items-start justify-between gap-1">
                        <span className="text-2xl leading-none" aria-hidden="true">{ach.icon}</span>
                        {ach.unlocked ? (
                          <div className="flex shrink-0 flex-col items-end gap-1">
                            {/* Green checkmark badge */}
                            <span className="flex h-5 w-5 items-center justify-center rounded-full bg-success/[0.15] border border-success/30">
                              <svg viewBox="0 0 24 24" className="h-3 w-3 fill-none stroke-current text-success" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-label="Kazanıldı">
                                <polyline points="20 6 9 17 4 12"/>
                              </svg>
                            </span>
                            {/* XP badge */}
                            <span className="rounded-full border border-success/25 bg-success/[0.12] px-1.5 py-0.5 text-[10px] font-[900] text-success">
                              +{ach.xp} XP
                            </span>
                          </div>
                        ) : (
                          /* Lock icon for locked achievements */
                          <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-border/60">
                            <svg viewBox="0 0 24 24" className="h-3 w-3 fill-current text-muted" aria-hidden="true">
                              <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
                            </svg>
                          </span>
                        )}
                      </div>

                      {/* Title + description */}
                      <div>
                        <p className={`text-sm font-[900] leading-tight ${ach.unlocked ? 'text-textStrong' : 'text-muted'}`}>
                          {ach.title}
                        </p>
                        <p className="mt-0.5 text-[11px] leading-snug text-muted">{ach.description}</p>
                      </div>

                      {/* Progress bar for locked achievements */}
                      {!ach.unlocked && ach.target_value > 0 && (
                        <div className="mt-auto">
                          <div className="mb-1 flex items-center justify-between text-[10px] text-muted">
                            <span>{ach.current_value} / {ach.target_value}</span>
                            <span>{Math.min(100, Math.round((ach.current_value / Math.max(1, ach.target_value)) * 100))}%</span>
                          </div>
                          <div className="h-1.5 w-full overflow-hidden rounded-full bg-border">
                            <div className="h-full rounded-full bg-primary/50 transition-all duration-500"
                              style={{ width: `${Math.min(100, Math.round((ach.current_value / Math.max(1, ach.target_value)) * 100))}%` }} />
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        )}

        {/* ── Tab: Feed ──────────────────────────────────────────────────── */}
        {tab === 'feed' && (
          <div className="flex flex-col gap-3">
            {FEED_LINKS.map(({ href, label, description }) => (
              <Link key={href} href={href}
                className="flex items-center justify-between rounded-[20px] border border-border bg-cardAlt p-5 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-yd2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30">
                <div>
                  <p className="font-[800] text-textStrong">{label}</p>
                  <p className="mt-0.5 text-sm text-muted">{description}</p>
                </div>
                <svg viewBox="0 0 24 24" className="h-5 w-5 shrink-0 fill-none stroke-current text-muted" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
              </Link>
            ))}
          </div>
        )}

      </Container>
    </main>
  );
}

