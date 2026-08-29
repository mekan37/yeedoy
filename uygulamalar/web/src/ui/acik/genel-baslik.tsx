import Link from 'next/link';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { NavAramaButonu } from '@/src/ui/bilesenler/nav-arama-butonu';
import { Container, ButtonLink } from '@/src/ui/acik/ortak';
import { Icon } from '@/src/ui/acik/simgeler';
import { NavLinks } from '@/src/ui/acik/nav-baglantilari';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { UserDropdown } from '@/src/ui/bilesenler/kullanici-dropdown';
import { HamburgerDugmesi } from '@/src/ui/kabuk/hamburger-dugmesi';
import { HeaderSarmalayici } from '@/src/ui/bilesenler/header-sarmalayici';
import { KonumSecici } from '@/src/ui/acik/konum-secici';

const NAV_ITEMS = [
  { href: '/kesif',        label: 'Keşfet' },
  { href: '/kesif/harita', label: 'Harita' },
  { href: '/kampanyalar',   label: 'Kampanyalar' },
  { href: '/oneri',        label: 'Akıllı Öneri' },
  { href: '/isletme-oner', label: 'İşletme Öner' },
];

const OWNER_NAV_ITEMS = [
  { href: '/isletme#nasil-calisir', label: 'Nasıl Çalışır?' },
  { href: '/isletme#ozellikler',    label: 'Özellikler' },
  { href: '/isletme#iletisim',      label: 'İletişim' },
];

export async function getSessionUser() {
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

export async function getUnreadCount(userId: string): Promise<number> {
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
  const isOwner = variant === 'owner';

  return (
    <HeaderSarmalayici>
      <Container className="flex min-h-16 items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <Link
            href={isOwner ? '/isletme' : '/'}
            aria-label="Yeedoy ana sayfa"
            className="inline-flex min-h-11 shrink-0 items-center gap-2"
          >
            <YeedoyLogo size={34} />
            {isOwner && (
              <span className="hidden rounded-full border border-primary/25 bg-primary/10 px-2 py-0.5 text-[10px] font-black uppercase tracking-wider text-primary sm:inline">
                for Business
              </span>
            )}
          </Link>
          {!isOwner && <KonumSecici />}
        </div>

        <nav className="hidden items-center gap-0.5 md:flex">
          <NavLinks items={navItems} />
        </nav>

        <div className="flex items-center gap-2">
          <HamburgerDugmesi />
          <NavAramaButonu />

          {isOwner ? (
            user ? (
              <>
                <Link
                  href="/sahip/gosterge-panosu"
                  className="hidden rounded-xl bg-primary px-4 py-2 text-sm font-black text-white sm:inline-flex"
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
              <>
                <ButtonLink href="/giris" variant="ghost" className="hidden min-h-11 px-4 sm:inline-flex">
                  Giriş Yap
                </ButtonLink>
                <ButtonLink href="/giris?tab=kayit" variant="secondary" className="min-h-11 px-4">
                  Kayıt Ol
                </ButtonLink>
              </>
            )
          )}
        </div>
      </Container>
    </HeaderSarmalayici>
  );
}
