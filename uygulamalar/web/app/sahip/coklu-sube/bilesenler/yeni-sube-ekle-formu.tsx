'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { eklenebilirIsletmeleriListele, subeEkle, type AddableBusiness } from '../coklu-sube-islemleri';

export function YeniSubeEkleFormu({
  chainId,
  onSuccess,
  onCancel,
}: {
  chainId: string;
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [businesses, setBusinesses] = useState<AddableBusiness[] | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState('');
  const [branchLabel, setBranchLabel] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    let cancelled = false;
    void eklenebilirIsletmeleriListele().then((result) => {
      if (cancelled) return;
      if ('error' in result) {
        setLoadError(result.error);
        return;
      }
      setBusinesses(result.businesses);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!selectedId) {
      setError('Bir işletme seçin');
      return;
    }
    setError(null);
    startTransition(async () => {
      const result = await subeEkle(chainId, selectedId, branchLabel);
      if (result?.error) {
        setError(result.error);
        return;
      }
      onSuccess();
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-md rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Yeni Şube Ekle</h2>

        {businesses === null && !loadError && <p className="text-sm text-muted">Yükleniyor...</p>}
        {loadError && <p className="text-sm font-bold text-red-600">{loadError}</p>}

        {businesses !== null && businesses.length === 0 && (
          <div className="flex flex-col gap-3">
            <p className="text-sm text-muted">
              Zincire eklenebilecek, henüz başka bir zincire bağlı olmayan onaylı bir işletmeniz yok.
            </p>
            <Link
              href="/sahip/isletmeler/yeni"
              className="rounded-xl bg-primary px-3 py-2 text-center text-sm font-bold text-white"
            >
              Yeni İşletme Başvurusu Yap
            </Link>
            <button
              type="button"
              onClick={onCancel}
              className="rounded-xl border border-border px-3 py-2 text-sm font-bold text-textStrong cursor-pointer"
            >
              Kapat
            </button>
          </div>
        )}

        {businesses !== null && businesses.length > 0 && (
          <form onSubmit={handleSubmit} className="flex flex-col gap-3">
            <div className="flex flex-col gap-1">
              <label htmlFor="yeni-sube-isletme" className="text-xs font-bold text-muted">İşletme</label>
              <select
                id="yeni-sube-isletme"
                value={selectedId}
                onChange={(e) => setSelectedId(e.target.value)}
                required
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
              >
                <option value="">Bir işletme seçin</option>
                {businesses.map((b) => (
                  <option key={b.business_id} value={b.business_id}>
                    {b.name} {b.city ? `(${b.city})` : ''}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex flex-col gap-1">
              <label htmlFor="yeni-sube-etiket" className="text-xs font-bold text-muted">Şube Etiketi (opsiyonel)</label>
              <input
                id="yeni-sube-etiket"
                value={branchLabel}
                onChange={(e) => setBranchLabel(e.target.value)}
                placeholder="örn. Kadıköy Şubesi"
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted"
              />
            </div>

            {error && <p className="text-xs font-bold text-red-600">{error}</p>}

            <div className="flex gap-2 pt-2">
              <button
                type="submit"
                disabled={isPending}
                className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
              >
                {isPending ? 'Ekleniyor...' : 'Şubeyi Ekle'}
              </button>
              <button
                type="button"
                onClick={onCancel}
                className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer"
              >
                İptal
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
