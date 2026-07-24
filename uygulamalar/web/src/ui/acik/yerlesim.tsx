import Link from 'next/link';
import type { ReactNode } from 'react';
import { Icon } from '@/src/ui/acik/simgeler';
import { AppDrawer, type DrawerSessionUser } from '@/src/ui/kabuk/uygulama-cekmecesi';
import { PublicHeader, getSessionUser, getUnreadCount } from '@/src/ui/acik/genel-baslik';
import { PublicFooter } from '@/src/ui/acik/genel-altbilgi';

// Re-export for backward compatibility — all existing imports from this file still work
export { PublicHeader, getSessionUser, getUnreadCount } from '@/src/ui/acik/genel-baslik';
export { PublicFooter } from '@/src/ui/acik/genel-altbilgi';

// ── Mobil alt navigasyon ──────────────────────────────────────────────────────

export function MobileBottomNav() {
  return (
    <nav
      className="fixed inset-x-3 bottom-3 z-40 grid grid-cols-4 rounded-[24px] border border-border bg-card/95 p-1 shadow-yd3 backdrop-blur-sm md:hidden"
      aria-label="Mobil navigasyon"
    >
      <Link href="/" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-black text-textStrong hover:bg-cardAlt">
        <Icon name="search" size={16} />
        <span className="mt-0.5">Ana Sayfa</span>
      </Link>
      <Link href="/kesif" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-black text-textStrong hover:bg-cardAlt">
        <Icon name="pin" size={16} />
        <span className="mt-0.5">Keşfet</span>
      </Link>
      <Link href="/arama" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-black text-textStrong hover:bg-cardAlt">
        <Icon name="search" size={16} />
        <span className="mt-0.5">Arama</span>
      </Link>
      <Link href="/profil" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-black text-textStrong hover:bg-cardAlt">
        <Icon name="user" size={16} />
        <span className="mt-0.5">Profil</span>
      </Link>
    </nav>
  );
}

// ── Shell wrapper ─────────────────────────────────────────────────────────────

export async function PublicShell({
  children,
  footer = true,
  variant = 'public',
}: {
  children: ReactNode;
  footer?: boolean;
  variant?: 'public' | 'owner';
}) {
  const sessionUser = await getSessionUser();
  const unreadCount = sessionUser ? await getUnreadCount(sessionUser.id) : 0;
  const drawerUser: DrawerSessionUser | null = sessionUser;

  return (
    <div className="min-h-screen bg-bg pb-20 text-text md:pb-0">
      <PublicHeader variant={variant} />
      <AppDrawer sessionUser={drawerUser} unreadCount={unreadCount} />
      {children}
      {footer ? <PublicFooter /> : null}
      <MobileBottomNav />
    </div>
  );
}
