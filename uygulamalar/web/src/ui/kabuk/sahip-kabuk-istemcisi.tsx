'use client';

import { useEffect, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { AppProviders } from '@/src/lib/uygulama-saglayicilari';
import { PanelShell } from './panel-kabugu';
import type { NavSection } from './panel-yan-menusu';
import { KullaniciFoteri } from './kullanici-foteri';
import { ReferralButonu } from './referral-butonu';
import { UserDropdown } from '@/src/ui/bilesenler/kullanici-dropdown';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { getOwnerBusinesses, getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

const ONBOARDING_NAV_HREF = '/sahip/baslangic';

const ownerNavSections: NavSection[] = [
  {
    title: 'Operasyon',
    items: [
      { href: '/sahip/gosterge-panosu', label: 'Genel Bakış', icon: <HomeIcon />, exact: true },
      { href: '/sahip/isletmeler', label: 'İşletmeler', icon: <BuildingIcon /> },
      { href: '/sahip/menuler', label: 'Menüler', icon: <MenuIcon /> },
      { href: '/sahip/baslangic', label: 'Başlangıç Rehberi', icon: <RocketIcon /> },
      { href: '/sahip/rezervasyonlar', label: 'Rezervasyonlar', icon: <CalendarIcon /> },
      { href: '/sahip/fotograflar', label: 'Fotoğraflar', icon: <ImageIcon /> },
    ],
  },
  {
    title: 'Büyüme',
    items: [
      { href: '/sahip/analitik', label: 'Analitik', icon: <ChartIcon /> },
      { href: '/sahip/fiyat-raporu', label: 'Fiyat Raporu', icon: <PriceIcon /> },
      { href: '/sahip/yorumlar', label: 'Yorumlar', icon: <StarIcon /> },
      { href: '/sahip/karekod', label: 'QR Kodlar', icon: <QrIcon /> },
      { href: '/sahip/pazarlama/kampanyalar', label: 'Kampanyalar', icon: <MegaphoneIcon /> },
      { href: '/sahip/yapay-zeka-analizi', label: 'Yapay Zeka Analizi', icon: <SparklesIcon /> },
    ],
  },
  {
    title: 'Yönetim',
    items: [
      { href: '/sahip/ekip', label: 'Ekip', icon: <UsersIcon /> },
      { href: '/sahip/fiyat-onerileri', label: 'Fiyat Önerileri', icon: <TagIcon /> },
      { href: '/sahip/istekler', label: 'Grup İstekleri', icon: <GroupIcon /> },
      { href: '/sahip/etkinlik', label: 'Aktivite', icon: <ActivityIcon /> },
      { href: '/sahip/bildirimler', label: 'Bildirimler', icon: <BellIcon /> },
      { href: '/sahip/denetim-kaydi', label: 'Denetim Kaydı', icon: <ClipboardIcon /> },
      { href: '/sahip/cop-kutusu', label: 'Çöp Kutusu', icon: <TrashIcon /> },
      { href: '/sahip/ayarlar', label: 'Ayarlar', icon: <SettingsIcon /> },
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

// Başlangıç Rehberi'ndeki 4 adım (işletme/menü/QR/ekip) tamamlanınca true
// döner — nav'dan "Başlangıç Rehberi" öğesi kaldırılır. null = henüz
// bilinmiyor (yükleniyor), bu sırada öğe görünür kalır.
function useOnboardingComplete() {
  const [complete, setComplete] = useState<boolean | null>(null);
  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    void supabase.auth.getSession().then(async ({ data }) => {
      if (!data.session?.user) return;
      const bizIds = await getOwnerBusinessIds(supabase as any, data.session.user.id);
      if (bizIds.length === 0) {
        setComplete(false);
        return;
      }
      const [menuRes, qrRes, teamRes] = await Promise.all([
        (supabase as any).from('menus').select('id', { count: 'exact', head: true }).in('business_id', bizIds).eq('status', 'published'),
        (supabase as any).from('business_qr_codes').select('id', { count: 'exact', head: true }).in('business_id', bizIds),
        (supabase as any).from('business_team_memberships').select('id', { count: 'exact', head: true }).in('business_id', bizIds).is('revoked_at', null),
      ]);
      setComplete((menuRes.count ?? 0) > 0 && (qrRes.count ?? 0) > 0 && (teamRes.count ?? 0) > 0);
    });
  }, []);
  return complete;
}

interface PrimaryBusiness {
  id: string;
  name: string;
  category: string | null;
  logo_url: string | null;
  is_verified: boolean | null;
  slug: string | null;
}

function useCurrentBusiness() {
  const [business, setBusiness] = useState<PrimaryBusiness | null>(null);
  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    void supabase.auth.getSession().then(async ({ data }) => {
      if (!data.session?.user) return;
      const businesses = await getOwnerBusinesses<PrimaryBusiness>(
        supabase as any,
        data.session.user.id,
        'id, name, category, logo_url, is_verified, slug',
      );
      const primary = [...businesses].sort((a, b) => a.name.localeCompare(b.name, 'tr'))[0] ?? null;
      setBusiness(primary);
    });
  }, []);
  return business;
}

interface SahipKabukIstemcisiProps {
  children: ReactNode;
  bannerSlot?: ReactNode;
}

// Public landing page (/sahip exact) — rendered without the authenticated
// panel chrome (sidebar/topbar), since logged-out visitors land here directly.
const PUBLIC_LANDING_PATH = '/sahip';

export function SahipKabukIstemcisi({ children, bannerSlot }: SahipKabukIstemcisiProps) {
  const pathname = usePathname();
  const user = useCurrentUser();
  const business = useCurrentBusiness();
  const onboardingComplete = useOnboardingComplete();

  if (pathname === PUBLIC_LANDING_PATH) {
    return <AppProviders>{children}</AppProviders>;
  }

  const navSections = onboardingComplete
    ? ownerNavSections.map((section) => ({
        ...section,
        items: section.items.filter((item) => item.href !== ONBOARDING_NAV_HREF),
      }))
    : ownerNavSections;

  return (
    <AppProviders>
      <PanelShell
        navSections={navSections}
        logoSlot={<OwnerLogo />}
        sidebarTop={business ? <SelectedBusinessCard business={business} /> : undefined}
        topbarTitle="Owner Panel"
        hideTopbarBadge
        hideThemeToggle
        topbarLeft={business ? <BusinessSwitcherButton business={business} /> : undefined}
        sidebarFooter={<><ReferralButonu /><KullaniciFoteri /></>}
        topbarActions={
          <>
            {business?.slug && (
              <a
                href={`/isletme/${business.slug}`}
                target="_blank"
                rel="noopener noreferrer"
                className="hidden items-center gap-1.5 rounded-xl border border-border px-3 py-1.5 text-xs font-[800] text-textStrong transition-colors hover:bg-bg sm:flex"
              >
                İşletme Sayfasını Gör
                <ExternalLinkIcon />
              </a>
            )}
            <Link
              href="/sahip/bildirimler"
              aria-label="Bildirimler"
              className="flex h-9 w-9 items-center justify-center rounded-full text-muted transition-colors hover:bg-bg hover:text-textStrong"
            >
              <TopbarBellIcon />
            </Link>
            {user ? (
              <div className="flex items-center gap-2 border-l border-border pl-2">
                <UserDropdown
                  displayName={user.displayName}
                  email={user.email}
                  avatarUrl={user.avatarUrl}
                  variant="topbar"
                />
                <div className="hidden text-right sm:block">
                  <p className="text-[13px] font-[800] leading-tight text-textStrong">
                    {user.displayName ?? user.email}
                  </p>
                  <p className="text-[11px] font-[600] text-muted">İşletme Sahibi</p>
                </div>
                <LogoutIconButton />
              </div>
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

function SelectedBusinessCard({ business }: { business: PrimaryBusiness }) {
  const logoUrl = business.logo_url ? buildMenuImageUrl(business.logo_url, { width: 88, quality: 84 }) : null;
  return (
    <div className="flex items-center gap-3">
      <div className="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-border bg-bg text-sm font-[900] text-textStrong">
        {logoUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logoUrl} alt={business.name} className="h-full w-full object-cover" />
        ) : (
          business.name.charAt(0).toUpperCase()
        )}
      </div>
      <div className="min-w-0">
        <p className="truncate text-[13px] font-[800] text-textStrong">{business.name}</p>
        {business.category && (
          <p className="truncate text-[11px] font-[600] text-muted">{business.category}</p>
        )}
        {business.is_verified && (
          <span className="mt-0.5 inline-flex items-center gap-1 rounded-full bg-green-50 px-2 py-0.5 text-[10px] font-[800] text-green-700">
            <span className="h-1.5 w-1.5 rounded-full bg-green-600" />
            Onaylı İşletme
          </span>
        )}
      </div>
    </div>
  );
}

function BusinessSwitcherButton({ business }: { business: PrimaryBusiness }) {
  const logoUrl = business.logo_url ? buildMenuImageUrl(business.logo_url, { width: 48, quality: 84 }) : null;
  return (
    <button
      type="button"
      className="flex items-center gap-2 rounded-xl border border-border bg-bg px-3 py-1.5 text-[13px] font-[800] text-textStrong transition-colors hover:bg-cardAlt"
    >
      <div className="flex h-6 w-6 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-card text-[11px] font-[900]">
        {logoUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logoUrl} alt={business.name} className="h-full w-full object-cover" />
        ) : (
          business.name.charAt(0).toUpperCase()
        )}
      </div>
      <span className="max-w-[160px] truncate">{business.name}</span>
      {business.is_verified && (
        <span className="rounded-full bg-green-50 px-2 py-0.5 text-[10px] font-[800] text-green-700">
          Onaylı İşletme
        </span>
      )}
      <ChevronDownIcon />
    </button>
  );
}

function LogoutIconButton() {
  async function handleLogout() {
    const supabase = createSupabaseBrowserClient();
    await supabase.auth.signOut();
    window.location.assign('/giris');
  }
  return (
    <button
      type="button"
      onClick={() => void handleLogout()}
      title="Çıkış Yap"
      className="ml-1 flex h-8 w-8 items-center justify-center rounded-lg text-muted transition-colors hover:bg-red-50 hover:text-red-600"
    >
      <LogoutIcon />
    </button>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <polyline points="6 9 12 15 18 9" />
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

function TopbarBellIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function ExternalLinkIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}

function OwnerLogo() {
  return (
    <div className="flex items-center gap-2">
      <div
        className="flex h-8 w-8 items-center justify-center rounded-lg text-white text-sm font-[900]"
        style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
      >
        Y
      </div>
      <span className="text-[15px] font-[900] text-textStrong">Yeedoy</span>
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

function TagIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z" />
      <line x1="7" y1="7" x2="7.01" y2="7" />
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

function GroupIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
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
      <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
      <circle cx="8.5" cy="8.5" r="1.5" />
      <polyline points="21 15 16 10 5 21" />
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

function MegaphoneIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m3 11 18-5v12L3 13v-2z" />
      <path d="M11.6 16.8a3 3 0 1 1-5.8-1.6" />
    </svg>
  );
}

function ClipboardIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" />
      <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
    </svg>
  );
}

function SparklesIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M18.4 5.6l-2.8 2.8M8.4 15.6l-2.8 2.8" />
    </svg>
  );
}

