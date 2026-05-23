'use client';

import { useState, useRef, useEffect, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

interface UserDropdownProps {
  displayName?: string | null;
  email?: string | null;
  avatarUrl?: string | null;
  /** 'topbar' = panel topbar stili, 'header' = public header stili */
  variant?: 'topbar' | 'header';
}

const MENU_ITEMS = [
  { href: '/profil',          label: 'Profilim',        icon: <UserIcon /> },
  { href: '/profil/settings', label: 'Ayarlar',         icon: <SettingsIcon /> },
  { href: '/gelen-kutusu',    label: 'Bildirimler',     icon: <BellIcon /> },
  { href: '/fiyat-uyarilari', label: 'Fiyat Uyarıları', icon: <TagIcon /> },
];

export function UserDropdown({ displayName, email, avatarUrl, variant = 'topbar' }: UserDropdownProps) {
  const [open, setOpen]         = useState(false);
  const [pending, startTransition] = useTransition();
  const ref = useRef<HTMLDivElement>(null);
  const router = useRouter();

  const initials = displayName?.[0]?.toUpperCase() ?? email?.[0]?.toUpperCase() ?? 'U';
  const label    = displayName ?? email ?? 'Hesabım';

  // Dışarı tıklayınca kapat
  useEffect(() => {
    function onPointerDown(e: PointerEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, []);

  function signOut() {
    setOpen(false);
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      await supabase.auth.signOut();
      router.push('/giris');
      router.refresh();
    });
  }

  const isTopbar = variant === 'topbar';

  return (
    <div ref={ref} className="relative">
      {/* Tetikleyici buton */}
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="true"
        aria-expanded={open}
        className={
          isTopbar
            ? 'flex h-9 w-9 items-center justify-center rounded-xl border border-border bg-primary/8 text-sm font-[900] text-primary transition-colors hover:bg-primary/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30'
            : 'flex h-10 w-10 items-center justify-center rounded-full border border-border bg-primary/10 text-sm font-[900] text-primary hover:bg-primary/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30'
        }
        title={label}
      >
        {avatarUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={avatarUrl}
            alt={displayName ?? ''}
            className={isTopbar ? 'h-7 w-7 rounded-lg object-cover' : 'h-8 w-8 rounded-full object-cover'}
          />
        ) : (
          initials
        )}
      </button>

      {/* Dropdown */}
      {open && (
        <div className="absolute right-0 top-full z-50 mt-2 w-56 overflow-hidden rounded-2xl border border-border bg-card shadow-lg">
          {/* Kullanıcı bilgisi */}
          <div className="border-b border-border px-4 py-3">
            <p className="truncate text-sm font-[800] text-textStrong">{displayName ?? 'Kullanıcı'}</p>
            {email && <p className="truncate text-xs text-muted">{email}</p>}
          </div>

          {/* Menü öğeleri */}
          <div className="py-1">
            {MENU_ITEMS.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className="flex items-center gap-3 px-4 py-2.5 text-sm font-[700] text-text transition-colors hover:bg-cardAlt hover:text-textStrong"
              >
                <span className="shrink-0 text-muted">{item.icon}</span>
                {item.label}
              </Link>
            ))}
          </div>

          {/* Ayraç + Çıkış */}
          <div className="border-t border-border py-1">
            <button
              type="button"
              onClick={signOut}
              disabled={pending}
              className="flex w-full items-center gap-3 px-4 py-2.5 text-sm font-[700] text-red-600 transition-colors hover:bg-red-50 disabled:opacity-50"
            >
              <span className="shrink-0"><LogoutIcon /></span>
              {pending ? 'Çıkılıyor…' : 'Çıkış yap'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ── İkonlar ───────────────────────────────────────────────────────────────────

function UserIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}

function SettingsIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function TagIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z" />
      <line x1="7" y1="7" x2="7.01" y2="7" />
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
