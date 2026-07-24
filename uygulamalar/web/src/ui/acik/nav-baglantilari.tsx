'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { clsx } from 'clsx';

interface NavItem {
  href: string;
  label: string;
}

export function NavLinks({ items }: { items: NavItem[] }) {
  const pathname = usePathname();

  return (
    <>
      {items.map((item) => {
        const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));
        return (
          <Link
            key={item.href}
            href={item.href}
            aria-current={isActive ? 'page' : undefined}
            className={clsx(
              'relative inline-flex min-h-11 items-center rounded-2xl px-3 text-sm font-black transition-colors',
              isActive
                ? 'text-primary'
                : 'text-textStrong hover:bg-cardAlt',
            )}
          >
            {item.label}
            {isActive && (
              <span
                aria-hidden="true"
                className="absolute bottom-1 left-1/2 h-[3px] w-4 -translate-x-1/2 rounded-full bg-primary"
              />
            )}
          </Link>
        );
      })}
    </>
  );
}
