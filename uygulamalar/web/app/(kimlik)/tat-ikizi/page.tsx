import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Tat İkizin | Yeedoy',
  robots: { index: false, follow: false },
};

type TasteMatch = {
  user_id: string;
  similarity: number;
  overlap: number;
  review_similarity: number;
  signal_similarity: number;
  display_name?: string;
  avatar_url?: string;
};

export default async function TatIkiziPage() {
  const supabase = await createSupabaseServerClient();

  let matches: TasteMatch[] = [];
  let fetchError: string | null = null;

  try {
    const { data, error: rpcError } = await (supabase as any).rpc(
      'get_taste_matches_hybrid_v1',
      {
        p_limit: 20,
        p_min_overlap: 3,
      },
    );

    if (rpcError) throw rpcError;

    const raw = (data as TasteMatch[]) ?? [];

    if (raw.length > 0) {
      const ids = raw.map((m) => m.user_id);
      const { data: profiles } = await (supabase as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url')
        .in('user_id', ids);

      const profileMap = Object.fromEntries(
        (
          (profiles ?? []) as {
            user_id: string;
            display_name: string | null;
            avatar_url: string | null;
          }[]
        ).map((p) => [p.user_id, { display_name: p.display_name, avatar_url: p.avatar_url }]),
      );

      matches = raw.map((m) => ({
        ...m,
        display_name: profileMap[m.user_id]?.display_name ?? undefined,
        avatar_url: profileMap[m.user_id]?.avatar_url ?? undefined,
      }));
    }
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : (e as { message?: string })?.message;
    fetchError = msg ?? 'Tat ikizleri yüklenemedi.';
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 pb-20 pt-10">

        {/* Geri */}
        <Link
          href="/kesif"
          className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-primary"
        >
          <svg viewBox="0 0 24 24" className="h-4 w-4 fill-current" aria-hidden="true">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" />
          </svg>
          Keşfe Dön
        </Link>

        {/* Başlık */}
        <div className="mb-6">
          <p className="mb-1 text-xs font-bold uppercase tracking-wide text-muted">Keşif</p>
          <h1 className="text-2xl font-black text-textStrong">Tat İkizin</h1>
          <p className="mt-1 text-sm text-muted">Benzer damak tadındaki Yeedoy kullanıcıları</p>
        </div>

        {/* Hata */}
        {fetchError && (
          <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-center">
            <p className="text-sm font-bold text-red-700">{fetchError}</p>
          </div>
        )}

        {/* Boş durum */}
        {!fetchError && matches.length === 0 && (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-(--yd-color-primary-soft)">
              <svg
                viewBox="0 0 24 24"
                className="h-7 w-7 fill-none stroke-current text-primary"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
              </svg>
            </div>
            <p className="mb-2 font-black text-textStrong">Henüz yeterli yorum yok</p>
            <p className="mb-6 text-sm text-muted">
              Daha fazla yorum yaptıkça tat ikilerin ortaya çıkar.
              <br />
              En az 3 ortak işletme yorumu gerekiyor.
            </p>
            <Link
              href="/kesif"
              className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-extrabold text-white transition-all hover:-translate-y-px hover:brightness-105 active:scale-[0.97] focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
              style={{
                background: 'var(--yd-gradient-primary)',
                boxShadow: 'var(--yd-shadow-primary)',
              }}
            >
              İşletme Keşfet
            </Link>
          </div>
        )}

        {/* Eşleşme listesi */}
        {!fetchError && matches.length > 0 && (
          <div className="flex flex-col gap-4">
            <p className="text-xs text-muted">{matches.length} tat ikizi bulundu</p>
            {matches.map((match, idx) => (
              <TatIkiziKarti key={match.user_id} match={match} rank={idx + 1} />
            ))}
          </div>
        )}
      </div>
    </main>
  );
}

function TatIkiziKarti({ match, rank }: { match: TasteMatch; rank: number }) {
  const pct = Math.round(Math.min(1, Math.max(0, match.similarity)) * 100);
  const displayName = match.display_name ?? `Kullanıcı #${rank}`;
  const initials = displayName
    .split(' ')
    .slice(0, 2)
    .map((w) => w[0] ?? '')
    .join('')
    .toUpperCase() || '#';

  return (
    <div className="flex items-center gap-4 rounded-2xl border border-border bg-card p-4 shadow-yd1 transition-all hover:-translate-y-0.5 hover:border-primary/20 hover:shadow-yd2">
      {/* Avatar */}
      <div className="relative h-12 w-12 shrink-0">
        {match.avatar_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={match.avatar_url}
            alt={displayName}
            className="h-12 w-12 rounded-full object-cover"
            loading="lazy"
          />
        ) : (
          <div
            className="flex h-12 w-12 items-center justify-center rounded-full text-sm font-black text-white"
            style={{ background: 'linear-gradient(135deg, #5C1515 0%, #7F1D1D 100%)' }}
            aria-hidden="true"
          >
            {initials}
          </div>
        )}
        <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-primary text-[10px] font-black text-white shadow-sm">
          {rank}
        </span>
      </div>

      {/* Bilgi */}
      <div className="min-w-0 flex-1">
        <p className="font-black text-textStrong">{displayName}</p>
        <p className="mt-0.5 text-xs text-muted">{match.overlap} ortak yorum</p>
      </div>

      {/* Benzerlik rozeti */}
      <div className="shrink-0 text-right">
        <div
          className="mb-1 h-1.5 w-16 overflow-hidden rounded-full bg-border"
          role="progressbar"
          aria-valuenow={pct}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-label={`${pct}% uyum`}
        >
          <div
            className="h-full rounded-full bg-primary transition-all"
            style={{ width: `${pct}%` }}
          />
        </div>
        <span className="text-sm font-black text-primary">{pct}%</span>
        <span className="block text-[10px] text-muted">uyum</span>
      </div>
    </div>
  );
}
