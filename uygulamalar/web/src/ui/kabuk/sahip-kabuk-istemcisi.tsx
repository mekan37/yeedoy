'use client';

import { useEffect, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { AppProviders } from '@/src/lib/uygulama-saglayicilari';
import { PanelShell } from './panel-kabugu';
import type { NavSection } from './panel-yan-menusu';
import { UserDropdown } from '@/src/ui/bilesenler/kullanici-dropdown';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { IsletmeSwitcherDropdown, type IsletmeSwitcherOgesi } from './isletme-switcher-dropdown';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { getOnboardingStatus } from '@/src/lib/veri/owner/sahip-baslangic-durumu';
import { usePanelStore } from '@/src/lib/panel-deposu';

export interface SahipKabukIsletmeKimligi {
  id: string;
  name: string;
  slug: string | null;
  category: string | null;
  logoUrl: string | null;
  isVerified: boolean;
  isActive: boolean;
}

// Referans tasarımdaki gibi tek, düz liste — bölüm başlığı yok.
const ownerNavSections: NavSection[] = [
  {
    items: [
      { href: '/sahip/gosterge-panosu', label: 'Genel Bakış', icon: <HomeIcon />, exact: true },
      { href: '/sahip/baslangic', label: 'Başlangıç Rehberi', icon: <RocketIcon /> },
      { href: '/sahip/isletmeler', label: 'İşletmelerim', icon: <BuildingIcon /> },
      { href: '/sahip/premium', label: 'Premium', icon: <CrownIcon /> },
      {
        href: '/sahip/menu-yonetimi',
        label: 'Menü Yönetimi',
        icon: <MenuIcon />,
        children: [
          { href: '/sahip/menu-yonetimi', label: 'Menü', icon: <MenuIcon />, exact: true },
          { href: '/sahip/menu-yonetimi/kategoriler', label: 'Kategoriler', icon: <MenuIcon /> },
          { href: '/sahip/karekod', label: 'QR Menü & QR Kod', icon: <QrIcon /> },
        ],
      },
      { href: '/sahip/fotograflar', label: 'Fotoğraflar', icon: <ImageIcon /> },
      { href: '/sahip/rezervasyonlar', label: 'Rezervasyonlar', icon: <CalendarIcon /> },
      { href: '/sahip/yorumlar', label: 'Yorumlar', icon: <StarIcon /> },
      { href: '/sahip/musteriler', label: 'Müşteriler', icon: <ContactIcon /> },
      { href: '/sahip/bildirimler', label: 'Bildirimler', icon: <BellIcon /> },
      {
        href: '/sahip/pazarlama/kampanyalar',
        label: 'Pazarlama',
        icon: <MegaphoneIcon />,
        children: [
          { href: '/sahip/pazarlama/kampanyalar', label: 'Kampanyalar', icon: <MegaphoneIcon />, exact: true },
          { href: '/sahip/pazarlama/sadakat', label: 'Sadakat', icon: <GiftIcon /> },
          { href: '/sahip/etkinlik', label: 'Etkinlikler', icon: <ActivityIcon /> },
        ],
      },
      {
        href: '/sahip/analitik',
        label: 'Raporlar',
        icon: <ChartIcon />,
        children: [
          { href: '/sahip/analitik', label: 'İstatistikler', icon: <ChartIcon />, exact: true },
          { href: '/sahip/fiyat-raporu', label: 'Fiyat Raporu', icon: <PriceIcon /> },
        ],
      },
      {
        href: '/sahip/ekip',
        label: 'Yönetim',
        icon: <ChoklusubeIcon />,
        children: [
          { href: '/sahip/ekip', label: 'Ekip', icon: <UsersIcon />, exact: true },
          { href: '/sahip/coklu-sube', label: 'Çoklu Şube Yönetimi', icon: <ChoklusubeIcon /> },
          { href: '/sahip/denetim-kaydi', label: 'Aktivite Geçmişi', icon: <ShieldIcon /> },
          { href: '/sahip/cop-kutusu', label: 'Çöp Kutusu', icon: <TrashIcon /> },
        ],
      },
      { href: '/sahip/destek', label: 'Destek', icon: <HeadsetIcon /> },
      { href: '/sahip/sss', label: 'S.S.S.', icon: <HelpIcon /> },
      {
        href: '/sahip/ayarlar',
        label: 'Hesabım',
        icon: <SettingsIcon />,
        children: [
          { href: '/sahip/ayarlar', label: 'Ayarlar', icon: <SettingsIcon />, exact: true },
          { href: '/sahip/profilim', label: 'Profilim', icon: <UserIcon /> },
        ],
      },
    ],
  },
];

function useCurrentUser() {
  const [user, setUser] = useState<{ email: string | null; displayName: string | null; avatarUrl: string | null } | null>(null);
  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    void supabase.auth.getSession().then(async ({ data }) => {
      if (!data.session?.user) return;
      const { data: profile } = await (supabase as any)
        .from('user_profiles')
        .select('display_name, avatar_url')
        .eq('user_id', data.session.user.id)
        .maybeSingle();
      setUser({
        email: data.session.user.email ?? null,
        displayName: profile?.display_name ?? null,
        avatarUrl: profile?.avatar_url ?? null,
      });
    });
  }, []);
  return user;
}

