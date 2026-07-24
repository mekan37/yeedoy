'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';

type BusinessResult = {
  id: string;
  name: string;
  category: string | null;
  city: string | null;
  district: string | null;
  slug: string | null;
};

export function OwnerLandingSearch() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<BusinessResult[]>([]);
  const [searched, setSearched] = useState(false);
  const [isPending, startTransition] = useTransition();

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (!query.trim()) return;
    setSearched(false);
    startTransition(async () => {
      try {
        const res = await fetch(
          `/api/arama/anlik?q=${encodeURIComponent(query.trim())}`,
        );
        if (!res.ok) throw new Error('search failed');
        const data = await res.json() as { businesses?: BusinessResult[] };
        setResults((data.businesses ?? []).slice(0, 6));
      } catch {
        setResults([]);
      }
      setSearched(true);
    });
  }

  return (
    <div>
      <form onSubmit={handleSearch} className="flex gap-3">
        <div className="relative flex-1">
          <span className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-[#9ca3af]">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
          </span>
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="İşletme adı veya şehir girin…"
            className="h-14 w-full rounded-2xl border border-[#e5e7eb] bg-[#fafafa] pl-12 pr-4 text-base text-[#111827] placeholder:text-[#d1d5db] outline-hidden transition focus:border-[#dc2626] focus:bg-white focus:ring-2 focus:ring-[#dc2626]/10"
          />
        </div>
        <button
          type="submit"
          disabled={isPending || !query.trim()}
          className="h-14 rounded-2xl bg-[#dc2626] px-7 text-sm font-extrabold text-white shadow-[0_2px_8px_rgba(220,38,38,0.25)] transition hover:bg-[#b91c1c] disabled:opacity-60"
        >
          {isPending ? (
            <span className="flex items-center gap-2">
              <svg className="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M21 12a9 9 0 1 1-6.219-8.56" />
              </svg>
              Aranıyor
            </span>
          ) : 'Ara'}
        </button>
      </form>

      {/* Results */}
      {searched && (
        <div className="mt-4">
          {results.length === 0 ? (
            <div className="rounded-2xl border border-[#f0f0f0] bg-white p-8 text-center">
              <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-[#f9fafb]">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
              </div>
              <p className="font-bold text-[#374151]">&ldquo;{query}&rdquo; için sonuç bulunamadı</p>
              <p className="mt-1 text-sm text-[#9ca3af]">İşletmenizi yeni olarak ekleyebilirsiniz.</p>
              <Link
                href="/sahiplen/yeni"
                className="mt-4 inline-flex h-10 items-center gap-2 rounded-xl bg-[#dc2626] px-5 text-sm font-extrabold text-white"
              >
                Yeni İşletme Ekle
              </Link>
            </div>
          ) : (
            <div className="overflow-hidden rounded-2xl border border-[#f0f0f0] bg-white shadow-xs">
              {results.map((biz, i) => (
                <div
                  key={biz.id}
                  className={`flex items-center gap-4 px-5 py-4 ${i < results.length - 1 ? 'border-b border-[#f3f4f6]' : ''}`}
                >
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#fef2f2] text-base font-black text-[#dc2626]">
                    {biz.name[0].toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="font-extrabold text-[#111827] truncate">{biz.name}</p>
                    <p className="text-xs text-[#6b7280]">
                      {[biz.category, biz.district, biz.city].filter(Boolean).join(' · ')}
                    </p>
                  </div>
                  <Link
                    href={`/sahiplen/talep?id=${biz.id}`}
                    className="shrink-0 rounded-xl border border-[#dc2626] px-4 py-2 text-sm font-extrabold text-[#dc2626] transition hover:bg-[#fef2f2]"
                  >
                    Sahiplen
                  </Link>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
