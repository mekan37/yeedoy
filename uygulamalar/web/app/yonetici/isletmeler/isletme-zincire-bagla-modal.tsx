'use client';

import { useRef, useState } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import {
  zincirAra,
  isletmeleriZincireBagla,
  yeniZincirKurVeBagla,
  type ZincirAramaSonucu,
} from './isletme-zincir-islemleri';

type Sekme = 'mevcut' | 'yeni';

export function IsletmeZincireBaglaModal({
  businesses,
  onClose,
  onDone,
}: {
  businesses: { id: string; name: string }[];
  onClose: () => void;
  onDone: () => void;
}) {
  const [sekme, setSekme] = useState<Sekme>('mevcut');
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<ZincirAramaSonucu[]>([]);
  const [searching, setSearching] = useState(false);
  const [selectedChain, setSelectedChain] = useState<ZincirAramaSonucu | null>(null);
  const [newChainName, setNewChainName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const requestIdRef = useRef(0);

  const businessIds = businesses.map((b) => b.id);

  function handleSearch(q: string) {
    setQuery(q);
    setError(null);
    if (debounceRef.current) clearTimeout(debounceRef.current);

    if (!q.trim()) {
      requestIdRef.current += 1;
      setResults([]);
      setSearching(false);
      return;
    }

    debounceRef.current = setTimeout(() => {
      const requestId = ++requestIdRef.current;
      setSearching(true);
      zincirAra(q).then((sonuc) => {
        if (requestIdRef.current !== requestId) return;
        setResults(sonuc);
        setSearching(false);
      });
    }, 300);
  }

  function handleConfirmExisting() {
    if (!selectedChain) return;
    setSubmitting(true);
    setError(null);
    isletmeleriZincireBagla(selectedChain.id, businessIds).then((res) => {
      setSubmitting(false);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      onDone();
    });
  }

  function handleConfirmNew() {
    if (!newChainName.trim()) return;
    setSubmitting(true);
    setError(null);
    yeniZincirKurVeBagla(newChainName, businessIds).then((res) => {
      setSubmitting(false);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      onDone();
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        className="flex max-h-[85vh] w-full max-w-md flex-col gap-4 overflow-y-auto rounded-2xl border border-border bg-card p-5 shadow-yd2"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between">
          <h2 className="text-base font-black text-textStrong">Zincire Bağla</h2>
          <button type="button" onClick={onClose} className="text-xs font-bold text-muted hover:underline">
            Kapat
          </button>
        </div>

        <p className="text-xs font-bold text-muted">
          {businesses.length} işletme: {businesses.map((b) => b.name).join(', ')}
        </p>

        <div className="flex gap-1 rounded-xl border border-border bg-bg p-1">
          <button
            type="button"
            onClick={() => setSekme('mevcut')}
            className={`flex-1 rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
              sekme === 'mevcut' ? 'bg-card text-textStrong shadow-yd' : 'text-muted'
            }`}
          >
            Var olan zincire ekle
          </button>
          <button
            type="button"
            onClick={() => setSekme('yeni')}
            className={`flex-1 rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
              sekme === 'yeni' ? 'bg-card text-textStrong shadow-yd' : 'text-muted'
            }`}
          >
            Yeni zincir kur
          </button>
        </div>

        {sekme === 'mevcut' ? (
          <div className="flex flex-col gap-2">
            {!selectedChain ? (
              <>
                <input
                  value={query}
                  onChange={(e) => handleSearch(e.target.value)}
                  placeholder="Zincir adı ara..."
                  className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                {searching && <p className="text-xs font-bold text-muted">Aranıyor...</p>}
                {results.length > 0 && (
                  <div className="flex flex-col gap-1 rounded-xl border border-border bg-bg p-1">
                    {results.map((c) => (
                      <button
                        key={c.id}
                        type="button"
                        onClick={() => setSelectedChain(c)}
                        className="flex items-center justify-between rounded-lg px-3 py-2 text-left text-sm hover:bg-black/4"
                      >
                        <span className="font-bold text-textStrong">{c.name}</span>
                        <span className="text-xs text-muted">{c.category || '—'}</span>
                      </button>
                    ))}
                  </div>
                )}
                {!searching && query.trim() && results.length === 0 && (
                  <p className="text-xs font-bold text-muted">Sonuç bulunamadı.</p>
                )}
              </>
            ) : (
              <div className="flex flex-col gap-3 rounded-xl border border-border bg-bg p-3">
                <div className="flex items-center justify-between gap-2">
                  <p className="text-sm font-black text-textStrong">{selectedChain.name}</p>
                  <button
                    type="button"
                    onClick={() => setSelectedChain(null)}
                    disabled={submitting}
                    className="shrink-0 text-xs font-bold text-muted hover:underline disabled:opacity-50"
                  >
                    Değiştir
                  </button>
                </div>
                <PanelActionButton variant="primary" loading={submitting} onClick={handleConfirmExisting}>
                  Bağla
                </PanelActionButton>
              </div>
            )}
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            <input
              value={newChainName}
              onChange={(e) => setNewChainName(e.target.value)}
              placeholder="Zincir adı (ör. Sofra Kebap)"
              className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
            <PanelActionButton
              variant="primary"
              loading={submitting}
              onClick={handleConfirmNew}
              disabled={!newChainName.trim()}
            >
              Kur ve Bağla
            </PanelActionButton>
          </div>
        )}

        {error && <p className="text-xs font-bold text-(--yd-color-danger)">{error}</p>}
      </div>
    </div>
  );
}