function useOnboardingComplete() {
  const [complete, setComplete] = useState<boolean | null>(null);
  useEffect(() => {
    void getOnboardingStatus().then((status) => setComplete(status.complete));
  }, []);
  return complete;
}

interface SahipKabukIstemcisiProps {
  children: ReactNode;
  bannerSlot?: ReactNode;
  isletme?: SahipKabukIsletmeKimligi | null;
  isletmeSayisi?: number;
  isletmeListesi?: IsletmeSwitcherOgesi[];
  yorumBadgeSayisi?: number;
}

function navSectionsWithYorumBadge(sections: NavSection[], badgeCount: number): NavSection[] {
  if (badgeCount <= 0) return sections;
  const badge = badgeCount > 99 ? '99+' : String(badgeCount);
  return sections.map((section) => ({
    ...section,
    items: section.items.map((item) =>
      item.href === '/sahip/yorumlar' ? { ...item, badge, badgeTone: 'primary' as const } : item,
    ),
  }));
}

export function SahipKabukIstemcisi({
  children,
  bannerSlot,
  isletme = null,
  isletmeSayisi = 0,
  isletmeListesi = [],
  yorumBadgeSayisi = 0,
}: SahipKabukIstemcisiProps) {
  const user = useCurrentUser();
  const onboardingComplete = useOnboardingComplete();
  const pathname = usePathname();
  const isLandingPage = pathname === '/sahip';

  if (isLandingPage) {
    return <AppProviders>{children}</AppProviders>;
  }

  // Kullanıcı zaten Yorumlar sayfasındayken rozeti gösterme
  const effectiveYorumBadge = pathname?.startsWith('/sahip/yorumlar') ? 0 : yorumBadgeSayisi;

  const baseSections = onboardingComplete === true
    ? ownerNavSections.map((section) => ({
        ...section,
        items: section.items.filter((item) => item.href !== '/sahip/baslangic'),
      }))
    : ownerNavSections;

  const isletmeSayfaHref = isletme?.slug ? `/isletme/${isletme.slug}` : null;

  return (
    <AppProviders>
      <PanelShell
        navSections={navSectionsWithYorumBadge(baseSections, effectiveYorumBadge)}
        logoSlot={<IsletmeKimlikKarti isletme={isletme} />}
        topbarLogoSlot={<OwnerLogo />}
        showPanelBadge={false}
        topbarCenter={
          isletme ? (
            <IsletmeSwitcherDropdown
              aktifIsletme={{ id: isletme.id, name: isletme.name, isVerified: isletme.isVerified }}
              isletmeler={isletmeListesi}
            />
          ) : null
        }
        sidebarFooter={<DestekKarti />}
        topbarActions={
          <>
            {isletmeSayfaHref && (
              <a
                href={isletmeSayfaHref}
                target="_blank"
                rel="noreferrer"
                className="hidden items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-xs font-extrabold text-textStrong transition-colors hover:border-primary hover:text-primary sm:flex"
              >
                <ExternalLinkIcon />
                İşletme Sayfasını Gör
              </a>
            )}
            <Link
              href="/sahip/bildirimler"
              aria-label="Bildirimler"
              className="relative flex h-9 w-9 items-center justify-center rounded-lg text-muted transition-colors hover:bg-textStrong/[0.07] hover:text-textStrong"
            >
              <BellIcon />
              {effectiveYorumBadge > 0 && (
                <span className="absolute right-1 top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-(--yd-color-primary) px-1 text-[9px] font-black text-white">
                  {effectiveYorumBadge > 9 ? '9+' : effectiveYorumBadge}
                </span>
              )}
            </Link>
            {user ? (
              <UserDropdown
                displayName={user.displayName}
                email={user.email}
                avatarUrl={user.avatarUrl}
                variant="topbar"
                context="owner"
                roleLabel="İşletme Sahibi"
              />
            ) : undefined}
          </>
        }
        bannerSlot={bannerSlot}
      >
        {children}
      </PanelShell>
    </AppProviders>
  );
}

