import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Haftalık Kahramanlar | Yeedoy',
  description: 'Bu haftanın en çok katkı sağlayan Yeedoy gurmeleri',
  openGraph: {
    title: 'Haftalık Kahramanlar | Yeedoy',
  },
};

export const revalidate = 300;

type LeaderboardEntry = {
  user_id: string;
  display_name: string | null;
  avatar_url: string | null;
  score: number;
  review_count: number;
  rank: number;
};

const PERIODS = [
  { key: 'weekly', label: 'Bu Hafta', rpc: 'get_weekly_contributor_leaderboard_v1' },
  { key: 'monthly', label: 'Bu Ay', rpc: 'get_monthly_contributor_leaderboard_v1' },
  { key: 'alltime', label: 'Tüm Zamanlar', rpc: 'get_alltime_contributor_leaderboard_v1' },
] as const;

export default async function HeroesPage({ searchParams }: { searchParams: Promise<{ period?: string }> }) {
  const sp = await searchParams;
  const periodKey = (sp.period ?? 'weekly') as string;
  const period = PERIODS.find((p) => p.key === periodKey) ?? PERIODS[0];

  const supabase = await createSupabaseServerClient();

  let entries: LeaderboardEntry[] = [];
  try {
    const { data, error } = await supabase.rpc(period.rpc as never) as { data: LeaderboardEntry[] | null; error: any };
    if (!error) entries = data ?? [];
  } catch { entries = []; }

  // Fallback: try weekly if chosen period RPC doesn't exist
  if (entries.length === 0 && period.key !== 'weekly') {
    try {
      const { data } = await supabase.rpc('get_weekly_contributor_leaderboard_v1' as never) as { data: LeaderboardEntry[] | null };
      entries = data ?? [];
    } catch { entries = []; }
  }

  const medalColor = (rank: number) => {
    if (rank === 1) return 'text-amber-500 bg-amber-50 border-amber-200';
    if (rank === 2) return 'text-slate-500 bg-slate-50 border-slate-200';
    if (rank === 3) return 'text-orange-600 bg-orange-50 border-orange-200';
    return 'text-muted bg-bg border-border';
  };

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="mb-6">
          <p className="text-xs font-[800] uppercase tracking-widest text-primary mb-2">Liderlik Tablosu</p>
          <h1 className="font-display text-3xl font-[900] text-textStrong mb-2">Kahramanlar</h1>
          <p className="text-muted">En aktif Yeedoy gurmeleri</p>
        </div>

        {/* Period toggle */}
        <div className="mb-6 flex gap-1 rounded-2xl border border-border bg-cardAlt p-1">
          {PERIODS.map((p) => (
            <Link
              key={p.key}
              href={`?period=${p.key}`}
              className={`flex flex-1 items-center justify-center rounded-xl py-2 text-center text-sm font-[800] transition-all ${periodKey === p.key ? 'bg-card text-primary shadow-yd1' : 'text-muted hover:text-textStrong'}`}
            >
              {p.label}
            </Link>
          ))}
        </div>

        {entries.length === 0 ? (
          <div className="rounded-[20px] border border-border bg-card p-10 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-amber-50">
              <svg viewBox="0 0 24 24" className="h-7 w-7 text-amber-500 fill-none stroke-current" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/>
                <path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/>
                <path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/>
                <path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/>
              </svg>
            </div>
            <p className="font-[700] text-textStrong mb-2">Bu hafta henüz katkıcı yok</p>
            <Link href="/kesif" className="text-sm text-primary hover:underline">
              Yorum yazarak listeye gir →
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {entries.map((e) => {
              const name = e.display_name ?? 'Anonim Gurme';
              const isTopThree = e.rank <= 3;
              return (
                <div key={e.user_id}
                  className={`flex items-center gap-4 rounded-[20px] border px-5 py-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2 ${isTopThree ? 'border-primary/20 bg-cardAlt' : 'border-border bg-card'}`}>
                  <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border text-sm font-[900] ${medalColor(e.rank)}`}>
                    {e.rank <= 3 ? <MedalIcon rank={e.rank} /> : `#${e.rank}`}
                  </div>

                  <div className="h-10 w-10 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-sm font-[900] text-primary">
                    {e.avatar_url
                      ? <Image src={e.avatar_url} alt={name} width={40} height={40} className="h-full w-full object-cover" />
                      : name[0]?.toUpperCase() ?? 'G'}
                  </div>

                  <div className="flex-1 min-w-0">
                    <p className="font-[800] text-textStrong truncate">{name}</p>
                    <p className="text-xs text-muted">{e.review_count} yorum</p>
                  </div>
                  <Link href={`/gurmeler/${e.user_id}`} className="shrink-0 text-[11px] font-[700] text-primary hover:underline">Profil →</Link>

                  <div className="shrink-0 text-right">
                    <p className="text-lg font-[900] text-primary">{e.score}</p>
                    <p className="text-[10px] font-[700] uppercase tracking-wide text-muted">puan</p>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}

function MedalIcon({ rank }: { rank: number }) {
  const colors = rank === 1 ? '#f59e0b' : rank === 2 ? '#94a3b8' : '#d97706';
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" aria-hidden="true">
      <path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6" stroke={colors} strokeWidth="2" strokeLinecap="round"/>
      <path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18" stroke={colors} strokeWidth="2" strokeLinecap="round"/>
      <path d="M4 22h16M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22M18 2H6v7a6 6 0 0 0 12 0V2Z" stroke={colors} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

