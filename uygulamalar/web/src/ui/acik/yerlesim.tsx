import Link from 'next/link';
import type { ReactNode } from 'react';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { ThemeToggle } from '@/src/ui/bilesenler/tema-degistirici';
import { Container, ButtonLink } from '@/src/ui/acik/ortak';
import { Icon } from '@/src/ui/acik/simgeler';
import { NavLinks } from '@/src/ui/acik/nav-baglantilari';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { UserDropdown } from '@/src/ui/bilesenler/kullanici-dropdown';
import { HamburgerDugmesi } from '@/src/ui/kabuk/hamburger-dugmesi';
import { AppDrawer, type DrawerSessionUser } from '@/src/ui/kabuk/uygulama-cekmecesi';
import { HeaderSarmalayici } from '@/src/ui/bilesenler/header-sarmalayici';

// ── Navigasyon öğeleri ────────────────────────────────────────────────────────

const NAV_ITEMS = [
  { href: '/kesif',     label: 'Keşfet' },
  { href: '/arama',     label: 'Arama' },
  { href: '/en-iyiler', label: 'En İyiler' },
];

// Owner sayfaları için ayrı nav (panel subdomain, /isletme, /sahiplen/*)
const OWNER_NAV_ITEMS = [
  { href: '/isletme#nasil-calisir', label: 'Nasıl Çalışır?' },
  { href: '/isletme#ozellikler',    label: 'Özellikler' },
  { href: '/isletme#iletisim',      label: 'İletişim' },
];

// ── Header ────────────────────────────────────────────────────────────────────

async function getSessionUser() {
  try {
    const supabase = await createSupabaseServerClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { data: profile } = await (supabase as any)
      .from('user_profiles')
      .select('display_name, avatar_url')
      .eq('user_id', user.id)
      .maybeSingle();

    return {
      id: user.id,
      email: user.email ?? '',
      displayName: (profile?.display_name as string | null) ?? null,
      avatarUrl: (profile?.avatar_url as string | null) ?? null,
    };
  } catch {
    return null;
  }
}

async function getUnreadCount(userId: string): Promise<number> {
  try {
    const supabase = await createSupabaseServerClient();
    const { count, error } = await (supabase as any)
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false) as { count: number | null; error: { code?: string } | null };
    if (error?.code === '42P01') {
      const { count: c2 } = await (supabase as any)
        .from('user_notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_read', false) as { count: number | null };
      return c2 ?? 0;
    }
    return count ?? 0;
  } catch {
    return 0;
  }
}

export async function PublicHeader({ variant = 'public' }: { variant?: 'public' | 'owner' }) {
  const user = await getSessionUser();
  const navItems = variant === 'owner' ? OWNER_NAV_ITEMS : NAV_ITEMS;
  const isOwner  = variant === 'owner';

  return (
    <HeaderSarmalayici>
      <Container className="flex min-h-16 items-center justify-between gap-3">
        {/* Logo */}
        <Link
          href={isOwner ? '/isletme' : '/'}
          aria-label="Yeedoy ana sayfa"
          className="inline-flex min-h-11 shrink-0 items-center gap-2"
        >
          <YeedoyLogo size={34} />
          {isOwner && (
            <span className="hidden rounded-full border border-primary/25 bg-primary/10 px-2 py-0.5 text-[10px] font-[900] uppercase tracking-wider text-primary sm:inline">
              for Business
            </span>
          )}
        </Link>

        {/* Desktop nav */}
        <nav className="hidden items-center gap-0.5 md:flex">
          <NavLinks items={navItems} />
        </nav>

        {/* Sağ araçlar */}
        <div className="flex items-center gap-2">
          <HamburgerDugmesi />
          <ThemeToggle />

          {isOwner ? (
            /* Owner sayfası: belirgin "Panele Giriş" + dropdown */
            user ? (
              <>
                <Link
                  href="/sahip/gosterge-panosu"
                  className="hidden rounded-xl bg-primary px-4 py-2 text-sm font-[900] text-white sm:inline-flex"
                >
                  Panele Git →
                </Link>
                <UserDropdown
                  displayName={user.displayName}
                  email={user.email}
                  avatarUrl={user.avatarUrl}
                  variant="header"
                />
              </>
            ) : (
              <>
                <ButtonLink href="/giris?redirect=/sahip/gosterge-panosu" variant="secondary" className="hidden min-h-11 px-4 sm:inline-flex">
                  Giriş
                </ButtonLink>
                <ButtonLink href="/sahiplen/ara" className="min-h-11 px-4">
                  İşletmeni Ekle
                </ButtonLink>
              </>
            )
          ) : (
            /* Public header */
            user ? (
              <>
                <Link
                  href="/gelen-kutusu"
                  aria-label="Bildirimler"
                  className="flex min-h-11 w-11 items-center justify-center rounded-2xl text-text hover:bg-cardAlt"
                >
                  <Icon name="bell" size={18} />
                </Link>
                <UserDropdown
                  displayName={user.displayName}
                  email={user.email}
                  avatarUrl={user.avatarUrl}
                  variant="header"
                />
              </>
            ) : (
              <ButtonLink href="/giris" variant="secondary" className="min-h-11 px-4">
                Giriş
              </ButtonLink>
            )
          )}
        </div>
      </Container>
    </HeaderSarmalayici>
  );
}