/** Sidebar üstü — işletme kimlik kartı (fotoğraf, ad, kategori, onay rozeti). Daraltılmışken sadece görsel kalır. İşletme yoksa Yeedoy logosuna düşer. */
function IsletmeKimlikKarti({ isletme }: { isletme: SahipKabukIsletmeKimligi | null }) {
  const { sidebarCollapsed } = usePanelStore();
  if (!isletme) return <OwnerLogo />;

  const foto = (
    <span className="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-primary/10 text-sm font-black text-primary">
      {isletme.logoUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={isletme.logoUrl} alt={isletme.name} className="h-full w-full object-cover" />
      ) : (
        isletme.name.charAt(0).toUpperCase()
      )}
    </span>
  );

  if (sidebarCollapsed) return foto;

  return (
    <div className="flex w-full items-center gap-3">
      {foto}
      <div className="min-w-0 flex-1">
        <p className="truncate text-[13px] font-black text-textStrong">{isletme.name}</p>
        <p className="truncate text-[11px] font-bold text-muted">{isletme.category ?? 'İşletme'}</p>
        {isletme.isVerified && (
          <span className="mt-1 inline-flex items-center rounded-full bg-green-50 px-2 py-0.5 text-[9px] font-extrabold uppercase tracking-wide text-green-700">
            Onaylı İşletme
          </span>
        )}
      </div>
    </div>
  );
}

function OwnerLogo() {
  return (
    <div className="flex shrink-0 items-center">
      <YeedoyLogo size={26} />
    </div>
  );
}

/** Sidebar altı — destek CTA kartı. Sidebar daraltıldığında tamamen gizlenir. */
function DestekKarti() {
  const { sidebarCollapsed } = usePanelStore();
  if (sidebarCollapsed) return null;

  return (
    <div className="mx-1 mb-1 rounded-xl border border-primary/20 bg-primary/5 p-3.5">
      <div className="mb-2 flex items-center gap-2">
        <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-primary/12 text-primary">
          <HeadsetIcon />
        </span>
        <p className="text-[12px] font-black text-textStrong">Yeedoy Destek</p>
      </div>
      <p className="mb-3 text-[11px] leading-relaxed text-muted">
        Yardım al ve destek ekibimize ulaş.
      </p>
      <Link
        href="/sahip/destek"
        className="flex min-h-9 items-center justify-center gap-1.5 rounded-lg bg-(--yd-color-primary) px-3 text-[11px] font-extrabold text-white transition-opacity hover:opacity-90"
      >
        Destek Talebi Oluştur
      </Link>
    </div>
  );
}

// ── Inline SVG icons ──────────────────────────────────────────────────────────

function HomeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      <polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
      <path d="M9 22V12h6v10" />
      <line x1="9" y1="6" x2="9.01" y2="6" />
      <line x1="15" y1="6" x2="15.01" y2="6" />
      <line x1="9" y1="10" x2="9.01" y2="10" />
      <line x1="15" y1="10" x2="15.01" y2="10" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
      <polyline points="10 9 9 9 8 9" />
    </svg>
  );
}

function ChartIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
    </svg>
  );
}

function PriceIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10"/><path d="M12 6v2m0 8v2m-4-5h8m-8 0a4 4 0 0 1 8 0"/>
    </svg>
  );
}

function StarIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function QrIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" />
      <rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" />
      <rect x="14" y="14" width="3" height="3" />
      <line x1="14" y1="20" x2="14" y2="20" />
      <line x1="20" y1="14" x2="20" y2="14" />
      <line x1="20" y1="20" x2="20" y2="20" />
    </svg>
  );
}

function UsersIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}


function ChoklusubeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="14" width="7" height="7" rx="1" />
      <rect x="3" y="14" width="7" height="7" rx="1" />
    </svg>
  );
}

function HeadsetIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
      <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
    </svg>
  );
}

function UserIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}

function SettingsIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  );
}

function RocketIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z" />
      <path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z" />
      <path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0" />
      <path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5" />
    </svg>
  );
}

function ActivityIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6M14 11v6" />
      <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  );
}

function CalendarIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}

function ImageIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="18" height="18" rx="2" />
      <circle cx="8.5" cy="8.5" r="1.5" />
      <polyline points="21 15 16 10 5 21" />
    </svg>
  );
}

function MegaphoneIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 11l18-5v12L3 13v-2z" />
      <path d="M11.6 16.8a3 3 0 1 1-5.8-1.6" />
    </svg>
  );
}

function ContactIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 21c0-4 3.5-7 8-7s8 3 8 7" />
    </svg>
  );
}

function GiftIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="8" width="18" height="4" />
      <path d="M12 8v13M19 12v9H5v-9" />
      <path d="M7.5 8a2.5 2.5 0 1 1 0-5C10 3 12 8 12 8" />
      <path d="M16.5 8a2.5 2.5 0 1 0 0-5C14 3 12 8 12 8" />
    </svg>
  );
}


function BellIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function ExternalLinkIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}

function CrownIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m2 20 2-11 5 5 3-8 3 8 5-5 2 11Z" />
    </svg>
  );
}

function HelpIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}

function ShieldIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}

