'use client';

import { useState } from 'react';
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
  /** Badge text shown after label — e.g. 'Yakında' */
  badge?: string;
  /** 'primary' = dolu kırmızı sayaç rozeti (bildirim sayısı gibi); 'muted' = nötr pill (varsayılan) */
  badgeTone?: 'muted' | 'primary';
  /** Disabled: shows badge, prevents navigation */
  disabled?: boolean;
  /** Alt-sekmeler — verilirse öğe genişletilebilir bir grup olarak render edilir */
  children?: NavItem[];
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
  /** true = koyu (lacivert) sidebar teması — admin panelinde kullanılır */
  dark?: boolean;
}

export function PanelSidebar({ sections, collapsed, logoSlot, footerSlot, dark = false }: PanelSidebarProps) {
  const pathname = usePathname();

  return (
    <aside
      className={clsx(
        'flex flex-col border-r transition-all duration-200',
        dark ? 'border-white/10 bg-[#0b1220]' : 'border-border bg-card',
        collapsed ? 'w-[72px]' : 'w-[260px]',
      )}
    >
      {/* Logo / kimlik alanı — owner panelinde işletme kartı, admin'de sabit logo yüksekliği */}
      <div
        className={clsx(
          'flex min-h-[60px] shrink-0 items-center border-b',
          dark ? 'border-white/10' : 'border-border',
          collapsed ? 'justify-center px-0 py-2' : 'px-4 py-3',
        )}
      >
        {logoSlot}
      </div>

      {/* Nav */}
      <nav className={clsx('flex-1 overflow-y-auto overflow-x-hidden py-3', dark && 'yd-sidebar-scroll-dark')}>
        {sections.map((section, si) => (
          <div key={si} className="mb-1">
            {section.title && !collapsed && (
              <p className={clsx('mb-1 px-5 text-[10px] font-extrabold uppercase tracking-[0.06em]', dark ? 'text-white/35' : 'text-muted')}>
                {section.title}
              </p>
            )}
            {section.items.map((item) =>
              item.children && item.children.length > 0 ? (
                <SidebarGroup key={item.href} item={item} collapsed={collapsed} pathname={pathname} dark={dark} />
              ) : (
                <SidebarItem
                  key={item.href}
                  item={item}
                  collapsed={collapsed}
                  dark={dark}
                  active={
                    item.exact
                      ? pathname === item.href
                      : pathname === item.href || pathname.startsWith(item.href + '/')
                  }
                />
              ),
            )}
          </div>
        ))}
      </nav>

      {/* Footer — daraltılmışken kenarlık/boşluk yok, içerik kendi görünürlüğüne karar verir */}
      {footerSlot && (
        <div className={clsx(collapsed ? 'px-2' : clsx('border-t px-3 py-2', dark ? 'border-white/10' : 'border-border'))}>
          {footerSlot}
        </div>
      )}
    </aside>
  );
}

