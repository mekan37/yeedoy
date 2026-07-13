import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { YorumlarIstemcisi } from './yorumlar-istemcisi';
import type { YorumSatiriVeri } from './yorumlar-istemcisi';

export const metadata: Metadata = {
  title: 'Yorumlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerReviewsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b: { id: string }) => b.id);
  const businessMap = Object.fromEntries(businesses.map((b: { id: string; name: string }) => [b.id, b.name]));

  const { data: reviews } = businessIds.length > 0
    ? await (supabase as any)
        .from('reviews')
        .select('id, business_id, user_id, rating, title, content, helpful_count, status, created_at, owner_reply, owner_replied_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(100)
    : { data: [] };

  const list = (reviews ?? []) as Array<{
    id: string;
    business_id: string;
    user_id: string | null;
    rating: number;
    title: string | null;
    content: string | null;
    helpful_count: number;
    status: string;
    created_at: string;
    owner_reply: string | null;
    owner_replied_at: string | null;
  }>;

  const userIds = Array.from(new Set(list.map((review) => review.user_id).filter((id): id is string => Boolean(id))));
  const { data: profiles } = userIds.length > 0
    ? await (supabase as any)
        .from('user_profiles')
        .select('user_id, display_name')
        .in('user_id', userIds)
    : { data: [] };

  const profileMap = new Map(
    ((profiles ?? []) as Array<{ user_id: string; display_name: string | null }>)
      .map((profile) => [profile.user_id, profile.display_name] as const),
  );

  const unreplied = list.filter((r) => !r.owner_reply).length;
  const showBusinessName = businessIds.length > 1;

  const reviewRows: YorumSatiriVeri[] = list.map((r) => ({
    id: r.id,
    businessId: r.business_id,
    rating: r.rating,
    title: r.title,
    content: r.content,
    helpfulCount: r.helpful_count,
    status: r.status,
    createdAt: r.created_at,
    displayName: r.user_id ? (profileMap.get(r.user_id) ?? null) : null,
    ownerReply: r.owner_reply,
    ownerRepliedAt: r.owner_replied_at,
  }));

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Yorumlar"
        description={
          unreplied > 0
            ? `${list.length} yorum · ${unreplied} yanıt bekliyor`
            : `${list.length} yorum`
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<StarIcon />}
            title="Henüz yorum yok"
            description="İşletmenize yapılan yorumlar burada görünür."
          />
        ) : (
          <PanelBolumKarti noPadding>
            <YorumlarIstemcisi
              reviews={reviewRows}
              businessMap={businessMap}
              showBusinessName={showBusinessName}
            />
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}

function StarIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}
