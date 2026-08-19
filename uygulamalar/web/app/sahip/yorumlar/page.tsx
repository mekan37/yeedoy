import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YorumlarIstemcisi, type YorumSatiriVerisi } from './yorumlar-istemcisi';

export const metadata: Metadata = {
  title: 'Yorumlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

type ReviewRow = {
  id: string;
  business_id: string;
  user_id: string | null;
  rating: number;
  content: string | null;
  status: string;
  created_at: string;
  owner_reply: string | null;
  owner_replied_at: string | null;
};

export default async function OwnerReviewsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b) => b.id);
  const businessMap = Object.fromEntries(businesses.map((b) => [b.id, b.name]));

  const { data: reviews } = businessIds.length > 0
    ? await (supabase as any)
        .from('reviews')
        .select('id, business_id, user_id, rating, content, status, created_at, owner_reply, owner_replied_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(300)
    : { data: [] };

  const list = (reviews ?? []) as ReviewRow[];

  const userIds = Array.from(new Set(list.map((review) => review.user_id).filter((id): id is string => Boolean(id))));
  const { data: profiles } = userIds.length > 0
    ? await (supabase as any)
        .from('user_profiles')
        .select('user_id, display_name, avatar_url')
        .in('user_id', userIds)
    : { data: [] };

  const profileMap = new Map(
    ((profiles ?? []) as Array<{ user_id: string; display_name: string | null; avatar_url: string | null }>)
      .map((profile) => [profile.user_id, { displayName: profile.display_name, avatarUrl: profile.avatar_url }] as const),
  );

  const satirlar: YorumSatiriVerisi[] = list.map((r) => ({
    id: r.id,
    businessId: r.business_id,
    businessName: businessMap[r.business_id] ?? '',
    rating: r.rating,
    content: r.content,
    displayName: r.user_id ? (profileMap.get(r.user_id)?.displayName ?? null) : null,
    avatarUrl: r.user_id ? (profileMap.get(r.user_id)?.avatarUrl ?? null) : null,
    createdAt: r.created_at,
    status: r.status === 'rejected' ? 'rejected' : r.status === 'pending' ? 'pending' : 'approved',
    ownerReply: r.owner_reply,
    ownerRepliedAt: r.owner_replied_at,
  }));

  // Gerçek dönemsel trend: son 30 gün vs önceki 30 gün
  const now = Date.now();
  const since30d = new Date(now - 30 * 86400000).toISOString();
  const since60d = new Date(now - 60 * 86400000).toISOString();
  const curr = list.filter((r) => r.created_at >= since30d);
  const prev = list.filter((r) => r.created_at >= since60d && r.created_at < since30d);

  function pctChange(currCount: number, prevCount: number): number {
    if (prevCount === 0) return currCount > 0 ? 100 : 0;
    return Math.round(((currCount - prevCount) / prevCount) * 100);
  }

  const avgRating = list.length > 0 ? list.reduce((sum, r) => sum + r.rating, 0) / list.length : 0;
  const currAvg = curr.length > 0 ? curr.reduce((s, r) => s + r.rating, 0) / curr.length : null;
  const prevAvg = prev.length > 0 ? prev.reduce((s, r) => s + r.rating, 0) / prev.length : null;
  const avgRatingTrend = currAvg !== null && prevAvg !== null ? Math.round((currAvg - prevAvg) * 10) / 10 : null;

  const approvedCount = list.filter((r) => r.status === 'approved').length;
  const awaitingReplyCount = list.filter((r) => r.status === 'approved' && !r.owner_reply).length;
  const rejectedCount = list.filter((r) => r.status === 'rejected').length;

  const stats = {
    avgRating,
    avgRatingTrend,
    total: list.length,
    totalTrend: pctChange(curr.length, prev.length),
    approvedCount,
    approvedPct: list.length > 0 ? Math.round((approvedCount / list.length) * 1000) / 10 : 0,
    awaitingReplyCount,
    awaitingReplyPct: list.length > 0 ? Math.round((awaitingReplyCount / list.length) * 1000) / 10 : 0,
    rejectedCount,
    rejectedPct: list.length > 0 ? Math.round((rejectedCount / list.length) * 1000) / 10 : 0,
  };

  const ratingDagilimi = [5, 4, 3, 2, 1].map((star) => {
    const count = list.filter((r) => r.rating === star).length;
    return { star, count, pct: list.length > 0 ? Math.round((count / list.length) * 1000) / 10 : 0 };
  });

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <YorumlarIstemcisi
          satirlar={satirlar}
          stats={stats}
          ratingDagilimi={ratingDagilimi}
          coklu={businessIds.length > 1}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
