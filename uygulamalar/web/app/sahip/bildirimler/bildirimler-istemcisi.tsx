'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';

// ── Types ─────────────────────────────────────────────────────────────────────

type NotifTag = 'Önemli' | 'Kampanya' | 'Sistem' | 'Rezervasyon';
type NotifType = 'review' | 'campaign' | 'report' | 'reservation' | 'favorite' | 'campaign_perf' | 'security';

interface NotifAction { label: string; primary?: boolean; icon: string; href?: string; }

interface Notification {
  id: string;
  type: NotifType;
  title: string;
  body: string;
  tag: NotifTag;
  time: string;
  dateStr: string;
  isRead: boolean;
  quote?: string;
  reviewer?: { name: string; initials: string; rating: number; time: string };
  actions: NotifAction[];
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const MOCK: Notification[] = [
  {
    id: '1', type: 'review',
    title: 'Yeni yorumunuz var',
    body: 'Seda K. tarafından No 18 Coffee Co. için yeni bir yorum yapıldı.',
    tag: 'Önemli', time: '2 dakika önce', dateStr: '6 Haziran 2025 · 10:42', isRead: false,
    quote: '"Kahveleri harika! Özellikle flat white favori oldu. Ortam çok sıcak ve çalışanlar ilgili. Kesinlikle tekrar geleceğim."',
    reviewer: { name: 'Seda K.', initials: 'SK', rating: 5, time: '2 dakika önce' },
    actions: [
      { label: 'Yorumu Görüntüle', primary: true, icon: 'review', href: '/owner/reviews' },
      { label: 'Yoruma Yanıt Ver', icon: 'reply', href: '/owner/reviews' },
      { label: 'Tüm Yorumları Görüntüle', icon: 'list', href: '/owner/reviews' },
    ],
  },
  {
    id: '2', type: 'campaign',
    title: 'Kampanyanız başladı',
    body: '"Hafta içi kahve %20 indirim" kampanyanız yayına alındı.',
    tag: 'Kampanya', time: '15 dakika önce', dateStr: '6 Haziran 2025 · 10:29', isRead: false,
    actions: [
      { label: 'Kampanyayı Görüntüle', primary: true, icon: 'campaign', href: '/owner/marketing/campaigns' },
      { label: 'Tüm Kampanyalar', icon: 'list', href: '/owner/marketing/campaigns' },
    ],
  },
  {
    id: '3', type: 'report',
    title: 'Günlük rapor hazır',
    body: 'Dünkü performans raporunuz hazır. Hemen görüntüleyebilirsiniz.',
    tag: 'Sistem', time: '1 saat önce', dateStr: '6 Haziran 2025 · 09:42', isRead: false,
    actions: [
      { label: 'Raporu Görüntüle', primary: true, icon: 'chart', href: '/sahip/analitik' },
      { label: 'İstatistikler', icon: 'list', href: '/sahip/analitik' },
    ],
  },
  {
    id: '4', type: 'reservation',
    title: 'Rezervasyon alındı',
    body: 'Yarın 19:00 için yeni bir rezervasyon aldınız.',
    tag: 'Rezervasyon', time: '2 saat önce', dateStr: '6 Haziran 2025 · 08:42', isRead: false,
    actions: [
      { label: 'Rezervasyonu Görüntüle', primary: true, icon: 'calendar', href: '/sahip/rezervasyonlar' },
      { label: 'Tüm Rezervasyonlar', icon: 'list', href: '/sahip/rezervasyonlar' },
    ],
  },
  {
    id: '5', type: 'favorite',
    title: 'Yeni favori',
    body: 'Bir kullanıcı işletmenizi favorilerine ekledi.',
    tag: 'Sistem', time: '4 saat önce', dateStr: '6 Haziran 2025 · 06:42', isRead: true,
    actions: [
      { label: 'İstatistikleri Görüntüle', primary: true, icon: 'chart', href: '/sahip/analitik' },
    ],
  },
  {
    id: '6', type: 'campaign_perf',
    title: 'Kampanya performansı',
    body: '"Tatlılarda %15 İndirim" kampanyanız iyi performans gösteriyor!',
    tag: 'Kampanya', time: '1 gün önce', dateStr: '5 Haziran 2025 · 10:42', isRead: true,
    actions: [
      { label: 'Kampanyayı Görüntüle', primary: true, icon: 'campaign', href: '/owner/marketing/campaigns' },
    ],
  },
  {
    id: '7', type: 'security',
    title: 'Güvenlik bildirimi',
    body: 'Hesabınıza yeni bir cihazdan giriş yapıldı.',
    tag: 'Önemli', time: '2 gün önce', dateStr: '4 Haziran 2025 · 10:42', isRead: true,
    actions: [
      { label: 'Güvenlik Ayarları', primary: true, icon: 'shield', href: '/owner/settings' },
    ],
  },
];

// ── Tab definitions ───────────────────────────────────────────────────────────

const TABS = [
  { key: 'all',       label: 'Tümü' },
  { key: 'unread',    label: 'Okunmamış' },
  { key: 'important', label: 'Önemli' },
  { key: 'system',    label: 'Sistem' },
  { key: 'campaign',  label: 'Kampanya' },
] as const;

type TabKey = typeof TABS[number]['key'];

function filterByTab(items: Notification[], tab: TabKey): Notification[] {
  switch (tab) {
    case 'unread':    return items.filter((n) => !n.isRead);
    case 'important': return items.filter((n) => n.tag === 'Önemli');
    case 'system':    return items.filter((n) => n.tag === 'Sistem' || n.tag === 'Rezervasyon');
    case 'campaign':  return items.filter((n) => n.tag === 'Kampanya');
    default:          return items;
  }
}

function countForTab(items: Notification[], tab: TabKey): number {
  return filterByTab(items, tab).length;
}

// ── Tag badge ─────────────────────────────────────────────────────────────────

const TAG_STYLES: Record<NotifTag, string> = {
  'Önemli':      'bg-red-50 text-red-600',
  'Kampanya':    'bg-purple-50 text-purple-600',
  'Sistem':      'bg-slate-100 text-slate-500',
  'Rezervasyon': 'bg-blue-50 text-blue-600',
};

function TagBadge({ tag }: { tag: NotifTag }) {
  return (
    <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-[800] ${TAG_STYLES[tag]}`}>
      {tag}
    </span>
  );
}

// ── Notification icon ─────────────────────────────────────────────────────────

const ICON_STYLES: Record<NotifType, { bg: string; text: string }> = {
  review:       { bg: 'bg-green-100',  text: 'text-green-600' },
  campaign:     { bg: 'bg-purple-100', text: 'text-purple-600' },
  report:       { bg: 'bg-orange-100', text: 'text-orange-600' },
  reservation:  { bg: 'bg-blue-100',   text: 'text-blue-600' },
  favorite:     { bg: 'bg-rose-100',   text: 'text-rose-500' },
  campaign_perf:{ bg: 'bg-red-100',    text: 'text-red-500' },
  security:     { bg: 'bg-slate-100',  text: 'text-slate-500' },
};

function NotifIcon({ type, size = 'sm' }: { type: NotifType; size?: 'sm' | 'lg' }) {
  const { bg, text } = ICON_STYLES[type];
  const dim = size === 'lg' ? 'h-16 w-16' : 'h-11 w-11';
  const iconDim = size === 'lg' ? 'h-8 w-8' : 'h-5 w-5';
  return (
    <div className={`${dim} ${bg} flex shrink-0 items-center justify-center rounded-full`}>
      <span className={text}>
        <TypeIcon type={type} className={iconDim} />
      </span>
    </div>
  );
}

// ── Main component ─────────────────────────────────────────────────────────────

export function NotificationsClient() {
  const [all, setAll] = useState<Notification[]>(MOCK);
  const [selectedId, setSelectedId] = useState<string>(MOCK[0].id);
  const [tab, setTab] = useState<TabKey>('all');
  const [search, setSearch] = useState('');
  const [catFilter, setCatFilter] = useState<string>('all');

  const selected = useMemo(() => all.find((n) => n.id === selectedId) ?? all[0], [all, selectedId]);

  const filtered = useMemo(() => {
    let items = filterByTab(all, tab);
    if (search) items = items.filter((n) => n.title.toLowerCase().includes(search.toLowerCase()) || n.body.toLowerCase().includes(search.toLowerCase()));
    if (catFilter !== 'all') items = items.filter((n) => n.tag === catFilter);
    return items;
  }, [all, tab, search, catFilter]);

  function markRead(id: string) {
    setAll((prev) => prev.map((n) => n.id === id ? { ...n, isRead: true } : n));
  }

  function handleSelect(id: string) {
    setSelectedId(id);
    markRead(id);
  }

  function handleDelete(id: string) {
    setAll((prev) => {
      const next = prev.filter((n) => n.id !== id);
      if (selectedId === id && next.length > 0) setSelectedId(next[0].id);
      return next;
    });
  }

  return (
    <div className="mx-auto max-w-[1200px] p-6">
      {/* Page header */}
      <div className="mb-6">
        <h1 className="text-[26px] font-[900] text-[#1a1a2e]">Bildirimler</h1>
        <p className="mt-1 text-sm text-[#64748b]">İşletmenizle ilgili tüm bildirimleri buradan görüntüleyin.</p>
      </div>

      {/* Tabs */}
      <div className="mb-5 flex items-center gap-1 border-b border-[#f0f0f0]">
        {TABS.map((t) => {
          const count = countForTab(all, t.key);
          const active = tab === t.key;
          return (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`relative pb-3 pt-1 px-3 text-[13px] font-[800] transition-colors ${
                active ? 'text-[#dc2626]' : 'text-[#64748b] hover:text-[#1a1a2e]'
              }`}
            >
              {t.label}
              {count > 0 && (
                <span className={`ml-1.5 rounded-full px-1.5 py-0.5 text-[10px] font-[900] ${
                  active ? 'bg-[#dc2626] text-white' : 'bg-[#f1f5f9] text-[#64748b]'
                }`}>
                  {count}
                </span>
              )}
              {active && (
                <span className="absolute bottom-0 left-0 right-0 h-[2px] rounded-full bg-[#dc2626]" />
              )}
            </button>
          );
        })}
      </div>

      {/* Two-column layout */}
      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[1fr_340px]">
        {/* ── Left: list ─────────────────────────────────────────────── */}
        <div className="flex flex-col gap-4">
          <div className="rounded-2xl border border-[#f0f0f0] bg-white shadow-sm">
            {/* Search + filter */}
            <div className="flex items-center gap-3 border-b border-[#f0f0f0] px-4 py-3">
              <div className="relative flex-1">
                <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#94a3b8]" />
                <input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Bildirim ara..."
                  className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] py-2 pl-9 pr-3 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20"
                />
              </div>
              <select
                value={catFilter}
                onChange={(e) => setCatFilter(e.target.value)}
                className="rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2 text-sm font-[700] text-[#475569] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20"
              >
                <option value="all">Tüm Kategoriler</option>
                <option value="Önemli">Önemli</option>
                <option value="Kampanya">Kampanya</option>
                <option value="Sistem">Sistem</option>
                <option value="Rezervasyon">Rezervasyon</option>
              </select>
              <button className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-[#e2e8f0] bg-[#f8fafc] text-[#64748b] transition hover:bg-[#f1f5f9]">
                <FilterIcon className="h-4 w-4" />
              </button>
            </div>

            {/* Notification rows */}
            {filtered.length === 0 ? (
              <div className="flex flex-col items-center gap-2 py-16 text-center">
                <BellOffIcon className="h-10 w-10 text-[#cbd5e1]" />
                <p className="text-sm font-[700] text-[#1a1a2e]">Bildirim bulunamadı</p>
                <p className="text-xs text-[#94a3b8]">Arama veya filtre kriterlerinizi değiştirin.</p>
              </div>
            ) : (
              <div>
                {filtered.map((notif, idx) => {
                  const isSelected = notif.id === selectedId;
                  return (
                    <button
                      key={notif.id}
                      onClick={() => handleSelect(notif.id)}
                      className={`flex w-full items-start gap-4 px-5 py-4 text-left transition-colors ${
                        isSelected ? 'bg-[#fff5f5]' : 'hover:bg-[#fafafa]'
                      } ${idx > 0 ? 'border-t border-[#f0f0f0]' : ''}`}
                    >
                      <NotifIcon type={notif.type} />
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <span className={`text-[13px] font-[800] ${notif.isRead ? 'text-[#475569]' : 'text-[#1a1a2e]'}`}>
                            {notif.title}
                          </span>
                          <TagBadge tag={notif.tag} />
                        </div>
                        <p className="mt-0.5 truncate text-xs text-[#64748b]">{notif.body}</p>
                        <p className="mt-1 text-[11px] text-[#94a3b8]">{notif.time}</p>
                      </div>
                      <div className="flex shrink-0 items-center gap-2">
                        {!notif.isRead && (
                          <span className="h-2 w-2 rounded-full bg-blue-500" />
                        )}
                        <ChevronRightIcon className="h-4 w-4 text-[#cbd5e1]" />
                      </div>
                    </button>
                  );
                })}
              </div>
            )}

            {/* Pagination */}
            {filtered.length > 0 && (
              <div className="flex items-center justify-between border-t border-[#f0f0f0] px-5 py-3">
                <span className="text-xs text-[#94a3b8]">Toplam {all.length} bildirim</span>
                <div className="flex items-center gap-1">
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg border border-[#e2e8f0] text-[#94a3b8] hover:bg-[#f8fafc]">
                    <ChevLeftIcon className="h-3.5 w-3.5" />
                  </button>
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg border border-[#dc2626] bg-[#dc2626] text-[11px] font-[900] text-white">1</button>
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg border border-[#e2e8f0] text-[11px] font-[700] text-[#64748b] hover:bg-[#f8fafc]">2</button>
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg border border-[#e2e8f0] text-[#94a3b8] hover:bg-[#f8fafc]">
                    <ChevRightIcon className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* ── Right: Detail panel ────────────────────────────────────── */}
        {selected && (
          <div className="flex flex-col gap-4">
            <div className="rounded-2xl border border-[#f0f0f0] bg-white shadow-sm">
              {/* Detail header */}
              <div className="flex items-center justify-between border-b border-[#f0f0f0] px-4 py-3">
                <span className="text-[13px] font-[800] text-[#1a1a2e]">Bildirim Detayı</span>
                <div className="flex items-center gap-1">
                  <button
                    onClick={() => handleDelete(selected.id)}
                    className="flex h-7 w-7 items-center justify-center rounded-lg text-[#94a3b8] transition hover:bg-[#fff1f2] hover:text-[#dc2626]"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg text-[#94a3b8] transition hover:bg-[#f1f5f9]">
                    <DotsIcon className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Detail body */}
              <div className="p-5">
                {/* Large icon + title */}
                <div className="flex flex-col items-center text-center">
                  <NotifIcon type={selected.type} size="lg" />
                  <div className="mt-3 flex items-center gap-2">
                    <span className="text-base font-[900] text-[#1a1a2e]">{selected.title}</span>
                    <TagBadge tag={selected.tag} />
                  </div>
                  <p className="mt-1 text-[12px] text-[#94a3b8]">{selected.dateStr}</p>
                </div>

                {/* Body */}
                <p className="mt-4 text-[13px] leading-relaxed text-[#475569]">{selected.body}</p>

                {/* Quote */}
                {selected.quote && (
                  <p className="mt-3 rounded-xl bg-[#f8fafc] px-4 py-3 text-[13px] italic leading-relaxed text-[#475569]">
                    {selected.quote}
                  </p>
                )}

                {/* Reviewer */}
                {selected.reviewer && (
                  <div className="mt-3 flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#7f1d1d] text-[12px] font-[900] text-white">
                      {selected.reviewer.initials}
                    </div>
                    <div className="flex-1">
                      <span className="text-[13px] font-[800] text-[#1a1a2e]">{selected.reviewer.name}</span>
                      <div className="flex items-center gap-1">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <StarFilledIcon key={i} filled={i < selected.reviewer!.rating} />
                        ))}
                        <span className="ml-1 text-[12px] font-[800] text-[#f59e0b]">{selected.reviewer!.rating}.0</span>
                      </div>
                    </div>
                    <span className="text-[11px] text-[#94a3b8]">{selected.reviewer.time}</span>
                  </div>
                )}

                {/* Related business */}
                <div className="mt-5 border-t border-[#f0f0f0] pt-4">
                  <p className="mb-2 text-[11px] font-[800] uppercase tracking-wider text-[#94a3b8]">İlgili İşletme</p>
                  <div className="flex items-center gap-3 rounded-xl border border-[#f0f0f0] bg-[#fafafa] p-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#7f1d1d] text-[13px] font-[900] text-white">N</div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1.5">
                        <span className="text-[13px] font-[800] text-[#1a1a2e]">No 18 Coffee Co.</span>
                        <span className="rounded-full bg-[#dcfce7] px-2 py-0.5 text-[10px] font-[800] text-[#16a34a]">Ana İşletme</span>
                      </div>
                      <p className="text-[11px] text-[#94a3b8]">Kafe · Yenimahalle, Ankara</p>
                    </div>
                    <Link href="/owner/businesses" className="shrink-0 text-[12px] font-[800] text-[#dc2626] hover:underline">
                      İşletmeye Git
                    </Link>
                  </div>
                </div>

                {/* Actions */}
                <div className="mt-4 border-t border-[#f0f0f0] pt-4">
                  <p className="mb-3 text-[11px] font-[800] uppercase tracking-wider text-[#94a3b8]">İşlemler</p>
                  <div className="flex flex-col gap-2">
                    {selected.actions.map((action) => (
                      <Link
                        key={action.label}
                        href={action.href ?? '#'}
                        className={`flex w-full items-center gap-2.5 rounded-xl px-4 py-2.5 text-[13px] font-[800] transition ${
                          action.primary
                            ? 'bg-[#dc2626] text-white hover:opacity-90'
                            : 'border border-[#e2e8f0] text-[#475569] hover:bg-[#f8fafc]'
                        }`}
                      >
                        <ActionIcon icon={action.icon} primary={action.primary} />
                        {action.label}
                      </Link>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Bottom settings banner */}
      <div className="mt-5 flex items-center gap-4 rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-amber-100">
          <BellIcon className="h-5 w-5 text-amber-600" />
        </div>
        <div className="flex-1">
          <p className="text-[13px] font-[800] text-[#1a1a2e]">Bildirim tercihlerinizi özelleştirin</p>
          <p className="text-[12px] text-[#64748b]">Hangi bildirimleri alacağınızı ve nasıl alınacağını ayarlar sayfasından düzenleyebilirsiniz.</p>
        </div>
        <Link
          href="/sahip/ayarlar"
          className="shrink-0 flex items-center gap-1.5 rounded-xl border border-amber-300 bg-white px-4 py-2 text-[12px] font-[800] text-[#1a1a2e] transition hover:bg-amber-50"
        >
          <SettingsIcon className="h-4 w-4" />
          Bildirim Ayarları →
        </Link>
      </div>
    </div>
  );
}

// ── Helper: action icons ───────────────────────────────────────────────────────

function ActionIcon({ icon, primary }: { icon: string; primary?: boolean }) {
  const cls = `h-4 w-4 shrink-0 ${primary ? 'text-white' : 'text-[#64748b]'}`;
  switch (icon) {
    case 'review':   return <ReviewActionIcon className={cls} />;
    case 'reply':    return <ReplyIcon className={cls} />;
    case 'list':     return <ListIcon className={cls} />;
    case 'campaign': return <CampaignActionIcon className={cls} />;
    case 'chart':    return <ChartActionIcon className={cls} />;
    case 'calendar': return <CalendarIcon className={cls} />;
    case 'shield':   return <ShieldIcon className={cls} />;
    default:         return <ListIcon className={cls} />;
  }
}

// ── Helper: star rating ───────────────────────────────────────────────────────

function StarFilledIcon({ filled }: { filled: boolean }) {
  return (
    <svg className="h-3 w-3" viewBox="0 0 24 24" fill={filled ? '#f59e0b' : 'none'} stroke="#f59e0b" strokeWidth="2">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

// ── Notification type icon ────────────────────────────────────────────────────

function TypeIcon({ type, className }: { type: NotifType; className: string }) {
  switch (type) {
    case 'review':
      return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>;
    case 'campaign':
    case 'campaign_perf':
      return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>;
    case 'report':
      return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>;
    case 'reservation':
      return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>;
    case 'favorite':
      return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>;
    case 'security':
      return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>;
  }
}

// ── Icons ─────────────────────────────────────────────────────────────────────

function SearchIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>;
}
function FilterIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>;
}
function ChevronRightIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="9 18 15 12 9 6"/></svg>;
}
function ChevLeftIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="15 18 9 12 15 6"/></svg>;
}
function ChevRightIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="9 6 15 12 9 18"/></svg>;
}
function TrashIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>;
}
function DotsIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>;
}
function BellIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>;
}
function BellOffIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M13.73 21a2 2 0 0 1-3.46 0"/><path d="M18.63 13A17.888 17.888 0 0 1 18 8"/><path d="M6.26 6.26A5.86 5.86 0 0 0 6 8c0 7-3 9-3 9h14"/><path d="M18 8a6 6 0 0 0-9.33-5"/><line x1="1" y1="1" x2="23" y2="23"/></svg>;
}
function SettingsIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>;
}
function ReviewActionIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>;
}
function ReplyIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="9 17 4 12 9 7"/><path d="M20 18v-2a4 4 0 0 0-4-4H4"/></svg>;
}
function ListIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>;
}
function CampaignActionIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M3 11l19-9-9 19-2-8-8-2z"/></svg>;
}
function ChartActionIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>;
}
function CalendarIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>;
}
function ShieldIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>;
}
