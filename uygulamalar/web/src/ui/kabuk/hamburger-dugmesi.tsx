'use client';

import { useWebKabukStore } from '@/src/lib/web-kabuk-deposu';

export function HamburgerDugmesi() {
  const toggleDrawer = useWebKabukStore((s) => s.toggleDrawer);
  const isOpen = useWebKabukStore((s) => s.isDrawerOpen);

  return (
    <button
      type="button"
      onClick={toggleDrawer}
      aria-label={isOpen ? 'Menüyü kapat' : 'Menüyü aç'}
      aria-expanded={isOpen}
      className="flex h-10 w-10 items-center justify-center rounded-2xl text-text hover:bg-cardAlt focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 md:hidden"
    >
      <svg
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        aria-hidden="true"
      >
        <line x1="2" y1="5" x2="18" y2="5" />
        <line x1="2" y1="10" x2="18" y2="10" />
        <line x1="2" y1="15" x2="18" y2="15" />
      </svg>
    </button>
  );
}
