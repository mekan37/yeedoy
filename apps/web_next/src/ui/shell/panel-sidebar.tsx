'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { clsx } from 'clsx';
import type { ReactNode } from 'react';

export interface NavItem {
  href: string;
  label: string;
  icon: ReactNode;
  /** If true, match exact path only */
  exact?: boolean;
}

export interface NavSection {
  title?: string;
  items: NavItem[];
}

interface PanelSidebarProps {
  sections: NavSection[];
  collapsed: boolean;
  logoSlot?: ReactNode;
  footerSlot?: ReactNode;
}

export function PanelSidebar({ sections, collapsed, logoSlot, footerSlot }: PanelSidebarProps) {
  const pathname = usePathname();

  return (
    <aside
      className={clsx(
        'flex flex-col border-r border-border bg-card transition-all duration-200',
        collapsed ? 'w-[72px]' : 'w-[260px]',
      )}
    >
      {/* Logo */}
      <div
        className={clsx(
          'flex h-[60px] shrink-0 items-center border-b border-border',
          collapsed ? 'justify-center px-0' : 'px-5',
        )}
      >
        {logoSlot}
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto overflow-x-hidden py-3">
        {sections.map((section, si) => (
          <div key={si} className="mb-1">
            {section.title && !collapsed && (
              <p className="mb-1 px-5 text-[10px] font-[800] uppercase tracking-[0.06em] text-muted">
                {section.title}
              </p>
            )}
            {section.items.map((item) => (
              <SidebarItem
                key={item.href}
                item={item}
                collapsed={collapsed}
                active={
                  item.exact
                    ? pathname === item.href
                    : pathname === item.href || pathname.startsWith(item.href + '/')
                }
              />
            ))}
          </div>
        ))}
      </nav>

      {/* Footer */}
      {footerSlot && (
        <div className={clsx('border-t border-border py-2', collapsed ? 'px-2' : 'px-3')}>
          {footerSlot}
        </div>
      )}
    </aside>
  );
}

function SidebarItem({
  item,
  collapsed,
  active,
}: {
  item: NavItem;
  collapsed: boolean;
  active: boolean;
}) {
  return (
    <Link
      href={item.href}
      title={collapsed ? item.label : undefined}
      className={clsx(
        'group relative flex min-h-[44px] items-center gap-3 rounded-xl transition-all duration-150',
        collapsed ? 'mx-2 px-0 justify-center' : 'mx-2 px-3',
        active
          ? 'bg-[color:var(--yd-color-primary-soft)] text-[color:var(--yd-color-primary)]'
          : 'text-text hover:bg-black/[0.04] hover:text-textStrong',
      )}
    >
      {/* Active indicator bar */}
      {active && !collapsed && (
        <span className="absolute left-0 top-[8px] bottom-[8px] w-[3px] rounded-r-full bg-[color:var(--yd-color-primary)]" />
      )}

      <span
        className={clsx(
          'flex h-5 w-5 shrink-0 items-center justify-center text-[18px]',
          active
            ? 'text-[color:var(--yd-color-primary)]'
            : 'text-muted group-hover:text-[color:var(--yd-color-text-strong)]',
        )}
      >
        {item.icon}
      </span>

      {!collapsed && (
        <span className="truncate text-sm font-[700]">{item.label}</span>
      )}
    </Link>
  );
}
