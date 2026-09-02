'use client';

import { useRef, useState } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import {
  isletmeAraBirlestirmeIcin,
  isletmeBirlestir,
  isletmeBirlestirOnizle,
  type IsletmeAramaOzetiBirlestirme,
} from './isletme-duzenle-islemleri';

const OZET_ETIKETLERI: Record<string, string> = {
  menus: 'Menüler',
  menu_items: 'Menü Öğeleri',
  reviews: 'Yorumlar',
  media: 'Medya',
  stories: 'Hikayeler',
  favorites: 'Favoriler',
  follows: 'Takipler',
  meal_cards: 'Yemek Kartı Sağlayıcıları',
};

/**
 * "Düzenlemekte olunan işletme" (duplicateId) her zaman birleştirmede
 * arşivlenecek taraftır — admin burada arayıp seçtiği işletme "asıl/keeper"
 * (primary) olur ve tüm veriler ona taşınır. admin_merge_businesses_v1
 * RPC'si dry_run:true ile önce bir önizleme döndürür, gerçek birleştirme
 * yalnızca admin açık bir onay verdikten sonra dry_run:false ile çağrılır.
 */
export function IsletmeBirlestirBolumu({
  duplicateId,
  duplicateName,
  onMerged,
}: {
  duplicateId: string;
  duplicateName: string;
  onMerged: () => void;
}) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<IsletmeAramaOzetiBirlestirme[]>([]);
  const [searching, setSearching] = useState(false);
  const [selectedPrimary, setSelectedPrimary] = useState<IsletmeAramaOzetiBirlestirme | null>(null);
  const [summary, setSummary] = useState<Record<string, number> | null>(null);
  const [previewLoading, setPreviewLoading] = useState(false);
  const [note, setNote] = useState('');
  const [merging, setMerging] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const requestIdRef = useRef(0);

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
      isletmeAraBirlestirmeIcin(q).then((sonuc) => {
        if (requestIdRef.current !== requestId) return;
        setResults(sonuc.filter((b) => b.id !== duplicateId));
        setSearching(false);
      });
    }, 300);
  }

  function handleSelect(b: IsletmeAramaOzetiBirlestirme) {
    setSelectedPrimary(b);
    setResults([]);
    setQuery('');
    setSummary(null);
    setError(null);
    setPreviewLoading(true);
    isletmeBirlestirOnizle(b.id, duplicateId).then((res) => {
      setPreviewLoading(false);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      setSummary(res.summary);
    });
  }

  function handleReset() {
    setSelectedPrimary(null);
    setSummary(null);
    setError(null);
    setNote('');
  }

  function handleConfirm() {
    if (!selectedPrimary) return;
    const onay = window.confirm(
      `"${duplicateName}" işletmesi arşivlenecek ve tüm verileri (yorumlar, menüler, medya, favoriler vb.) "${selectedPrimary.name}" işletmesine taşınacak.\n\nBu işlem geri alınamaz. Devam edilsin mi?`,
    );
    if (!onay) return;

    setMerging(true);
    setError(null);
    isletmeBirlestir(selectedPrimary.id, duplicateId, note).then((res) => {
      setMerging(false);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      onMerged();
    });
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-xs font-bold text-amber-800">
        Bu işlem, düzenlemekte olduğunuz <span className="font-black">&quot;{duplicateName}&quot;</span> işletmesini seçeceğiniz başka bir
        işletmenin (asıl/keeper) içine birleştirir. Birleştirilen işletme arşivlenir (pasif hale gelir), verileri silinmez.
      </div>

      {!selectedPrimary ? (
        <div className="flex flex-col gap-2">
          <label className="text-xs font-bold uppercase tracking-wide text-muted">
            &quot;{duplicateName}&quot; hangi işletme ile birleştirilecek? (asıl/keeper işletmeyi arayın)
          </label>
          <input
            value={query}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder="İşletme adı ara..."
            className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
          {searching && <p className="text-xs font-bold text-muted">Aranıyor...</p>}
          {results.length > 0 && (
            <div className="flex flex-col gap-1 rounded-xl border border-border bg-card p-1">
              {results.map((b) => (
                <button
                  key={b.id}
                  type="button"
                  onClick={() => handleSelect(b)}
                  className="flex items-center justify-between rounded-lg px-3 py-2 text-left text-sm hover:bg-black/4"
                >
                  <span className="font-bold text-textStrong">{b.name}</span>
                  <span className="text-xs text-muted">{b.city || '—'}</span>
                </button>
              ))}
            </div>
          )}
          {!searching && query.trim() && results.length === 0 && (
            <p className="text-xs font-bold text-muted">Sonuç bulunamadı.</p>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-3 rounded-xl border border-border bg-bg p-3">
          <div className="flex items-center justify-between gap-2">
            <div className="min-w-0">
              <p className="text-[11px] font-bold uppercase tracking-wide text-muted">Asıl (Keeper) İşletme</p>
              <p className="truncate text-sm font-black text-textStrong">
                {selectedPrimary.name} <span className="font-normal text-muted">({selectedPrimary.city || '—'})</span>
              </p>
            </div>
            <button
              type="button"
              onClick={handleReset}
              disabled={merging}
              className="shrink-0 text-xs font-bold text-muted hover:underline disabled:opacity-50"
            >
              Değiştir
            </button>
          </div>

          {previewLoading && <p className="text-xs font-bold text-muted">Önizleme yükleniyor...</p>}

          {summary && (
            <>
              <div>
                <p className="mb-1.5 text-[11px] font-bold uppercase tracking-wide text-muted">
                  &quot;{duplicateName}&quot; işletmesinden taşınacak veriler
                </p>
                <div className="grid grid-cols-2 gap-1.5 sm:grid-cols-4">
                  {Object.entries(summary).map(([key, count]) => (
                    <div key={key} className="rounded-lg border border-border bg-card px-2 py-1.5 text-center">
                      <p className="text-base font-black text-textStrong">{count}</p>
                      <p className="text-[10px] font-bold text-muted">{OZET_ETIKETLERI[key] ?? key}</p>
                    </div>
                  ))}
                </div>
              </div>

              <div>
                <label className="mb-1 block text-xs font-bold uppercase tracking-wide text-muted">Admin Notu (opsiyonel)</label>
                <input
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="Neden birleştiriliyor?"
                  className="w-full rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
              </div>

              <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-bold text-(--yd-color-danger)">
                &quot;{duplicateName}&quot; işletmesi pasif/arşivlenmiş duruma geçecek ve tüm verileri geri alınamaz şekilde &quot;
                {selectedPrimary.name}&quot; işletmesine taşınacak.
              </div>

              <PanelActionButton variant="danger" loading={merging} onClick={handleConfirm}>
                Birleştirmeyi Onayla
              </PanelActionButton>
            </>
          )}
        </div>
      )}

      {error && <p className="text-xs font-bold text-(--yd-color-danger)">{error}</p>}
    </div>
  );
}
