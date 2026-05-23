'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useMemo, useRef, useState, type FormEvent } from 'react';
import {
  ADMIN_SEARCH_CATEGORY_BADGES,
  ADMIN_SEARCH_CATEGORY_LABELS,
  type AdminSearchResult,
} from '@/src/lib/veri/admin/yonetici-arama';

export function YoneticiUstArama() {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<AdminSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [error, setError] = useState(false);
  const closeTimer = useRef<number | null>(null);

  const trimmedQuery = query.trim();
  const allResultsHref = useMemo(
    () => `/yonetici/arama?q=${encodeURIComponent(trimmedQuery)}&type=all`,
    [trimmedQuery],
  );

  useEffect(() => {
    if (trimmedQuery.length < 2) {
      setResults([]);
      setLoading(false);
      setError(false);
      return;
    }

    const controller = new AbortController();
    const timer = window.setTimeout(async () => {
      setLoading(true);
      setError(false);

      try {
        const response = await fetch(
          `/sunucu/yonetici/arama?q=${encodeURIComponent(trimmedQuery)}&type=all&limit=5`,
          { signal: controller.signal },
        );

        if (!response.ok) {
          setResults([]);
          setError(true);
          return;
        }

        const payload = await response.json() as { data?: AdminSearchResult[] };
        setResults(payload.data ?? []);
      } catch (err) {
        if (!controller.signal.aborted) {
          setResults([]);
          setError(true);
        }
      } finally {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }, 180);

    return () => {
      controller.abort();
      window.clearTimeout(timer);
    };
  }, [trimmedQuery]);

  function handleBlur() {
    closeTimer.current = window.setTimeout(() => setOpen(false), 140);
  }

  function keepOpen() {
    if (closeTimer.current) window.clearTimeout(closeTimer.current);
    setOpen(true);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (trimmedQuery.length >= 2) {
      router.push(allResultsHref);
      setOpen(false);
    }
  }

  const showPanel = open && trimmedQuery.length >= 2;

  return (
    <form
      onSubmit={handleSubmit}
      className="relative hidden w-full max-w-xl md:block"
      role="search"
      onFocus={keepOpen}
      onBlur={handleBlur}
    >
      <SearchIcon />
      <input
        value={query}
        onChange={(event) => {
          setQuery(event.target.value);
          setOpen(true);
        }}
        placeholder="İşletme, kullanıcı, rapor ara..."
        className="h-11 w-full rounded-xl border border-border bg-bg pl-10 pr-4 text-sm font-[600] text-textStrong placeholder:text-muted transition-colors focus:border-primary/40 focus:outline-none focus:ring-2 focus:ring-primary/20"
      />

      {showPanel && (
        <div className="absolute left-0 right-0 top-[48px] z-50 overflow-hidden rounded-xl border border-border bg-card shadow-yd2">
          <div className="max-h-[360px] overflow-y-auto py-1">
            {loading && results.length === 0 && (
              <p className="px-4 py-3 text-sm text-muted">Aranıyor...</p>
            )}

            {!loading && error && (
              <p className="px-4 py-3 text-sm text-muted">Arama şu anda çalıştırılamıyor.</p>
            )}

            {!loading && !error && results.length === 0 && (
              <p className="px-4 py-3 text-sm text-muted">Sonuç bulunamadı.</p>
            )}

            {results.map((item) => (
              <Link
                key={`${item.category}-${item.item_id}`}
                href={item.href}
                className="flex items-center justify-between gap-3 px-4 py-3 transition-colors hover:bg-black/[0.03]"
                onClick={() => setOpen(false)}
              >
                <span className="min-w-0">
                  <span className="block truncate text-sm font-[800] text-textStrong">{item.title}</span>
                  <span className="block truncate text-xs text-muted">{item.subtitle}</span>
                </span>
                <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-[800] ${ADMIN_SEARCH_CATEGORY_BADGES[item.category] ?? 'bg-zinc-100 text-zinc-600'}`}>
                  {ADMIN_SEARCH_CATEGORY_LABELS[item.category] ?? item.category}
                </span>
              </Link>
            ))}
          </div>

          <Link
            href={allResultsHref}
            className="flex min-h-11 items-center justify-center border-t border-border px-4 text-sm font-[800] text-primary transition-colors hover:bg-primary/5"
            onClick={() => setOpen(false)}
          >
            Tümünü Göster
          </Link>
        </div>
      )}
    </form>
  );
}

function SearchIcon() {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-muted"
    >
      <circle cx="11" cy="11" r="8" />
      <line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  );
}
