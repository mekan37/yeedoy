import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = { title: 'Damak Twinlerim | Yeedoy', robots: { index: false, follow: false } };

type TwinUser = {
  user_id: string;
  display_name: string | null;
  avatar_url: string | null;
  common_count: number;
  match_score: number;
  top_business: string | null;
};

type MyStats = {
  reviews_count: number;
  avg_rating: number | null;
  top_categories: string[];
};

export default async function TasteTwinPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let twins: TwinUser[] = [];
  let myStats: MyStats | null = null;

  try {
    // Try RPC first
    const { data: rpcData } = await (supabase as any).rpc('get_taste_twin_users_v1', {
      p_user_id: user!.id,
      p_limit: 8,
    }) as { data: TwinUser[] | null };
    if (rpcData && rpcData.length > 0) twins = rpcData;
  } catch {
    // RPC doesn't exist yet — use manual computation
  }

  // Fallback: find users who reviewed the same businesses
  if (twins.length === 0) {
    try {
      // Get businesses this user reviewed
      const { data: myReviews } = await (supabase as any)
        .from('business_reviews')
        .select('business_id, rating')
        .eq('user_id', user!.id)
        .eq('is_visible', true)
        .limit(30) as { data: { business_id: string; rating: number }[] | null };

      const myBizIds = (myReviews ?? []).map((r) => r.business_id);

      if (myBizIds.length > 0) {
        // Find other users who reviewed same businesses
        const { data: otherReviews } = await (supabase as any)
          .from('business_reviews')
          .select('user_id, business_id, rating, user_profiles!user_id(display_name, avatar_url)')
          .in('business_id', myBizIds)
          .neq('user_id', user!.id)
          .eq('is_visible', true)
          .limit(200) as { data: Array<{ user_id: string; business_id: string; rating: number; user_profiles: { display_name: string | null; avatar_url: string | null } | null }> | null };

        // Group by user and score by common businesses
        const scoreMap = new Map<string, { count: number; profile: { display_name: string | null; avatar_url: string | null } | null; bizIds: string[] }>();
        for (const r of (otherReviews ?? [])) {
          const entry = scoreMap.get(r.user_id) ?? { count: 0, profile: r.user_profiles, bizIds: [] };
          entry.count++;
          entry.bizIds.push(r.business_id);
          scoreMap.set(r.user_id, entry);
        }

        twins = Array.from(scoreMap.entries())
          .sort((a, b) => b[1].count - a[1].count)
          .slice(0, 8)
          .map(([uid, data]) => ({
            user_id: uid,
            display_name: data.profile?.display_name ?? null,
            avatar_url: data.profile?.avatar_url ?? null,
            common_count: data.count,
            match_score: Math.min(100, Math.round((data.count / myBizIds.length) * 100)),
            top_business: null,
          }));
      }

      // Compute my stats
      const reviewCount = myBizIds.length;
      const avgRating = myReviews && myReviews.length > 0
        ? myReviews.reduce((s, r) => s + Number(r.rating), 0) / myReviews.length
        : null;
      myStats = { reviews_count: reviewCount, avg_rating: avgRating ? Math.round(avgRating * 10) / 10 : null, top_categories: [] };
    } catch {
      // ignore
    }
  }

  const initials = (name: string | null) => (name ?? 'G')[0].toUpperCase();

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">← Profilime Dön</Link>

        <h1 className="mb-1 text-2xl font-[900] text-textStrong">Damak Twinlerim</h1>
        <p className="mb-4 text-sm text-muted leading-relaxed">
          Aynı işletmeleri deneyimlemiş gurmeleri keşfedin — ortak mekan sayısı ve oran puanına göre.
        </p>
        <div className="mb-8 flex flex-wrap gap-2 text-[11px]">
          {[
            { icon: '🤝', label: 'Ortak mekan bazlı eşleştirme' },
            { icon: '📊', label: 'Match% = ortak / toplam' },
            { icon: '🔄', label: 'Anlık güncellenir' },
          ].map(({ icon, label }) => (
            <span key={label} className="inline-flex items-center gap-1.5 rounded-full border border-border bg-cardAlt px-3 py-1 font-[700] text-textStrong">
              {icon} {label}
            </span>
          ))}
        </div>

        {/* My stats */}
        {myStats && myStats.reviews_count > 0 && (
          <div className="mb-6 flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4">
            <div className="flex-1">
              <p className="text-xs font-[900] uppercase text-muted">Değerlendirmeleriniz</p>
              <p className="mt-0.5 text-2xl font-[900] text-textStrong">{myStats.reviews_count}</p>
            </div>
            {myStats.avg_rating && (
              <div className="flex-1 border-l border-border pl-4">
                <p className="text-xs font-[900] uppercase text-muted">Ort. Puanınız</p>
                <p className="mt-0.5 text-2xl font-[900] text-textStrong">⭐ {myStats.avg_rating}</p>
              </div>
            )}
            <div className="flex-1 border-l border-border pl-4">
              <p className="text-xs font-[900] uppercase text-muted">Twin Sayısı</p>
              <p className="mt-0.5 text-2xl font-[900] text-primary">{twins.length}</p>
            </div>
          </div>
        )}

        {twins.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="text-3xl mb-3">🍽️</p>
            <p className="font-[700] text-textStrong mb-2">Henüz yeterli veri yok</p>
            <p className="text-sm text-muted mb-6">Daha fazla işletme değerlendirdikçe benzer damak zevkindeki gurmeler burada görünecek.</p>
            <Link href="/kesif"
              className="inline-flex min-h-[44px] items-center rounded-2xl px-5 text-sm font-[800] text-white"
              style={{ background: 'var(--yd-gradient-primary)' }}>
              İşletme Keşfet
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {twins.map((twin, idx) => {
              const name = twin.display_name ?? 'Anonim Gurme';
              const matchBar = Math.max(10, twin.match_score);
              return (
                <div key={twin.user_id}
                  className="flex items-center gap-4 rounded-2xl border border-border bg-card px-5 py-4">
                  {/* Rank */}
                  <div className="w-5 shrink-0 text-center text-xs font-[900] text-muted">{idx + 1}</div>

                  {/* Avatar */}
                  <div className="h-11 w-11 shrink-0 overflow-hidden rounded-full border border-border bg-primary/10 flex items-center justify-center text-base font-[900] text-primary">
                    {twin.avatar_url
                      ? <Image src={twin.avatar_url} alt={name} width={44} height={44} className="h-full w-full object-cover" />
                      : initials(twin.display_name)}
                  </div>

                  {/* Info */}
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-[900] text-textStrong">{name}</p>
                    <div className="mt-1.5 flex items-center gap-2">
                      <div className="h-1.5 w-24 overflow-hidden rounded-full bg-border">
                        <div className="h-full rounded-full bg-primary transition-all" style={{ width: `${matchBar}%` }} />
                      </div>
                      <span className="text-[11px] font-[700] text-muted">{twin.common_count} ortak mekan</span>
                    </div>
                  </div>

                  {/* Score badge */}
                  <div className="shrink-0 flex h-10 w-10 items-center justify-center rounded-xl bg-[var(--yd-color-primary-soft)] text-sm font-[900] text-primary">
                    %{twin.match_score}
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
