'use client';

import { useEffect } from 'react';

const ACTIVE_CLASSES = ['border-primary', 'bg-primary/5', 'text-primary'];
const INACTIVE_CLASSES = ['border-transparent', 'text-textStrong'];

// Scroll pozisyonuna göre sol kenar çubuğunda hangi kategorinin "aktif"
// göründüğünü günceller — yalnızca CSS class toggle eder, hiçbir veri
// taşımaz/render etmez (return null). İlk sunucu render'ında "Öne Çıkanlar"
// zaten aktif class'larla geliyor (bkz. menu-duzen.tsx); bu component
// yalnızca kullanıcı kaydırdıkça günceller.
export function MenuSidebarVurgu() {
  useEffect(() => {
    const sections = Array.from(document.querySelectorAll<HTMLElement>('[data-menu-section-id]'));
    const links = new Map<string, HTMLElement>();
    document.querySelectorAll<HTMLElement>('[data-sidebar-link]').forEach((el) => {
      const id = el.dataset.sidebarLink;
      if (id) links.set(id, el);
    });
    if (sections.length === 0 || links.size === 0) return;

    const setActive = (activeId: string) => {
      links.forEach((link, linkId) => {
        if (linkId === activeId) {
          link.classList.remove(...INACTIVE_CLASSES);
          link.classList.add(...ACTIVE_CLASSES);
        } else {
          link.classList.remove(...ACTIVE_CLASSES);
          link.classList.add(...INACTIVE_CLASSES);
        }
      });
    };

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries.find((e) => e.isIntersecting);
        if (visible) {
          const id = (visible.target as HTMLElement).dataset.menuSectionId;
          if (id) setActive(id);
        }
      },
      { rootMargin: '0px 0px -70% 0px', threshold: 0 },
    );

    sections.forEach((s) => observer.observe(s));
    return () => observer.disconnect();
  }, []);

  return null;
}
