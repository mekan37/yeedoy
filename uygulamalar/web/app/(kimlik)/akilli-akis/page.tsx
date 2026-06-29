import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import AkilliAkisIstemcisi from '@/src/ui/bolumler/akilli-akis-istemcisi';
import type { SmartFeedEvent } from '@/src/ui/bolumler/akilli-akis-istemcisi';

export const metadata: Metadata = {
  title: 'Akıllı Akış | Yeedoy',
  robots: { index: false, follow: false },
};

export default async function AkilliAkisPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = (await (supabase as any).rpc('get_smart_feed_v2', {
    p_limit: 20,
    p_offset: 0,
  })) as { data: SmartFeedEvent[] | null };
  return <AkilliAkisIstemcisi initialItems={data ?? []} />;
}
