'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';

const STORAGE_KEY = 'yd_recent_searches';
const MAX_RECENT = 8;

function getRecent(): string[] {
  if (typeof window === 'undefined') return [];
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '[]') as string[];
  } catch {
    return [];
  }
}

function addRecent(q: string) {
  if (!q.trim()) return;
  const prev = getRecent().filter(r => r !== q.trim());
  const next = [q.trim(), ...prev].slice(0, MAX_RECENT);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
}

function clearRecent() {
  localStorage.removeItem(STORAGE_KEY);
}

// Autocomplete suggestions based on common food categories
const QUICK_SUGGESTIONS = [
  'Kahvaltı', 'Vejetaryen', 'Vegan', 'Halal', 'Balık', 'Et', 'Tavuk',
  'Fast Food', 'Restoran', 'Kafe', 'Pastane', 'Sushi', 'İtalyan', 'Çin',
];

export function RecentSearches({ currentQ }: { currentQ: string }) {
  const [recent, setRecent] = useState<string[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [inputVal, setInputVal] = useState(currentQ);
  const inputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    setRecent(getRecent());
    // Save current q if it came from a search
    if (currentQ.trim()) {
      addRecent(currentQ.trim());
      setRecent(getRecent());
    }
  }, [currentQ]);

  const suggestions = QUICK_SUGGESTIONS.filter(s =>
    inputVal.length > 0 && s.toLowerCase().startsWith(inputVal.toLowerCase()) && s !== inputVal
  ).slice(0, 5);

  if (recent.length === 0 && !inputVal) return null;

  return (
    <div className="mb-8">
      {/* Inline autocomplete search */}
      <div className="relative mb-6">
        <p className="mb-2 text-xs font-black uppercase tracking-wide text-muted">Hızlı Arama</p>
        <div className="relative">
          <input
            ref={inputRef}
            value={inputVal}
            onChange={e => { setInputVal(e.target.value); setShowSuggestions(true); }}
            onFocus={() => setShowSuggestions(true)}
            onBlur={() => setTimeout(() => setShowSuggestions(false), 150)}
            placeholder="Ör: pizza, burger, kahvaltı..."
            className="w-full rounded-2xl border border-border bg-card px-4 py-3 pr-12 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
          />
          {inputVal && (
            <button
              onClick={() => setInputVal('')}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong"
              aria-label="Temizle"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <line x1="18" y1="6" x2="6" y2="18" />
                <line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          )}

          {/* Autocomplete dropdown */}
          {showSuggestions && suggestions.length > 0 && (
            <div className="absolute left-0 right-0 top-full z-20 mt-1 overflow-hidden rounded-2xl border border-border bg-card shadow-lg">
              {suggestions.map(s => (
                <Link
                  key={s}
                  href={`/arama?q=${encodeURIComponent(s)}`}
                  className="flex items-center gap-3 px-4 py-3 text-sm font-bold text-textStrong hover:bg-cardAlt"
                  onClick={() => addRecent(s)}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-muted">
                    <circle cx="11" cy="11" r="8" />
                    <line x1="21" y1="21" x2="16.65" y2="16.65" />
                  </svg>
                  {s}
                </Link>
              ))}
            </div>
          )}
        </div>
        {inputVal && (
          <Link
            href={`/arama?q=${encodeURIComponent(inputVal)}`}
            onClick={() => addRecent(inputVal)}
            className="mt-2 inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-sm font-extrabold text-white hover:bg-primary/90"
          >
            &quot;{inputVal}&quot; için ara
          </Link>
        )}
      </div>

      {/* Recent searches */}
      {recent.length > 0 && (
        <section>
          <div className="mb-2 flex items-center justify-between">
            <p className="text-xs font-black uppercase tracking-wide text-muted">Son Aramalarım</p>
            <button
              onClick={() => { clearRecent(); setRecent([]); }}
              className="text-xs font-bold text-muted hover:text-danger"
            >
              Temizle
            </button>
          </div>
          <div className="flex flex-wrap gap-2">
            {recent.map(r => (
              <Link
                key={r}
                href={`/arama?q=${encodeURIComponent(r)}`}
                className="inline-flex min-h-[36px] items-center gap-2 rounded-full border border-border bg-card px-3 text-sm font-bold text-textStrong hover:border-primary/40 hover:text-primary"
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-muted">
                  <polyline points="1 4 1 10 7 10" />
                  <path d="M3.51 15a9 9 0 1 0 .49-3.15" />
                </svg>
                {r}
              </Link>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
