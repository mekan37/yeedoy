'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { clsx } from 'clsx';

export type Aralik = '7g' | '30g' | '90g';

export interface AralikSecenegi {
  aralik: Aralik;
  etiket: string;
  tarihAraligi: string;
}

interface Props {
  aktif: Aralik;
  aktifTarihAraligi: string;
  secenekler: AralikSecenegi[];
  karsilastirmaEtiketi: string;
}

export function TarihAraligiSecici({ aktif, aktifTarihAraligi, secenekler, karsilastirmaEtiketi }: Props) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onPointerDown(e: PointerEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, []);

  return (
    <div className="flex flex-wrap items-center gap-2">
      <div ref={ref} className="relative">
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          aria-haspopup="true"
          aria-expanded={open}
          className="flex items-center gap-2 rounded-xl border border-border bg-card px-3.5 py-2 text-xs font-extrabold text-textStrong transition-colors hover:bg-black/4"
        >
          <CalendarIcon />
          {aktifTarihAraligi}
          <ChevronDownIcon />
        </button>

        {open && (
          <div className="absolute right-0 top-full z-50 mt-2 w-60 overflow-hidden rounded-2xl border border-border bg-card py-1 shadow-lg">
            {secenekler.map((s) => (
              <Link
                key={s.aralik}
                href={`/sahip/analitik?aralik=${s.aralik}`}
                onClick={() => setOpen(false)}
                className={clsx(
                  'flex flex-col gap-0.5 px-4 py-2.5 text-left transition-colors hover:bg-cardAlt',
                  s.aralik === aktif && 'bg-primary/5',
                )}
              >
                <span className="text-sm font-bold text-textStrong">{s.etiket}</span>
                <span className="text-[11px] text-muted">{s.tarihAraligi}</span>
              </Link>
            ))}
          </div>
        )}
      </div>

      <div className="flex items-center gap-1.5 rounded-xl border border-border bg-card px-3.5 py-2 text-xs font-extrabold text-textStrong">
        <CompareIcon />
        Karşılaştırma: {karsilastirmaEtiketi}
      </div>
    </div>
  );
}

function CalendarIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted">
      <rect x="3" y="4" width="18" height="18" rx="2" />
      <path d="M16 2v4M8 2v4M3 10h18" />
    </svg>
  );
}

function CompareIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted">
      <path d="M8 3 4 7l4 4M4 7h13M16 21l4-4-4-4M20 17H7" />
    </svg>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  );
}
