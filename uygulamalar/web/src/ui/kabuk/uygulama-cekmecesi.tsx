'use client';

import { useEffect, useRef, type ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Search, Trophy, Bell, User, Lightbulb, Heart, Inbox, FileText } from 'lucide-react';
import { useWebKabukStore } from '@/src/lib/web-kabuk-deposu';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { ThemeToggle } from '@/src/ui/bilesenler/tema-degistirici';

export interface DrawerSessionUser {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
}

interface AppDrawerProps {
  sessionUser: DrawerSessionUser | null;
  unreadCount: number;
}

const NAV_SECTIONS: { title: string; items: { href: string; label: string; icon: ReactNode }[] }[] = [
  {
    title: 'Keşfet',
    items: [
      { href: '/kesif',       label: 'Keşfet',    icon: <Search size={16} aria-hidden="true" /> },
      { href: '/arama',       label: 'Arama',     icon: <Search size={16} aria-hidden="true" /> },
      { href: '/en-iyiler',   label: 'En İyiler', icon: <Trophy size={16} aria-hidden="true" /> },
    ],
  },
  {
    title: 'Özellikler',
    items: [
      { href: '/fiyat-uyarilari', label: 'Fiyat Uyarıları', icon: <Bell size={16} aria-hidden="true" /> },
    ],
  },
];

const ACCOUNT_ITEMS: { href: string; label: string; icon: ReactNode; showBadge: boolean; requiresAuth: boolean }[] = [
  { href: '/favoriler',       label: 'Favorilerim',  icon: <Heart size={16} aria-hidden="true" />,     showBadge: false, requiresAuth: true  },
  { href: '/profil',          label: 'Profil',       icon: <User size={16} aria-hidden="true" />,      showBadge: false, requiresAuth: true  },
  { href: '/gelen-kutusu',    label: 'Gelen Kutusu', icon: <Inbox size={16} aria-hidden="true" />,     showBadge: true,  requiresAuth: true  },
  { href: '/oneriler',        label: 'Önerilerim',   icon: <Lightbulb size={16} aria-hidden="true" />, showBadge: false, requiresAuth: true  },
  { href: '/yasal',           label: 'Yasal',        icon: <FileText size={16} aria-hidden="true" />,  showBadge: false, requiresAuth: false },
];

