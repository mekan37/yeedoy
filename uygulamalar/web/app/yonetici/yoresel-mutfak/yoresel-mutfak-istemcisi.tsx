'use client';

import { useState, useTransition } from 'react';
import { TURKIYE_ILLERI } from '@/src/lib/turkiye-illeri';
import { etiketKaydet, etiketSil, isletmeAra, isletmeyeEtiketAta, type IsletmeAramaSonucu } from './yoresel-mutfak-islemleri';

export type YoreselEtiket = { id: string; city: string; label: string; business_count: number; created_at: string };

export function YoreselMutfakIstemcisi({ initialEtiketler }: { initialEtiketler: YoreselEtiket[] }) {
  const [etiketler, setEtiketler] = useState(initialEtiketler);
  const [city, setCity] = useState<string>(TURKIYE_ILLERI[0]);
  const [label, setLabel] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const [query, setQuery] = useState('');
  const [results, setResults] = useState<IsletmeAramaSonucu[]>([]);
  const [selectedBusiness, setSelectedBusiness] = useState<IsletmeAramaSonucu | null>(null);

  function handleAddTag() {
    setError(null);
    startTransition(async () => {
      const res = await etiketKaydet(null, city, label);
      if (!res.ok) { setError(res.error); return; }
      setEtiketler((prev) => [...prev, { id: res.id, city, label, business_count: 0, created_at: new Date().toISOString() }].sort((a, b) => a.city.localeCompare(b.city, 'tr')));
      setLabel('');
    });
  }

  function handleDeleteTag(id: string) {
    startTransition(async () => {
      const res = await etiketSil(id);
      if (res.ok) setEtiketler((prev) => prev.filter((t) => t.id !== id));
    });
  }

  function handleSearch(q: string) {
    setQuery(q);
    startTransition(async () => {
      setResults(q.trim() ? await isletmeAra(q) : []);
    });
  }

  function handleAssign(tagId: string) {
    if (!selectedBusiness) return;
    startTransition(async () => {
      const res = await isletmeyeEtiketAta(selectedBusiness.id, tagId);
      if (res.ok) {
        setSelectedBusiness(null);
        setQuery('');
        setResults([]);
      }
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="rounded-xl border border-border bg-card p-4">
        <p className="mb-3 text-sm font-extrabold text-textStrong">Yeni Etiket Ekle</p>
        <div className="flex flex-wrap gap-2">
          <select value={city} onChange={(e) => setCity(e.target.value)} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong">
            {TURKIYE_ILLERI.map((il) => <option key={il} value={il}>{il}</option>)}
          </select>
          <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Etiket adı (ör. Kayseri Mantısı)" className="min-h-11 flex-1 min-w-[200px] rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
          <button type="button" onClick={handleAddTag} disabled={isPending || !label.trim()} className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white disabled:opacity-50">Ekle</button>
        </div>
        {error && <p className="mt-2 text-xs font-bold text-danger">{error}</p>}
      </div>

      <div className="rounded-xl border border-border bg-card">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-xs font-bold uppercase text-muted">
              <th className="px-4 py-2.5">Şehir</th>
              <th className="px-4 py-2.5">Etiket</th>
              <th className="px-4 py-2.5">İşletme Sayısı</th>
              <th className="px-4 py-2.5"></th>
            </tr>
          </thead>
          <tbody>
            {etiketler.map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2.5 font-bold text-textStrong">{t.city}</td>
                <td className="px-4 py-2.5">{t.label}</td>
                <td className="px-4 py-2.5 text-muted">{t.business_count}</td>
                <td className="px-4 py-2.5 text-right">
                  <button type="button" onClick={() => handleDeleteTag(t.id)} disabled={isPending} className="text-xs font-bold text-danger hover:underline">Sil</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="rounded-xl border border-border bg-card p-4">
        <p className="mb-3 text-sm font-extrabold text-textStrong">İşletmeye Etiket Ata</p>
        <input value={query} onChange={(e) => handleSearch(e.target.value)} placeholder="İşletme adı ara..." className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
        {results.length > 0 && !selectedBusiness && (
          <div className="mt-2 flex flex-col gap-1">
            {results.map((b) => (
              <button key={b.id} type="button" onClick={() => setSelectedBusiness(b)} className="flex items-center justify-between rounded-lg px-3 py-2 text-left text-sm hover:bg-black/4">
                <span className="font-bold text-textStrong">{b.name} <span className="font-normal text-muted">({b.city})</span></span>
                <span className="text-xs text-muted">{b.current_tag_label ?? 'Etiketsiz'}</span>
              </button>
            ))}
          </div>
        )}
        {selectedBusiness && (
          <div className="mt-3 rounded-lg border border-border p-3">
            <p className="mb-2 text-sm font-bold text-textStrong">{selectedBusiness.name} ({selectedBusiness.city}) için etiket seç:</p>
            <div className="flex flex-wrap gap-2">
              {etiketler.filter((t) => t.city === selectedBusiness.city).map((t) => (
                <button key={t.id} type="button" onClick={() => handleAssign(t.id)} disabled={isPending} className="rounded-full border border-border px-3 py-1.5 text-xs font-bold hover:border-primary/40 hover:text-primary">{t.label}</button>
              ))}
              {etiketler.filter((t) => t.city === selectedBusiness.city).length === 0 && (
                <p className="text-xs text-muted">Bu şehir için henüz etiket yok — önce yukarıdan ekleyin.</p>
              )}
            </div>
            <button type="button" onClick={() => setSelectedBusiness(null)} className="mt-2 text-xs font-bold text-muted hover:underline">Vazgeç</button>
          </div>
        )}
      </div>
    </div>
  );
}
