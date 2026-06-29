'use client';

import { useState } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';

export interface SmartFeedEvent {
  event_id: string;
  event_type: string;
  business_id: string;
  business_name: string;
  created_at: string;
  ref_type: string | null;
  ref_id: string | null;
  payload: Record<string, unknown>;
}

function eventTypeLabel(type: string): string {
  const map: Record<string, string> = {
    new_review: 'Yeni Yorum',
    new_menu_item: 'Yeni Ürün',
    price_update: 'Fiyat Güncelleme',
    business_update: 'İşletme Güncellemesi',
  };
  return map[type] ?? type;
}

function FeedCard({ item }: { item: SmartFeedEvent }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4 flex flex-col gap-2">
      <span className="text-xs font-[700] uppercase tracking-wide text-muted">
        {eventTypeLabel(item.event_type)}
      </span>
      <a
        href={`/isletme/${item.business_id}`}
        className="text-base font-[800] text-textStrong hover:text-primary"
      >
        {item.business_name}
      </a>
      {Object.entries(item.payload ?? {}).slice(0, 2).map(([k, v]) =>
        typeof v === 'string' || typeof v === 'number' ? (
          <p key={k} className="text-sm text-muted">
            {String(v)}
          </p>
        ) : null,
      )}
      <span className="text-xs text-muted">
        {new Date(item.created_at).toLocaleDateString('tr-TR')}
      </span>
    </div>
  );
}

type Props = {
  initialItems: SmartFeedEvent[];
};

export default function AkilliAkisIstemcisi({ initialItems }: Props) {
  const [items, setItems] = useState<SmartFeedEvent[]>(initialItems);
  const [offset, setOffset] = useState(initialItems.length);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(initialItems.length === 20);

  async function loadMore() {
    if (loading) return;
    setLoading(true);
    try {
      const supabase = createSupabaseBrowserClient();
      const { data } = (await (supabase as any).rpc('get_smart_feed_v2', {
        p_limit: 20,
        p_offset: offset,
      })) as { data: SmartFeedEvent[] | null };
      const newItems = data ?? [];
      setItems((prev) => [...prev, ...newItems]);
      setOffset((prev) => prev + newItems.length);
      setHasMore(newItems.length === 20);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col gap-4 p-4 max-w-2xl mx-auto">
      <h1 className="text-xl font-[900] text-textStrong">Akıllı Akış</h1>
      <div className="flex flex-col gap-3">
        {items.map((item) => (
          <FeedCard key={item.event_id} item={item} />
        ))}
      </div>
      {items.length === 0 && !loading && (
        <div className="rounded-xl border border-border bg-card p-10 text-center">
          <p className="text-sm text-muted">Henüz akış öğesi bulunamadı.</p>
        </div>
      )}
      {hasMore && (
        <button
          onClick={loadMore}
          disabled={loading}
          className="w-full rounded-xl border border-border bg-card py-3 text-sm font-[700] text-textStrong disabled:opacity-50"
        >
          {loading ? 'Yükleniyor...' : 'Daha fazla yükle'}
        </button>
      )}
    </div>
  );
}
