'use client';

import { useEffect, useState } from 'react';

/** Returns true once the page has scrolled past `threshold` px */
export function useScrolled(threshold = 8): boolean {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    function check() {
      setScrolled(window.scrollY > threshold);
    }
    check();
    window.addEventListener('scroll', check, { passive: true });
    return () => window.removeEventListener('scroll', check);
  }, [threshold]);

  return scrolled;
}
