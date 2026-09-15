import type { Metadata } from 'next';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { NotFoundFallback } from '@/src/ui/acik/bulunamadi';
import { OyVermeYuzeyi } from './oy-verme-yuzeyi';

export const revalidate = 0; // her istekte taze

type Props = { params: Promise<{ token: string }> };

// RLS token'ı JWT'de taşımadığı için satır bazlı politikayla ifade edilemiyor
// (SELECT politikaları owner/üyelik istiyor, oturumsuz ziyaretçi için
// auth.uid() NULL — doğrudan .select() önceden her zaman boş/"bulunamadı"
// dönüyordu). SECURITY DEFINER RPC token'ı doğrulayıp veriyi dar bir
// yüzeyden dönüyor.
type CollabListPayload = {
  error?: string;
  id: string;
  name: string;
  description: string | null;
  items: Array<{
    id: string;
    business_id: string;
    name: string;
    slug: string;
    category: string | null;
    city: string | null;
    district: string | null;
    up_votes: number;
    down_votes: number;
  }>;
};

async function fetchCollabList(token: string): Promise<CollabListPayload | null> {
  const supabase = createSupabasePublicClient();
  const { data, error } = await supabase.rpc('get_collab_list_by_token_v1', { p_token: token });
  if (error) return null;
  const payload = data as CollabListPayload;
  if (!payload || payload.error) return null;
  return payload;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { token } = await params;
  const list = await fetchCollabList(token);

  if (!list) return { title: 'Grup Karar' };
  return {
    title: `${list.name} — Oy Ver`,
    robots: { index: false, follow: false },
  };
}

export default async function OyVerPage({ params }: Props) {
  const { token } = await params;
  const list = await fetchCollabList(token);

  if (!list) {
    return (
      <NotFoundFallback
        title="Davet bulunamadı"
        message="Bu grup karar daveti artık geçerli değil ya da bağlantı hatalı."
        hint="Daveti gönderen kişiden yeni bir bağlantı isteyin."
      />
    );
  }

  return (
    <main className="min-h-screen bg-bg px-4 py-10">
      <div className="mx-auto max-w-lg">
        <div className="mb-6 text-center">
          <p className="text-xs font-extrabold uppercase tracking-widest text-primary">Grup Karar</p>
          <h1 className="mt-1 text-2xl font-black text-textStrong">{list.name}</h1>
          {list.description && <p className="mt-1 text-sm text-muted">{list.description}</p>}
        </div>

        <OyVermeYuzeyi
          token={token}
          items={list.items.map((item) => ({
            id: item.id,
            businessId: item.business_id,
            businessName: item.name,
            businessSlug: item.slug,
            category: item.category,
            location: [item.district, item.city].filter(Boolean).join(', '),
            upVotes: item.up_votes,
            downVotes: item.down_votes,
          }))}
        />
      </div>
    </main>
  );
}
