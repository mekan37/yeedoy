import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const revalidate = 300;

export const metadata: Metadata = {
  title: 'Haftalık Liderler | Yeedoy',
  description:
    "Yeedoy topluluğunun bu haftanın en çok katkı yapan üyeleri — fiyat doğrulamaları, yorumlar ve fotoğraflar.",
  robots: { index: true, follow: true },
  alternates: { canonical: '/liderler' },
};

type LeaderboardRow = {
  user_id: string;
  verify_count: number;
  review_count: number;
  photo_count: number;
  weekly_score: number;
};

type UserProfileRow = {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  is_gourmet: boolean;
};

type LeaderEntry = LeaderboardRow & {
  display_name: string;
  avatar_url: string | null;
  is_gourmet: boolean;
};

function RankBadge({ rank }: { rank: number }) {
  const colors: Record<number, string> = { 1: '#FFD700', 2: '#9E9E9E', 3: '#CD7F32' };
  const color = colors[rank];
  return (
    <span className="text-sm font-black" style={color ? { color } : {}}>
      #{rank}
    </span>
  );
}

function ScorePill({ label, value }: { label: string; value: number }) {
  if (value === 0) return null;
  return (
    <span className="rounded-full bg-cardAlt border border-border px-2 py-0.5 text-[11px] font-bold text-muted">
      {label} {value}
    </span>
  );
}

export default async function LiderlerPage() {
  const supabase = await createSupabaseServerClient();

  let entries: LeaderEntry[] = [];

  try {
    const { data: rows, error } = await (supabase as any).rpc(
      'get_weekly_contributor_leaderboard_v1',
      { p_limit: 20 },
    ) as { data: LeaderboardRow[] | null; error: { message?: string } | null };

    if (!error && rows && rows.length > 0) {
      const userIds = rows.map((r) => r.user_id);

      const { data: profiles } = await (supabase as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url, is_gourmet')
        .in('user_id', userIds) as { data: UserProfileRow[] | null };

      const profileMap = new Map<string, UserProfileRow>(
        (profiles ?? []).map((p) => [p.user_id, p]),
      );

      entries = rows.map((row) => {
        const profile = profileMap.get(row.user_id);
        return {
          ...row,
          display_name: profile?.display_name ?? 'Yeedoy Üyesi',
          avatar_url: profile?.avatar_url ?? null,
          is_gourmet: profile?.is_gourmet ?? false,
        };
      });
    }
  } catch {
    entries = [];
  }

  return (
    <div className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-8">
        <div className="mb-6">
          <p className="text-xs font-bold uppercase tracking-wide text-muted mb-1">Topluluk</p>
          <h1 className="text-2xl font-black text-textStrong">Haftalık Liderler</h1>
          <p className="mt-1 text-sm text-muted">Bu haftanın en çok katkı yapan üyeleri</p>
        </div>

        {entries.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-base font-bold text-textStrong mb-1">
              Bu hafta henüz katkı yapılmadı
            </p>
            <p className="text-sm text-muted">
              Fiyat doğrulayarak, yorum yazarak veya fotoğraf ekleyerek ilk sıraya geçebilirsin.
            </p>
          </div>
        ) : (
          <ol className="flex flex-col gap-3">
            {entries.map((entry, i) => {
              const rank = i + 1;
              const initials = entry.display_name.charAt(0).toUpperCase();

              return (
                <li key={entry.user_id}>
                  <div className="rounded-xl border border-border bg-card p-4 flex items-center gap-4">
                    {/* Sıra */}
                    <span className="w-9 shrink-0 text-center">
                      <RankBadge rank={rank} />
                    </span>

                    {/* Avatar */}
                    <div className="h-11 w-11 shrink-0 overflow-hidden rounded-full border border-border bg-cardAlt flex items-center justify-center">
                      {entry.avatar_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={entry.avatar_url}
                          alt={entry.display_name}
                          className="h-full w-full object-cover"
                          loading="lazy"
                        />
                      ) : (
                        <span className="text-base font-black text-muted">{initials}</span>
                      )}
                    </div>

                    {/* Bilgi */}
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-1.5 mb-1">
                        <span className="truncate font-bold text-textStrong text-sm">
                          {entry.display_name}
                        </span>
                        {entry.is_gourmet && (
                          <span className="shrink-0 rounded-full bg-primary/5 border border-primary/20 px-1.5 py-0.5 text-[10px] font-bold text-primary">
                            Aktif
                          </span>
                        )}
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        <ScorePill label="Dogrulama" value={entry.verify_count} />
                        <ScorePill label="Yorum" value={entry.review_count} />
                        <ScorePill label="Fotograf" value={entry.photo_count} />
                      </div>
                    </div>

                    {/* Puan */}
                    <div className="shrink-0 text-right">
                      <span className="text-lg font-black text-primary">
                        {entry.weekly_score}
                      </span>
                      <p className="text-[10px] font-bold uppercase tracking-wide text-muted">
                        puan
                      </p>
                    </div>
                  </div>
                </li>
              );
            })}
          </ol>
        )}

        {/* Puan açıklaması */}
        <div className="mt-8 rounded-xl border border-border bg-cardAlt p-4">
          <p className="text-xs font-bold uppercase tracking-wide text-muted mb-2">
            Puan Sistemi
          </p>
          <ul className="flex flex-col gap-1">
            <li className="flex items-center justify-between text-sm text-textStrong">
              <span>Yorum yazma</span>
              <span className="font-bold text-primary">3 puan</span>
            </li>
            <li className="flex items-center justify-between text-sm text-textStrong">
              <span>Fiyat dogrulama</span>
              <span className="font-bold text-primary">2 puan</span>
            </li>
            <li className="flex items-center justify-between text-sm text-textStrong">
              <span>Fotograf ekleme</span>
              <span className="font-bold text-primary">2 puan</span>
            </li>
          </ul>
          <p className="mt-3 text-[11px] text-muted">
            Son 7 gunun katkilari sayilir. Tablo her 5 dakikada bir guncellenir.
          </p>
        </div>
      </div>
    </div>
  );
}