// ── Footer ────────────────────────────────────────────────────────────────────

export function PublicFooter() {
  return (
    <footer className="border-t border-border bg-card">
      <Container className="grid gap-8 py-10 sm:grid-cols-2 lg:grid-cols-4">
        {/* Marka */}
        <div className="sm:col-span-2 lg:col-span-1">
          <YeedoyLogo size={36} />
          <p className="mt-4 max-w-xs text-sm leading-6 text-muted">
            Yakınındaki restoran ve kafeleri keşfet. Gerçek fiyatlar, topluluk yorumları, akıllı keşif.
          </p>
        </div>

        {/* Keşif */}
        <div>
          <p className="font-[900] text-textStrong">Keşif</p>
          <div className="mt-3 grid gap-2 text-sm text-muted">
            <Link href="/kesif" className="hover:text-primary">İşletmeler</Link>
            <Link href="/arama" className="hover:text-primary">Arama</Link>
            <Link href="/en-iyiler" className="hover:text-primary">En İyiler</Link>
          </div>
        </div>

        {/* Özellikler */}
        <div>
          <p className="font-[900] text-textStrong">Özellikler</p>
          <div className="mt-3 grid gap-2 text-sm text-muted">
            <Link href="/fiyat-uyarilari" className="hover:text-primary">Fiyat Uyarıları</Link>
          </div>
        </div>

        {/* Hesap & İşletmeler */}
        <div>
          <p className="font-[900] text-textStrong">Hesap</p>
          <div className="mt-3 grid gap-2 text-sm text-muted">
            <Link href="/giris" className="hover:text-primary">Giriş Yap</Link>
            <Link href="/baslangic" className="hover:text-primary">Kayıt Ol</Link>
            <Link href="/profil" className="hover:text-primary">Profilim</Link>
            <Link href="/katki" className="hover:text-primary">Katkılarım</Link>
          </div>
          <p className="mt-5 font-[900] text-textStrong">İşletmeler</p>
          <div className="mt-3 grid gap-2 text-sm text-muted">
            <Link href="/isletme" className="hover:text-primary">Yeedoy for Business</Link>
            <Link href="/yasal" className="hover:text-primary">Yasal</Link>
            <Link href="/yasal/yorum-politikasi" className="hover:text-primary">Yorum Politikası</Link>
            <Link href="/yasal/terms" className="hover:text-primary">Kullanım Şartları</Link>
            <Link href="/gizlilik" className="hover:text-primary">Gizlilik Politikası</Link>
            <Link href="/yardim" className="hover:text-primary">Yardım</Link>
          </div>
        </div>
      </Container>

      {/* Alt bar */}
      <div className="border-t border-border">
        <Container className="flex flex-wrap items-center justify-between gap-3 py-4 text-xs text-muted">
          <span>© {new Date().getFullYear()} Yeedoy. Tüm hakları saklıdır.</span>
          <span>Türkiye&apos;nin menü ve fiyat keşif platformu</span>
        </Container>
      </div>
    </footer>
  );
}

// ── Mobil alt navigasyon ──────────────────────────────────────────────────────
// Server component — auth state içermez (performans için)
// Auth gerektiren linkler /giris'e yönlendirir, middleware redirect eder

export function MobileBottomNav() {
  return (
    <nav
      className="fixed inset-x-3 bottom-3 z-40 grid grid-cols-4 rounded-[24px] border border-border bg-card/95 p-1 shadow-yd3 backdrop-blur md:hidden"
      aria-label="Mobil navigasyon"
    >
      <Link href="/" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-[900] text-textStrong hover:bg-cardAlt">
        <Icon name="search" size={16} />
        <span className="mt-0.5">Ana Sayfa</span>
      </Link>
      <Link href="/kesif" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-[900] text-textStrong hover:bg-cardAlt">
        <Icon name="pin" size={16} />
        <span className="mt-0.5">Keşfet</span>
      </Link>
      <Link href="/arama" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-[900] text-textStrong hover:bg-cardAlt">
        <Icon name="search" size={16} />
        <span className="mt-0.5">Arama</span>
      </Link>
      <Link href="/profil" className="flex min-h-12 flex-col items-center justify-center rounded-[20px] text-[11px] font-[900] text-textStrong hover:bg-cardAlt">
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
