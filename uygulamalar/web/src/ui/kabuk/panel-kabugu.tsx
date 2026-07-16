'use client';

import { useEffect, type ReactNode } from 'react';
import { PanelSidebar, type NavSection } from './panel-yan-menusu';
import { PanelTopbar, TopbarIconButton } from './panel-ust-cubugu';
import { usePanelStore } from '@/src/lib/panel-deposu';
import { ThemeToggle } from '@/src/ui/bilesenler/tema-degistirici';

interface PanelShellProps {
  navSections: NavSection[];
  logoSlot?: ReactNode;
  sidebarTop?: ReactNode;
  topbarTitle?: string;
  hideTopbarBadge?: boolean;
  topbarLeft?: ReactNode;
  topbarCenter?: ReactNode;
  topbarActions?: ReactNode;
  /** true ise topbar'daki açık/koyu tema anahtarı gizlenir. */
  hideThemeToggle?: boolean;
  sidebarFooter?: ReactNode;
  bannerSlot?: ReactNode;
  children: ReactNode;
}

const COLLAPSE_BREAKPOINT = 1280;

export function PanelShell({
  navSections,
  logoSlot,
  sidebarTop,
  topbarTitle,
  hideTopbarBadge,
  topbarLeft,
  topbarCenter,
  topbarActions,
  hideThemeToggle,
  sidebarFooter,
  bannerSlot,
  children,
}: PanelShellProps) {
  const { sidebarCollapsed, toggleSidebar, setSidebarCollapsed } = usePanelStore();

  // Auto-collapse on narrow screens
  useEffect(() => {
    function handle() {
      if (window.innerWidth < COLLAPSE_BREAKPOINT) {
        setSidebarCollapsed(true);
      }
    }
    handle();
    window.addEventListener('resize', handle);
    return () => window.removeEventListener('resize', handle);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="flex h-screen overflow-hidden bg-bg">
      {/* Sidebar */}
      <PanelSidebar
        sections={navSections}
        collapsed={sidebarCollapsed}
        logoSlot={logoSlot}
        topSlot={sidebarTop}
        footerSlot={sidebarFooter}
      />

      {/* Main area */}
      <div className="flex flex-1 flex-col overflow-hidden">
        <PanelTopbar
          title={topbarTitle}
          hideBadge={hideTopbarBadge}
          leftSlot={topbarLeft}
          centerSlot={topbarCenter}
          toggleButton={
            <TopbarIconButton label="Menüyü aç/kapat" onClick={toggleSidebar}>
              <CollapseIcon collapsed={sidebarCollapsed} />
            </TopbarIconButton>
          }
          actions={
            <>
              {topbarActions}
              {!hideThemeToggle && <ThemeToggle className="min-h-9 min-w-9 rounded-lg" />}
            </>
          }
        />
        {bannerSlot}
        <main className="flex-1 overflow-y-auto">{children}</main>
      </div>
    </div>
  );
}

function CollapseIcon({ collapsed }: { collapsed: boolean }) {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
      {collapsed ? (
        <>
          <line x1="2" y1="5" x2="16" y2="5" />
          <line x1="2" y1="9" x2="16" y2="9" />
          <line x1="2" y1="13" x2="16" y2="13" />
        </>
      ) : (
        <>
          <line x1="2" y1="5" x2="16" y2="5" />
          <line x1="2" y1="9" x2="10" y2="9" />
          <line x1="2" y1="13" x2="16" y2="13" />
        </>
      )}
    </svg>
  );
}