function SidebarGroup({
  item,
  collapsed,
  pathname,
  dark = false,
}: {
  item: NavItem;
  collapsed: boolean;
  pathname: string;
  dark?: boolean;
}) {
  const children = item.children!;
  const isChildActive = (child: NavItem) =>
    child.exact ? pathname === child.href : pathname === child.href || pathname.startsWith(child.href + '/');
  const childActive = children.some(isChildActive);
  // null = kullanıcı henüz elle değiştirmedi — bu durumda aktif alt-öğe olması
  // grubu otomatik açık tutar. Elle kapatılırsa artık kullanıcının tercihi geçerli olur.
  const [manualOpen, setManualOpen] = useState<boolean | null>(null);
  const open = manualOpen ?? childActive;

  if (collapsed) {
    return (
      <SidebarItem
        item={item}
        collapsed={collapsed}
        dark={dark}
        active={childActive || pathname === item.href}
      />
    );
  }

  return (
    <div className="mx-2">
      <button
        type="button"
        onClick={() => setManualOpen(!open)}
        aria-expanded={open}
        className={clsx(
          'group relative flex min-h-[38px] w-[calc(100%-0px)] items-center gap-2.5 rounded-xl px-3 transition-all duration-150',
          childActive
            ? 'text-(--yd-color-primary)'
            : dark
              ? 'text-white/70 hover:bg-white/5 hover:text-white'
              : 'text-text hover:bg-textStrong/[0.06] hover:text-textStrong',
        )}
      >
        <span
          className={clsx(
            'flex h-4 w-4 shrink-0 items-center justify-center text-[16px]',
            childActive ? 'text-(--yd-color-primary)' : dark ? 'text-white/40 group-hover:text-white' : 'text-muted group-hover:text-(--yd-color-text-strong)',
          )}
        >
          {item.icon}
        </span>
        <span className="flex-1 truncate text-left text-[13px] font-bold">{item.label}</span>
        <span className={clsx('shrink-0 transition-transform duration-150', dark ? 'text-white/40' : 'text-muted', open && 'rotate-180')}>
          <ChevronDownIcon />
        </span>
      </button>

      {open && (
        <div className={clsx('ml-[20px] mt-0.5 mb-1 flex flex-col gap-0.5 border-l pl-3', dark ? 'border-white/10' : 'border-border')}>
          {children.map((child) => (
            <Link
              key={child.href}
              href={child.href}
              className={clsx(
                'relative flex min-h-8 items-center rounded-lg px-2.5 text-[13px] font-bold transition-colors',
                isChildActive(child)
                  ? 'text-(--yd-color-primary)'
                  : dark
                    ? 'text-white/50 hover:bg-white/5 hover:text-white'
                    : 'text-muted hover:bg-textStrong/[0.06] hover:text-textStrong',
              )}
            >
              <span
                className={clsx(
                  'absolute -left-[13px] h-1.5 w-1.5 rounded-full',
                  isChildActive(child) ? 'bg-(--yd-color-primary)' : dark ? 'bg-white/15' : 'bg-border',
                )}
              />
              {child.label}
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  );
}

function SidebarItem({
  item,
  collapsed,
  active,
  dark = false,
}: {
  item: NavItem;
  collapsed: boolean;
  active: boolean;
  dark?: boolean;
}) {
  const isDisabled = item.disabled === true;

  const inner = (
    <>
      {/* Active indicator bar — sadece açık temada (koyu temada dolu pill zaten belirgin) */}
      {active && !collapsed && !isDisabled && !dark && (
        <span className="absolute left-0 top-[8px] bottom-[8px] w-[3px] rounded-r-full bg-(--yd-color-primary)" />
      )}

      <span
        className={clsx(
          'flex h-4 w-4 shrink-0 items-center justify-center text-[16px]',
          isDisabled
            ? dark ? 'text-white/25' : 'text-muted/50'
            : active
              ? dark ? 'text-white' : 'text-(--yd-color-primary)'
              : dark ? 'text-white/40 group-hover:text-white' : 'text-muted group-hover:text-(--yd-color-text-strong)',
        )}
      >
        {item.icon}
      </span>

      {!collapsed && (
        <>
          <span
            className={clsx(
              'flex-1 truncate text-[13px] font-bold',
              isDisabled && (dark ? 'text-white/30' : 'text-muted/60'),
            )}
          >
            {item.label}
          </span>
          {item.badge && (
            <span
              className={clsx(
                'shrink-0 rounded-full px-1.5 py-0.5 text-[9px] font-extrabold uppercase tracking-wider',
                item.badgeTone === 'primary'
                  ? 'bg-(--yd-color-primary) text-white'
                  : dark ? 'bg-white/10 text-white/70' : 'bg-muted/15 text-muted',
              )}
            >
              {item.badge}
            </span>
          )}
        </>
      )}
    </>
  );

  const baseClass = clsx(
    'group relative flex min-h-[38px] items-center gap-2.5 rounded-xl transition-all duration-150',
    collapsed ? 'mx-2 px-0 justify-center' : 'mx-2 px-3',
  );

  if (isDisabled) {
    return (
      <div
        title={collapsed ? item.label : undefined}
        className={clsx(baseClass, 'cursor-not-allowed opacity-50')}
      >
        {inner}
      </div>
    );
  }

  return (
    <Link
      href={item.href}
      title={collapsed ? item.label : undefined}
      className={clsx(
        baseClass,
        active
          ? dark
            ? 'text-white shadow-sm'
            : 'bg-(--yd-color-primary-soft) text-(--yd-color-primary)'
          : dark
            ? 'text-white/70 hover:bg-white/5 hover:text-white'
            : 'text-text hover:bg-textStrong/[0.06] hover:text-textStrong',
      )}
      style={active && dark ? { background: 'linear-gradient(135deg, #dc2626, #991b1b)' } : undefined}
    >
      {inner}
    </Link>
  );
}
