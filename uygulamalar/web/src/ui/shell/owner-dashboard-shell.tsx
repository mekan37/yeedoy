'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban-istemci';

export interface OwnerShellBusiness {
  id: string;
  name: string;
  category: string | null;
  logoUrl: string | null;
  isVerified: boolean;
  slug: string | null;
}

export interface OwnerShellUser {
  displayName: string;
  avatarUrl: string | null;
}

interface NavItem {
  href: string;
  label: string;
  icon: React.ReactNode;
  badge?: number | string;
}

const NAV_ITEMS: NavItem[] = [
  { href: '/owner/dashboard', label: 'Genel Bakış', icon: <HomeIcon /> },
  { href: '/owner/businesses', label: 'İşletme Bilgileri', icon: <BuildingIcon /> },
  { href: '/owner/menus', label: 'Menü Yönetimi', icon: <MenuIcon /> },
  { href: '/owner/reviews', label: 'Yorumlar', icon: <StarIcon />, badge: 0 },
  { href: '/owner/analytics', label: 'İstatistikler', icon: <ChartIcon /> },
  { href: '/owner/marketing/campaigns', label: 'Kampanyalar', icon: <MegaphoneIcon /> },
  { href: '/owner/qr', label: 'QR Menü & QR Kod', icon: <QrIcon /> },
  { href: '/owner/activity', label: 'Bildirimler', icon: <BellIcon /> },
  { href: '/owner/settings', label: 'Ayarlar', icon: <SettingsIcon /> },
];

interface Props {
  children: React.ReactNode;
  business: OwnerShellBusiness | null;
  user: OwnerShellUser | null;
  reviewBadgeCount?: number;
  bannerSlot?: React.ReactNode;
}

