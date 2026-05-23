import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';

export const metadata: Metadata = {
  title: 'Bildirimler | Yeedoy',
  robots: { index: false, follow: false },
};

type NotifRow = {
  id: string;
  type: string;
  title: string;
  body: string | null;
  is_read: boolean;
  created_at: string;
  action_url: string | null;
};

function formatRelativeTime(isoString: string): string {
  const diff = Date.now() - new Date(isoString).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 1) return 'Az önce';
  if (minutes < 60) return `${minutes}d önce`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}s önce`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}g önce`;
  return new Date(isoString).toLocaleDateString('tr-TR');
}

export default async function InboxPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  let list: NotifRow[] = [];
  let tableError = false;

  try {
    const { data, error } = await (supabase as any)
      .from('notifications')
      .select('id, type, title, body, is_read, created_at, action_url')
      .eq('user_id', user!.id)
      .order('created_at', { ascending: false })
      .limit(50) as { data: NotifRow[] | null; error: { code?: string; message?: string } | null };

    if (error && error.code === '42P01') {
      // Table does not exist — try user_notifications
      const { data: data2, error: error2 } = await (supabase as any)
        .from('user_notifications')
        .select('id, type, title, body, is_read, created_at, action_url')
        .eq('user_id', user!.id)
        .order('created_at', { ascending: false })
        .limit(50) as { data: NotifRow[] | null; error: { code?: string } | null };
      if (!error2 || error2.code !== '42P01') {
        list = data2 ?? [];
      } else {
        tableError = true;
      }
    } else {
      list = data ?? [];
    }
  } catch {
    list = [];
  }

  const unreadCount = list.filter((n) => !n.is_read).length;

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">
          ← Profilime Dön
        </Link>

        {/* Header with unread badge and mark-all-read */}
        <div className="mb-6 flex items-center justify-between gap-4">
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-[900] text-textStrong">Bildirimler</h1>
            {unreadCount > 0 && (
              <span className="rounded-full bg-primary px-2 py-0.5 text-[11px] font-[700] text-white">
                {unreadCount}
              </span>
            )}
          </div>
          {unreadCount > 0 && (
            <button
              type="button"
              className="rounded-xl border border-border bg-card px-3 py-1.5 text-xs font-[700] text-textStrong hover:border-primary/30 transition-colors cursor-pointer"
              title="Hepsini okundu olarak işaretle (yakında)"
            >
              Hepsini Okundu İşaretle
            </button>
          )}
        </div>

        {tableError ? (
          <div className="rounded-2xl border border-border bg-card p-8 text-center">
            <p className="font-[700] text-textStrong mb-1">Bildirimler şu an kullanılamıyor</p>
            <p className="text-sm text-muted">Lütfen daha sonra tekrar deneyin.</p>
          </div>
        ) : list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <div className="mb-3 flex justify-center">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                <path d="M13.73 21a2 2 0 0 1-3.46 0" />
              </svg>
            </div>
            <p className="font-[700] text-textStrong">Bildiriminiz yok</p>
            <p className="mt-2 text-sm text-muted">Yeni bildirimler burada görünecek.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {list.map((n) => (
              <div
                key={n.id}
                className={`rounded-2xl border p-4 transition-colors ${
                  n.is_read
                    ? 'border-border bg-card'
                    : 'border-primary/30 bg-primary/5'
                }`}
              >
                <div className="flex items-start gap-3">
                  {/* Unread dot */}
                  <div className="mt-1.5 shrink-0">
                    {!n.is_read ? (
                      <span className="block h-2 w-2 rounded-full bg-primary" />
                    ) : (
                      <span className="block h-2 w-2 rounded-full bg-transparent" />
                    )}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <p className={`text-sm leading-snug ${n.is_read ? 'text-textStrong' : 'font-[700] text-textStrong'}`}>
                        {n.title}
                      </p>
                      <span className="shrink-0 text-[11px] text-muted whitespace-nowrap">
                        {formatRelativeTime(n.created_at)}
                      </span>
                    </div>
                    {n.body && (
                      <p className="mt-1 text-[12px] text-muted leading-relaxed">{n.body}</p>
                    )}
                    {n.action_url && (
                      <Link
                        href={n.action_url}
                        className="mt-2 inline-flex text-[12px] font-[700] text-primary hover:underline cursor-pointer"
                      >
                        Görüntüle →
                      </Link>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
