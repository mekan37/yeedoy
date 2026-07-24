'use client';

import type { ReactNode } from 'react';
import { useScrolled } from './scroll-header';

export function HeaderSarmalayici({ children }: { children: ReactNode }) {
  const scrolled = useScrolled();
  return (
    <header
      className={`sticky top-0 z-40 border-b border-border bg-card/90 backdrop-blur-sm transition-shadow duration-200 ${
        scrolled ? 'shadow-yd2' : ''
      }`}
    >
      {children}
    </header>
  );
}
