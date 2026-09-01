'use client';

import { useState, useTransition } from 'react';
import { terimAra, terimEkle, terimSil, type BlacklistTerim } from './kara-liste-islemleri';

export function KaraListeIstemcisi({ initialTerimler }: { initialTerimler: BlacklistTerim[] }) {
  const [terimler, setTerimler] = useState(initialTerimler);
  const [yeniTerim, setYeniTerim] = useState('');
  const [query, setQuery] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleAdd() {
    setError(null);
    startTransition(async () => {
      const res = await terimEkle(yeniTerim);
      if (!res.ok) { setError(res.error); return; }
      setYeniTerim('');
      const yenile = await terimAra(query);
      setTerimler(yenile);
    });
  }

  function handleDelete(t: BlacklistTerim) {
    if (!confirm(`"${t.term}" terimini kaldırmak istediğinize emin misiniz?`)) return;
    startTransition(async () => {
      const res = await terimSil(t.id);
      if (res.ok) setTerimler((prev) => prev.filter((x) => x.id !== t.id));
    });
  }

  function handleSearch(q: string) {
    setQuery(q);
    startTransition(async () => {
      const sonuc = await terimAra(q);
      setTerimler(sonuc);
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="rounded-xl border border-border bg-card p-4">
        <p className="mb-3 text-sm font-extrabold text-textStrong">Yeni Terim Ekle</p>
        <div className="flex flex-wrap gap-2">
          <input value={yeniTerim} onChange={(e) => setYeniTerim(e.target.value)} placeholder="Terim..." className="min-h-11 flex-1 min-w-[200px] rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
          <button type="button" onClick={handleAdd} disabled={isPending || !yeniTerim.trim()} className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white disabled:opacity-50">Ekle</button>
        </div>
        {error && <p className="mt-2 text-xs font-bold text-danger">{error}</p>}
      </div>

      <div className="rounded-xl border border-border bg-card p-4">
        <input value={query} onChange={(e) => handleSearch(e.target.value)} placeholder="Terim ara..." className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
      </div>

      <div className="rounded-xl border border-border bg-card">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-xs font-bold uppercase text-muted">
              <th className="px-4 py-2.5">Terim</th>
              <th className="px-4 py-2.5">Eklenme Tarihi</th>
              <th className="px-4 py-2.5"></th>
            </tr>
          </thead>
          <tbody>
            {terimler.map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2.5 font-bold text-textStrong">{t.term}</td>
                <td className="px-4 py-2.5 text-muted">{new Date(t.created_at).toLocaleDateString('tr-TR')}</td>
                <td className="px-4 py-2.5 text-right">
                  <button type="button" onClick={() => handleDelete(t)} disabled={isPending} className="text-xs font-bold text-danger hover:underline">Kaldır</button>
                </td>
              </tr>
            ))}
            {terimler.length === 0 && (
              <tr><td colSpan={3} className="px-4 py-6 text-center text-muted">Sonuç yok.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
