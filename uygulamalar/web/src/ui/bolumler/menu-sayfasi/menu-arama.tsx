'use client';

import { useEffect, useRef } from 'react';

// Menü verisi artık sunucu tarafında render ediliyor (MenuDuzen server
// component'e çevrildi) — bu küçük client-island'ın tek işi arama kutusunu
// render etmek ve zaten DOM'da mevcut olan ürün elementlerini gizleyip
// göstermek. React state'e menü verisini TAŞIMIYOR (yalnızca DOM query +
// hidden attribute), böylece arama filtresi neredeyse tüm listeyi
// etkilese bile hiçbir veri client bundle'ına gitmiyor.
export function MenuArama({
  placeholder,
  noResultsPrefix,
  noResultsSuffix,
  noResultsHint,
}: {
  placeholder: string;
  noResultsPrefix: string;
  noResultsSuffix: string;
  noResultsHint: string;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const noResultsRef = useRef<HTMLDivElement>(null);
  const queryTextRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const input = inputRef.current;
    if (!input) return;

    function applyFilter() {
      const q = (input!.value ?? '').trim().toLowerCase();
      const items = document.querySelectorAll<HTMLElement>('[data-menu-item]');
      const sections = document.querySelectorAll<HTMLElement>('[data-menu-section]');
      let anyVisible = false;

      items.forEach((item) => {
        const name = (item.dataset.menuName ?? '').toLowerCase();
        const desc = (item.dataset.menuDesc ?? '').toLowerCase();
        const matches = !q || name.includes(q) || desc.includes(q);
        item.hidden = !matches;
        if (matches) {
          anyVisible = true;
          // Eşleşen bir öğe "daha fazla göster" <details>'i içindeyse aç —
          // aksi halde kullanıcı eşleşmeyi hiç göremez.
          const details = item.closest('details');
          if (details && !details.open) details.open = true;
        }
      });

      sections.forEach((section) => {
        const hasVisibleItem = section.querySelector('[data-menu-item]:not([hidden])') !== null;
        section.hidden = q !== '' && !hasVisibleItem;
      });

      if (noResultsRef.current) {
        noResultsRef.current.hidden = !(q !== '' && !anyVisible);
      }
      if (queryTextRef.current) {
        queryTextRef.current.textContent = q;
      }
    }

    input.addEventListener('input', applyFilter);
    return () => input.removeEventListener('input', applyFilter);
  }, []);

  return (
    <>
      <div className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted" aria-hidden="true">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
          </svg>
        </span>
        <input
          ref={inputRef}
          type="search"
          placeholder={placeholder}
          className="h-11 w-full rounded-2xl border border-border bg-card pl-11 pr-4 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden transition-colors"
        />
      </div>

      <div ref={noResultsRef} hidden className="rounded-2xl border border-border bg-card px-6 py-12 text-center">
        <p className="text-3xl" aria-hidden="true">🔍</p>
        <p className="mt-3 text-sm font-black text-textStrong">
          {noResultsPrefix} &ldquo;<span ref={queryTextRef} />&rdquo; {noResultsSuffix}
        </p>
        <p className="mt-1 text-xs font-bold text-muted">{noResultsHint}</p>
      </div>
    </>
  );
}
