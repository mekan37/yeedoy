import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { createSupabasePublicClient } from '@/src/lib/taban/acik';
import { OyVermeYuzeyi } from './oy-verme-yuzeyi';

export const revalidate = 0; // her istekte taze

type Props = { params: Promise<{ token: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { token } = await params;
  const supabase = createSupabasePublicClient();
  const { data } = await (supabase as any)
    .from('collab_lists')
    .select('name')
    .eq('invite_token', token)
    .single() as { data: { name: string } | null };

  if (!data) return { title: 'Grup Karar | Yeedoy' };
  return {
    title: `${data.name} — Oy Ver | Yeedoy`,
    robots: { index: false, follow: false },
  };
}

export default async function OyVerPage({ params }: Props) {
  const { token } = await params;
  const supabase = createSupabasePublicClient();

  const { data: list } = await (supabase as any)
    .from('collab_lists')
    .select('id, name, description')
    .eq('invite_token', token)
    .single() as { data: { id: string; name: string; description: string | null } | null };

  if (!list) notFound();

  // Listedeki işletmeler ve oy sayıları
  const { data: items } = await (supabase as any)
    .from('collab_list_items')
    .select('id, business_id, businesses(id, name, slug, category, city, district)')
    .eq('list_id', list.id) as { data: Array<{
      id: string;
      business_id: string;
      businesses: { id: string; name: string; slug: string; category: string | null; city: string | null; district: string | null };
    }> | null };

  const { data: votes } = await (supabase as any)
    .from('collab_list_votes')
    .select('item_id, vote')
    .eq('list_id', list.id) as { data: Array<{ item_id: string; vote: number }> | null };

  // Oy sayılarını grupla
  const voteCounts: Record<string, { up: number; down: number }> = {};
  for (const v of votes ?? []) {
    if (!voteCounts[v.item_id]) voteCounts[v.item_id] = { up: 0, down: 0 };
    if (v.vote === 1) voteCounts[v.item_id].up++;
    if (v.vote === -1) voteCounts[v.item_id].down++;
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
          listId={list.id}
          token={token}
          items={(items ?? []).map((item) => ({
            id: item.id,
            businessId: item.business_id,
            businessName: item.businesses.name,
            businessSlug: item.businesses.slug,
            category: item.businesses.category,
            location: [item.businesses.district, item.businesses.city].filter(Boolean).join(', '),
            upVotes: voteCounts[item.id]?.up ?? 0,
            downVotes: voteCounts[item.id]?.down ?? 0,
          }))}
        />
      </div>
    </main>
  );
}
