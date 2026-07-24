import type { Metadata } from 'next';
import Link from 'next/link';
import { Star, Megaphone, TrendingUp, Gift, User, Receipt, Bell, type LucideIcon } from 'lucide-react';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import {
  HepsiniOkunduButonu,
  BildirimiOkunduButonu,
  BildirimiSilButonu,
  EskiBildirimleriSilButonu,
} from './okundu-dugmesi';
import { GelenKutusuRealtimeYenileyici } from './realtime-yenileyici';

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

// Bildirim tipi → Türkçe etiket + renk
const TYPE_META: Record<string, { label: string; icon: LucideIcon; color: string }> = {
  review:     { label: 'Yorum', icon: Star, color: 'text-warning' },
  campaign:   { label: 'Kampanya', icon: Megaphone, color: 'text-primary' },
  price_alert:{ label: 'Fiyat Alarmı', icon: TrendingUp, color: 'text-success' },
  loyalty:    { label: 'Sadakat', icon: Gift, color: 'text-info' },
  follow:     { label: 'Takip', icon: User, color: 'text-slate' },
  order:      { label: 'Sipariş', icon: Receipt, color: 'text-success' },
  system:     { label: 'Sistem', icon: Bell, color: 'text-muted' },
};

function getTypeMeta(type: string) {
  return TYPE_META[type] ?? { label: type, icon: Bell, color: 'text-muted' };
}

function groupByDate(list: NotifRow[]) {
  const bugun = new Date();
  bugun.setHours(0, 0, 0, 0);
  const buHafta = new Date(bugun);
  buHafta.setDate(buHafta.getDate() - 7);

  const groups: { baslik: string; items: NotifRow[] }[] = [
    { baslik: 'Bugün', items: [] },
    { baslik: 'Bu Hafta', items: [] },
    { baslik: 'Eski', items: [] },
  ];

  for (const n of list) {
    const d = new Date(n.created_at);
    if (d >= bugun) groups[0].items.push(n);
    else if (d >= buHafta) groups[1].items.push(n);
    else groups[2].items.push(n);
  }

  return groups.filter((g) => g.items.length > 0);
}

interface PageProps {
  searchParams: Promise<Record<string, string | undefined>>;
}

