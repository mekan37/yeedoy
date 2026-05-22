'use client';

import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

export function GelenKutusuRealtimeYenileyici({ userId }: { userId: string }) {
  const router = useRouter();
  const channelRef = useRef<ReturnType<ReturnType<typeof createSupabaseBrowserClient>['channel']> | null>(null);

  useEffect(() => {
    if (!userId) return;
    const supabase = createSupabaseBrowserClient();

    const channel = supabase
      .channel(`notifications:${userId}`)
      .on(
        'postgres_changes' as any,
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `user_id=eq.${userId}`,
        },
        (payload: any) => {
          const notif = payload.new as { title?: string; body?: string };
          toast(notif.title ?? 'Yeni bildirim', 'info');
          router.refresh();
        },
      )
      .subscribe();

    channelRef.current = channel;
    return () => {
      supabase.removeChannel(channel);
    };
  }, [userId, router]);

  return null;
}
