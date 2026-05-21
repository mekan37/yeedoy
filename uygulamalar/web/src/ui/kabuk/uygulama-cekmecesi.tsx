'use client';

import Link from 'next/link';
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

const NAV_SECTIONS: { title: string; items: { href: string; label: string; icon: string }[] }[] = [
  {
    title: 'Keşfet',
    items: [
      { href: '/kesif',       label: 'Keşfet',    icon: '🔍' },
      { href: '/en-iyiler',   label: 'En İyiler', icon: '🏆' },
      { href: '/liderler',    label: 'Liderler',  icon: '📍' },
      { href: '/butce',       label: 'Bütçe',     icon: '💰' },
    ],
  },
  {
    title: 'Özellikler',
    items: [
      { href: '/akilli-akis',     label: 'Akıllı Akış',            icon: '✨' },
      { href: '/tat-ikizi',       label: 'Taste Twin',             icon: '🤝' },
      { href: '/fiyat-uyarilari', label: 'Fiyat Uyarıları',       icon: '🔔' },
      { href: '/ortak-listeler',  label: 'Kolaborasyon Listeleri', icon: '📋' },
    ],
  },
];

const ACCOUNT_ITEMS: { href: string; label: string; icon: string; showBadge: boolean; requiresAuth: boolean }[] = [
  { href: '/favoriler',       label: 'Favorilerim',  icon: '❤️', showBadge: false, requiresAuth: true  },
  { href: '/profil',          label: 'Profil',       icon: '👤', showBadge: false, requiresAuth: true  },
  { href: '/gelen-kutusu',    label: 'Gelen Kutusu', icon: '📥', showBadge: true,  requiresAuth: true  },
  { href: '/oneriler',        label: 'Önerilerim',   icon: '💡', showBadge: false, requiresAuth: true  },
  { href: '/yasal',           label: 'Yasal',        icon: '📄', showBadge: false, requiresAuth: false },
];

export function AppDrawer({ sessionUser, unreadCount }: AppDrawerProps) {
  const { isDrawerOpen, closeDrawer } = useWebKabukStore();
  const initials =
    sessionUser?.displayName?.[0]?.toUpperCase() ??
    sessionUser?.email?.[0]?.toUpperCase() ??
    'K';

  return (
    <>
      {/* Backdrop */}
      {isDrawerOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm"
          onClick={closeDrawer}
          aria-hidden="true"
        />
      )}

      {/* Drawer paneli */}
      <aside
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
  icon: string;
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
      <span className="shrink-0 text-base leading-none">{icon}</span>
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