export default async function InboxPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const filterType = params.tip ?? 'hepsi';

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
      .limit(100) as { data: NotifRow[] | null; error: { code?: string; message?: string } | null };

    if (error && error.code === '42P01') {
      const { data: data2, error: error2 } = await (supabase as any)
        .from('user_notifications')
        .select('id, type, title, body, is_read, created_at, action_url')
        .eq('user_id', user!.id)
        .order('created_at', { ascending: false })
        .limit(100) as { data: NotifRow[] | null; error: { code?: string } | null };
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

  // Tip filtresi
  const filteredList = filterType === 'hepsi'
    ? list
    : list.filter((n) => n.type === filterType);

  const unreadCount = list.filter((n) => !n.is_read).length;
  const filteredUnread = filteredList.filter((n) => !n.is_read).length;

  // Mevcut tipler (tab navigation için)
  const mevcut_tipler = [...new Set(list.map((n) => n.type))];
  const groups = groupByDate(filteredList);

  return (
    <main className="min-h-screen bg-bg">
      {/* C-2: Realtime bildirim güncelleyici */}
      <GelenKutusuRealtimeYenileyici userId={user!.id} />
      <div className="mx-auto max-w-2xl px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">
          ← Profilime Dön
        </Link>

        {/* Başlık + aksiyon bar */}
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-black text-textStrong">Bildirimler</h1>
            {unreadCount > 0 && (
              <span className="rounded-full bg-primary px-2 py-0.5 text-[11px] font-bold text-white">
                {unreadCount}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            {filteredUnread > 0 && <HepsiniOkunduButonu />}
            <EskiBildirimleriSilButonu />
          </div>
        </div>

        {/* Tip filtreleri */}
        {mevcut_tipler.length > 1 && (
          <div className="mb-6 flex flex-wrap gap-2">
            <Link
              href="/gelen-kutusu"
              className={`rounded-full px-3 py-1.5 text-xs font-bold transition-colors ${
                filterType === 'hepsi'
                  ? 'bg-primary text-white'
                  : 'border border-border bg-card text-muted hover:border-primary/30'
              }`}
            >
              Hepsi ({list.length})
            </Link>
            {mevcut_tipler.map((type) => {
              const meta = getTypeMeta(type);
              const cnt = list.filter((n) => n.type === type).length;
              const active = filterType === type;
              return (
                <Link
                  key={type}
                  href={`/gelen-kutusu?tip=${type}`}
                  className={`rounded-full px-3 py-1.5 text-xs font-bold transition-colors ${
                    active
                      ? 'bg-primary text-white'
                      : 'border border-border bg-card text-muted hover:border-primary/30'
                  }`}
                >
                  <meta.icon className="mr-1 inline h-3.5 w-3.5" aria-hidden="true" /> {meta.label} ({cnt})
                </Link>
              );
            })}
          </div>
        )}

        {tableError ? (
          <div className="rounded-2xl border border-border bg-card p-8 text-center">
            <p className="font-bold text-textStrong mb-1">Bildirimler şu an kullanılamıyor</p>
            <p className="text-sm text-muted">Lütfen daha sonra tekrar deneyin.</p>
          </div>
        ) : filteredList.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <div className="mb-3 flex justify-center">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                <path d="M13.73 21a2 2 0 0 1-3.46 0" />
              </svg>
            </div>
            <p className="font-bold text-textStrong">
              {filterType === 'hepsi' ? 'Bildiriminiz yok' : `${getTypeMeta(filterType).label} bildirimi yok`}
            </p>
            <p className="mt-2 text-sm text-muted">Yeni bildirimler burada görünecek.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-6">
            {groups.map((group) => (
              <section key={group.baslik}>
                <p className="mb-2 text-[11px] font-black uppercase tracking-wide text-muted">
                  {group.baslik}
                </p>
                <div className="flex flex-col gap-2">
                  {group.items.map((n) => {
                    const meta = getTypeMeta(n.type);
                    return (
                      <div
                        key={n.id}
                        className={`rounded-2xl border p-4 transition-colors ${
                          n.is_read ? 'border-border bg-card' : 'border-primary/30 bg-primary/5'
                        }`}
                      >
                        <div className="flex items-start gap-3">
                          {/* Okunmadı noktası */}
                          <div className="mt-2 shrink-0">
                            <span className={`block h-2 w-2 rounded-full ${n.is_read ? 'bg-transparent' : 'bg-primary'}`} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-2">
                              <div className="flex items-center gap-1.5">
                                <meta.icon className={`h-4 w-4 shrink-0 ${meta.color}`} aria-hidden="true" />
                                <p className={`text-sm leading-snug ${n.is_read ? 'text-textStrong' : 'font-bold text-textStrong'}`}>
                                  {n.title}
                                </p>
                              </div>
                              <span className="shrink-0 text-[11px] text-muted whitespace-nowrap">
                                {formatRelativeTime(n.created_at)}
                              </span>
                            </div>
                            {n.body && (
                              <p className="mt-1 text-[12px] text-muted leading-relaxed">{n.body}</p>
                            )}
                            <div className="mt-2 flex items-center gap-3">
                              {n.action_url && (
                                <Link href={n.action_url} className="inline-flex text-[12px] font-bold text-primary hover:underline cursor-pointer">
                                  Görüntüle →
                                </Link>
                              )}
                              {!n.is_read && <BildirimiOkunduButonu notifId={n.id} />}
                              <BildirimiSilButonu notifId={n.id} />
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </section>
            ))}
          </div>
        )}

        {/* Bildirim Ayarları Linki */}
        <div className="mt-8 border-t border-border pt-6">
          <Link
            href="/profil/ayarlar?sekme=bildirimler"
            className="inline-flex items-center gap-2 text-sm font-bold text-muted hover:text-primary"
          >
            <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
              <path d="M13.73 21a2 2 0 0 1-3.46 0" />
            </svg>
            Bildirim Tercihlerini Düzenle
          </Link>
        </div>
      </div>
    </main>
  );
}