export function AppDrawer({ sessionUser, unreadCount }: AppDrawerProps) {
  const { isDrawerOpen, closeDrawer } = useWebKabukStore();
  const router = useRouter();
  const searchRef = useRef<HTMLInputElement>(null);
  const initials =
    sessionUser?.displayName?.[0]?.toUpperCase() ??
    sessionUser?.email?.[0]?.toUpperCase() ??
    'K';

  useEffect(() => {
    if (!isDrawerOpen) return;
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') closeDrawer();
    }
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [isDrawerOpen, closeDrawer]);

  return (
    <>
      {/* Backdrop */}
      {isDrawerOpen && (
        <div
          className="fixed inset-0 z-[45] bg-black/50 backdrop-blur-sm"
          onClick={closeDrawer}
          aria-hidden="true"
        />
      )}

      {/* Drawer paneli */}
      <aside
        id="app-drawer"
        className={`fixed inset-y-0 left-0 z-50 w-80 overflow-y-auto bg-bg shadow-xl transition-transform duration-300 ease-in-out ${
          isDrawerOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
        aria-label="Navigasyon menüsü"
        role="dialog"
        aria-modal="true"
      >
        <div className="flex flex-col gap-3 p-4 pb-8">

          {/* Gradient başlık kartı */}
          <div
            className="flex items-center rounded-[18px] px-4 py-3 shadow-lg"
            style={{
              background:
                'linear-gradient(135deg, var(--yd-color-primary-deep) 0%, var(--yd-color-primary) 100%)',
            }}
          >
            <YeedoyLogo size={28} textColor="white" />
          </div>

          {/* Profil alanı */}
          {sessionUser ? (
            <Link
              href="/profil"
              onClick={closeDrawer}
              className="flex items-center gap-3 rounded-full border border-border bg-cardAlt px-3 py-2 hover:bg-card"
            >
              <div className="flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/15 text-sm font-[900] text-primary">
                {sessionUser.avatarUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={sessionUser.avatarUrl}
                    alt=""
                    className="h-8 w-8 rounded-full object-cover"
                  />
                ) : (
                  initials
                )}
              </div>
              <span className="flex-1 text-sm font-[800] text-textStrong">
                {sessionUser.displayName ?? sessionUser.email}
              </span>
              <ChevronRight />
            </Link>
          ) : (
            <Link
              href="/giris"
              onClick={closeDrawer}
              className="flex items-center justify-center rounded-full border border-primary/30 bg-primary/10 px-4 py-2.5 text-sm font-[900] text-primary hover:bg-primary/20"
            >
              Giriş Yap
            </Link>
          )}

          {/* Arama kutusu — W-15 */}
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const q = (new FormData(e.currentTarget).get('q') as string | null)?.trim();
              if (q) { router.push(`/arama?q=${encodeURIComponent(q)}`); closeDrawer(); }
            }}
            className="flex items-center gap-2 rounded-2xl border border-border bg-bg px-3 py-2"
          >
            <svg viewBox="0 0 24 24" className="h-4 w-4 shrink-0 fill-none stroke-muted stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              ref={searchRef}
              name="q"
              type="search"
              placeholder="İşletme veya yemek ara..."
              autoComplete="off"
              className="min-w-0 flex-1 bg-transparent text-sm text-textStrong placeholder:text-muted focus:outline-none"
            />
          </form>

          {/* Nav bölümleri */}
          {NAV_SECTIONS.map((section) => (
            <div
              key={section.title}
              className="rounded-2xl border border-border bg-cardAlt p-3 shadow-sm"
            >
              <p className="mb-2 text-sm font-[800] text-textStrong">{section.title}</p>
              {section.items.map((item) => (
                <DrawerTile
                  key={item.href}
                  href={item.href}
                  icon={item.icon}
                  label={item.label}
                  onClose={closeDrawer}
                />
              ))}
            </div>
          ))}

          {/* Hesap bölümü */}
          <div className="rounded-2xl border border-border bg-cardAlt p-3 shadow-sm">
            <p className="mb-2 text-sm font-[800] text-textStrong">Hesap</p>
            {ACCOUNT_ITEMS.map((item) => (
              <DrawerTile
                key={item.href}
                href={
                  item.requiresAuth && !sessionUser
                    ? `/giris?redirect=${item.href}`
                    : item.href
                }
                icon={item.icon}
                label={item.label}
                badge={item.showBadge && unreadCount > 0 ? unreadCount : undefined}
                onClose={closeDrawer}
              />
            ))}
          </div>

          {/* Alt satır: tema toggle + marka adı */}
          <div className="flex items-center justify-between px-1 pt-1">
            <ThemeToggle className="min-h-9 min-w-9 rounded-xl" />
            <span className="text-xs font-[800] text-muted">Yeedoy</span>
          </div>
        </div>
      </aside>
    </>
  );
}

// ── İç bileşenler ─────────────────────────────────────────────────────────────

function DrawerTile({
  href,
  icon,
  label,
  badge,
  onClose,
}: {
  href: string;
  icon: ReactNode;
  label: string;
  badge?: number;
  onClose: () => void;
}) {
  return (
    <Link
      href={href}
      onClick={onClose}
      className="flex items-center gap-3 rounded-xl px-2 py-2.5 text-sm font-[700] text-text hover:bg-card"
    >
      <span className="shrink-0 text-muted">{icon}</span>
      <span className="flex-1">{label}</span>
      {badge !== undefined && (
        <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary px-1.5 text-[10px] font-[900] text-white">
          {badge > 99 ? '99+' : badge}
        </span>
      )}
      <ChevronRight />
    </Link>
  );
}

function ChevronRight() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="shrink-0 text-muted"
      aria-hidden="true"
    >
      <path d="m9 18 6-6-6-6" />
    </svg>
  );
}
