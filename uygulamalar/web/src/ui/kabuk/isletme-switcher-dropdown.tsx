'use client';

import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AKTIF_ISLETME_COOKIE_NAME } from './aktif-isletme-cerezi';

/** Modül seviyesinde tutulur — React Compiler'ın render/hook gövdesi içindeki
 * global mutasyonları (document.cookie) immutability ihlali olarak işaretlemesini önler. */
function aktifIsletmeCerezineYaz(id: string) {
  document.cookie = `${AKTIF_ISLETME_COOKIE_NAME}=${id}; path=/; max-age=31536000; samesite=lax`;
}

export interface IsletmeSwitcherOgesi {
  id: string;
  name: string;
  logoUrl: string | null;
}

interface Props {
  aktifIsletme: { id: string; name: string; isVerified: boolean };
  isletmeler: IsletmeSwitcherOgesi[];
}

export function IsletmeSwitcherDropdown({ aktifIsletme, isletmeler }: Props) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const router = useRouter();

  useEffect(() => {
    function onPointerDown(e: PointerEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, []);

  function secImle(id: string) {
    setOpen(false);
    if (id === aktifIsletme.id) return;
    aktifIsletmeCerezineYaz(id);
    router.refresh();
  }

  return (
    <div ref={ref} className="flex items-center gap-2">
      <div className="relative">
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          aria-haspopup="true"
          aria-expanded={open}
          className="flex items-center gap-1.5 rounded-lg border border-border bg-card px-2.5 py-1.5 text-xs font-extrabold text-textStrong transition-colors hover:bg-textStrong/[0.05]"
        >
          <span className="max-w-[180px] truncate">{aktifIsletme.name}</span>
          <ChevronDownIcon />
        </button>

        {open && isletmeler.length > 0 && (
          <div className="absolute left-0 top-full z-50 mt-2 w-64 overflow-hidden rounded-2xl border border-border bg-card shadow-lg">
            <p className="border-b border-border px-4 py-2.5 text-[11px] font-extrabold uppercase tracking-wide text-muted">
              İşletmelerim
            </p>
            <div className="max-h-72 overflow-y-auto py-1">
              {isletmeler.map((b) => (
                <button
                  key={b.id}
                  type="button"
                  onClick={() => secImle(b.id)}
                  className="flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm font-bold text-text transition-colors hover:bg-cardAlt hover:text-textStrong"
                >
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-primary/10 text-[11px] font-black text-primary">
                    {b.logoUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={b.logoUrl} alt={b.name} className="h-full w-full object-cover" />
                    ) : (
                      b.name.charAt(0).toUpperCase()
                    )}
                  </span>
                  <span className="min-w-0 flex-1 truncate">{b.name}</span>
                  {b.id === aktifIsletme.id && (
                    <span className="shrink-0 text-primary">
                      <CheckIcon />
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {aktifIsletme.isVerified && (
        <span className="hidden shrink-0 rounded-full bg-green-50 px-2.5 py-1 text-[11px] font-extrabold text-green-700 sm:inline-flex">
          Onaylı İşletme
        </span>
      )}
    </div>
  );
}

function ChevronDownIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-muted">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