export function OwnerDashboardShell({ children, business, user, reviewBadgeCount, bannerSlot }: Props) {
  const pathname = usePathname();
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  async function handleLogout() {
    const supabase = createSupabaseBrowserClient();
    await supabase.auth.signOut();
    router.push('/login');
  }

  const navItems: NavItem[] = NAV_ITEMS.map((item) =>
    item.href === '/owner/reviews' && reviewBadgeCount
      ? { ...item, badge: reviewBadgeCount }
      : item
  );

  const isActive = (href: string) => {
    if (href === '/owner/dashboard') return pathname === href;
    return pathname.startsWith(href);
  };

  return (
    <div className="flex h-screen overflow-hidden bg-[#f8f9fb]">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-30 bg-black/40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* ── Sidebar ───────────────────────────────────────────────────── */}
      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-[240px] flex-col bg-white shadow-[1px_0_0_#f0f0f0] transition-transform duration-200 lg:relative lg:translate-x-0 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}
      >
        {/* Logo */}
        <div className="flex h-[60px] items-center px-5 border-b border-[#f0f0f0]">
          <span className="text-[22px] font-[900]" style={{ color: '#dc2626', letterSpacing: '-0.5px' }}>
            Yeedoy
          </span>
        </div>

        {/* Business card */}
        {business && (
          <div className="px-4 py-4 border-b border-[#f0f0f0]">
            <div className="flex items-center gap-3">
              <BusinessAvatar name={business.name} logoUrl={business.logoUrl} size={44} />
              <div className="min-w-0">
                <p className="truncate text-[13px] font-[800] text-[#1a1a2e]">{business.name}</p>
                {business.category && (
                  <p className="text-[11px] text-[#94a3b8] font-[600]">{business.category}</p>
                )}
                {business.isVerified && (
                  <span className="mt-0.5 inline-flex items-center gap-1 rounded-full bg-[#dcfce7] px-2 py-0.5 text-[10px] font-[800] text-[#16a34a]">
                    <span className="h-1.5 w-1.5 rounded-full bg-[#16a34a]" />
                    Onaylı İşletme
                  </span>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto py-2 px-2">
          {navItems.map((item) => {
            const active = isActive(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 mb-0.5 text-[13px] font-[700] transition-all ${
                  active
                    ? 'bg-[#fef2f2] text-[#dc2626]'
                    : 'text-[#475569] hover:bg-[#f8fafc] hover:text-[#1a1a2e]'
                }`}
                style={active ? { borderLeft: '3px solid #dc2626', paddingLeft: 10 } : { borderLeft: '3px solid transparent', paddingLeft: 10 }}
              >
                <span className={active ? 'text-[#dc2626]' : 'text-[#94a3b8]'}>{item.icon}</span>
                <span className="flex-1 truncate">{item.label}</span>
                {item.badge != null && Number(item.badge) > 0 && (
                  <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-[#dc2626] px-1.5 text-[10px] font-[900] text-white">
                    {typeof item.badge === 'number' && item.badge > 99 ? '99+' : String(item.badge)}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Support */}
        <div className="border-t border-[#f0f0f0] p-4">
          <div className="mb-2 flex items-center gap-2">
            <span className="flex h-7 w-7 items-center justify-center rounded-full bg-[#f1f5f9] text-[#64748b]">
              <HelpIcon />
            </span>
            <div>
              <p className="text-[12px] font-[800] text-[#1a1a2e]">Yeedoy Destek</p>
              <p className="text-[11px] text-[#94a3b8]">Yardım al ve destek ekibimize ulaş.</p>
            </div>
          </div>
          <button className="w-full rounded-xl border border-[#e2e8f0] bg-white py-2 text-[12px] font-[800] text-[#475569] hover:bg-[#f8fafc] transition-colors">
            Destek Talebi Oluştur
          </button>
        </div>
      </aside>

      {/* ── Main area ─────────────────────────────────────────────────── */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Topbar */}
        <header className="flex h-[60px] items-center justify-between gap-4 border-b border-[#f0f0f0] bg-white px-5">
          {/* Left: hamburger (mobile) + business selector */}
          <div className="flex items-center gap-3">
            <button
              className="flex h-8 w-8 items-center justify-center rounded-lg text-[#94a3b8] hover:bg-[#f1f5f9] lg:hidden"
              onClick={() => setSidebarOpen(true)}
            >
              <HamburgerIcon />
            </button>
            {business && (
              <button className="flex items-center gap-2 rounded-xl border border-[#f0f0f0] bg-[#fafafa] px-3 py-1.5 text-[13px] font-[800] text-[#1a1a2e] hover:bg-[#f1f5f9] transition-colors">
                <BusinessAvatar name={business.name} logoUrl={business.logoUrl} size={24} />
                <span className="max-w-[160px] truncate">{business.name}</span>
                {business.isVerified && (
                  <span className="rounded-full bg-[#dcfce7] px-2 py-0.5 text-[10px] font-[800] text-[#16a34a]">
                    Onaylı İşletme
                  </span>
                )}
                <ChevronDownIcon />
              </button>
            )}
          </div>

          {/* Right */}
          <div className="flex items-center gap-2">
            {business?.slug && (
              <Link
                href={`/isletme/${business.slug}`}
                target="_blank"
                className="hidden items-center gap-1.5 rounded-xl border border-[#e2e8f0] px-3 py-1.5 text-[12px] font-[800] text-[#475569] hover:bg-[#f8fafc] transition-colors sm:flex"
              >
                İşletme Sayfasını Gör
                <ExternalLinkIcon />
              </Link>
            )}

            {/* Notifications */}
            <button className="relative flex h-8 w-8 items-center justify-center rounded-full text-[#64748b] hover:bg-[#f1f5f9] transition-colors">
              <BellIcon />
            </button>

            {/* User + Logout */}
            {user && (
              <div className="flex items-center gap-2 pl-2 border-l border-[#f0f0f0]">
                <UserAvatar displayName={user.displayName} avatarUrl={user.avatarUrl} />
                <div className="hidden sm:block text-right">
                  <p className="text-[13px] font-[800] text-[#1a1a2e] leading-tight">{user.displayName}</p>
                  <p className="text-[11px] text-[#94a3b8] font-[600]">İşletme Sahibi</p>
                </div>
                <button
                  onClick={handleLogout}
                  title="Çıkış Yap"
                  className="ml-1 flex h-8 w-8 items-center justify-center rounded-lg text-[#94a3b8] hover:bg-[#fff1f2] hover:text-[#dc2626] transition-colors"
                >
                  <LogoutIcon />
                </button>
              </div>
            )}
          </div>
        </header>

        {/* Banner slot */}
        {bannerSlot}

        {/* Content */}
        <main className="flex-1 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
}

function BusinessAvatar({ name, logoUrl, size }: { name: string; logoUrl: string | null; size: number }) {
  if (logoUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={logoUrl}
        alt={name}
        width={size}
        height={size}
        className="rounded-full object-cover border border-[#f0f0f0]"
        style={{ width: size, height: size, flexShrink: 0 }}
      />
    );
  }
  return (
    <div
      className="flex items-center justify-center rounded-full bg-[#fef2f2] text-[#dc2626] font-[900]"
      style={{ width: size, height: size, fontSize: size * 0.4, flexShrink: 0 }}
    >
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

function UserAvatar({ displayName, avatarUrl }: { displayName: string; avatarUrl: string | null }) {
  if (avatarUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img src={avatarUrl} alt={displayName} className="h-8 w-8 rounded-full object-cover border border-[#f0f0f0]" />
    );
  }
  return (
    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#7f1d1d] text-[13px] font-[900] text-white">
      {displayName.charAt(0).toUpperCase()}
    </div>
  );
}

// ── Icons ──────────────────────────────────────────────────────────────────────

function HomeIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      <polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
      <path d="M9 22V12h6v10" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
  );
}

function StarIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function ChartIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
    </svg>
  );
}

function MegaphoneIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 11l19-9-9 19-2-8-8-2z" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" />
      <rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" />
      <line x1="14" y1="14" x2="14" y2="14.01" />
      <line x1="21" y1="14" x2="21" y2="14.01" />
      <line x1="14" y1="21" x2="14" y2="21.01" />
      <line x1="21" y1="21" x2="21" y2="21.01" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function SettingsIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  );
}

function HelpIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}

function HamburgerIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="3" y1="6" x2="21" y2="6" />
      <line x1="3" y1="12" x2="21" y2="12" />
      <line x1="3" y1="18" x2="21" y2="18" />
    </svg>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  );
}

function ExternalLinkIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}

function LogoutIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  );
}
