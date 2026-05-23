'use client';

import { useState, useCallback, useRef } from 'react';
import Link from 'next/link';

type BusinessResult = {
  id: string;
  name: string;
  category: string;
  city: string | null;
  district: string | null;
  address: string | null;
};

export function IsletmeAramaIstemcisi() {
  const [name, setName]         = useState('');
  const [city, setCity]         = useState('');
  const [district, setDistrict] = useState('');
  const [results, setResults]   = useState<BusinessResult[]>([]);
  const [loading, setLoading]   = useState(false);
  const [searched, setSearched] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const search = useCallback(async (n: string, c: string, d: string) => {
    if (!n.trim() && !c.trim() && !d.trim()) {
      setResults([]);
      setSearched(false);
      return;
    }
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (n.trim()) params.set('q', n.trim());
      if (c.trim()) params.set('city', c.trim());
      if (d.trim()) params.set('district', d.trim());
      const res = await fetch(`/sunucu/isletme-ara?${params}`);
      const data = await res.json();
      setResults(data.results ?? []);
      setSearched(true);
    } catch {
      setResults([]);
      setSearched(true);
    } finally {
      setLoading(false);
    }
  }, []);

  const handleChange = useCallback(
    (n: string, c: string, d: string) => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      debounceRef.current = setTimeout(() => search(n, c, d), 400);
    },
    [search],
  );

  return (
    <div className="space-y-4">
      {/* Arama formu */}
      <div className="overflow-hidden rounded-2xl border border-border bg-bg shadow-sm">
        <div className="grid gap-0 divide-y divide-border sm:grid-cols-3 sm:divide-x sm:divide-y-0">
          <div className="flex flex-col p-3">
            <label className="mb-1 text-[11px] font-[800] uppercase tracking-wider text-muted">
              İşletme Adı
            </label>
            <input
              type="text"
              value={name}
              placeholder="Örn: Eyvan Kebap"
              onChange={(e) => {
                setName(e.target.value);
                handleChange(e.target.value, city, district);
              }}
              className="bg-transparent text-sm font-[700] text-textStrong outline-none placeholder:text-muted/50"
            />
          </div>
          <div className="flex flex-col p-3">
            <label className="mb-1 text-[11px] font-[800] uppercase tracking-wider text-muted">
              Şehir (İl)
            </label>
            <input
              type="text"
              value={city}
              placeholder="Örn: Ankara"
              onChange={(e) => {
                setCity(e.target.value);
                handleChange(name, e.target.value, district);
              }}
              className="bg-transparent text-sm font-[700] text-textStrong outline-none placeholder:text-muted/50"
            />
          </div>
          <div className="flex flex-col p-3">
            <label className="mb-1 text-[11px] font-[800] uppercase tracking-wider text-muted">
              İlçe
            </label>
            <input
              type="text"
              value={district}
              placeholder="Örn: Yenimahalle"
              onChange={(e) => {
                setDistrict(e.target.value);
                handleChange(name, city, e.target.value);
              }}
              className="bg-transparent text-sm font-[700] text-textStrong outline-none placeholder:text-muted/50"
            />
          </div>
        </div>
        <div className="border-t border-border px-3 py-2">
          <button
            type="button"
            onClick={() => search(name, city, district)}
            className="rounded-xl bg-primary px-4 py-2 text-sm font-[900] text-white"
          >
            {loading ? 'Aranıyor…' : 'Ara'}
          </button>
        </div>
      </div>

      {/* Sonuçlar */}
      {searched && results.length === 0 && (
        <div className="rounded-2xl border border-border bg-bg p-6 text-center">
          <p className="font-[800] text-textStrong">Sonuç bulunamadı</p>
          <p className="mt-1 text-sm text-muted">
            Farklı anahtar kelime deneyin veya işletmenizi aşağıdan yeni olarak ekleyin.
          </p>
          <div className="mt-4 flex justify-center gap-3">
            <Link
              href="/sahiplen/yeni"
              className="rounded-xl border border-border bg-bg px-4 py-2 text-sm font-[800] text-text hover:bg-cardAlt"
            >
              Yeni İşletme Ekle
            </Link>
          </div>
        </div>
      )}

      {results.length > 0 && (
        <div className="overflow-hidden rounded-2xl border border-border bg-bg shadow-sm">
          <div className="border-b border-border px-4 py-3">
            <p className="text-sm font-[800] text-textStrong">
              {results.length} işletme bulundu — işletmenizi seçin
            </p>
          </div>
          <ul className="divide-y divide-border">
            {results.map((b) => (
              <li key={b.id}>
                <Link
                  href={`/sahiplen/talep?id=${b.id}`}
                  className="flex items-start gap-3 px-4 py-4 transition-colors hover:bg-cardAlt"
                >
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-border bg-cardAlt text-xl">
                    {categoryEmoji(b.category)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-[800] text-textStrong">{b.name}</p>
                    <p className="mt-0.5 truncate text-xs text-muted">
                      {[b.category, b.district, b.city].filter(Boolean).join(' · ')}
                    </p>
                    {b.address && (
                      <p className="mt-0.5 truncate text-xs text-muted">{b.address}</p>
                    )}
                  </div>
                  <span className="shrink-0 rounded-xl border border-primary/25 bg-primary/8 px-2.5 py-1 text-xs font-[800] text-primary">
                    Seç →
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* İşletmem listede yok */}
      {searched && results.length > 0 && (
        <p className="text-center text-sm text-muted">
          İşletmenizi göremiyorsanız{' '}
          <Link href="/sahiplen/yeni" className="font-[800] text-primary hover:underline">
            yeni işletme ekleyin
          </Link>
          .
        </p>
      )}
    </div>
  );
}

function categoryEmoji(cat: string) {
  const map: Record<string, string> = {
    Restoran: '🍽️',
    Kafe: '☕',
    'Balık / Et': '🥩',
    Tatlıcı: '🍰',
    Kahvaltı: '🥐',
    Mekan: '🎵',
  };
  return map[cat] ?? '🏪';
}
