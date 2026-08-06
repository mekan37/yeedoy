'use client';

import { useState, useTransition } from 'react';
import { destekTalebiOlustur } from '../destek-islemleri';
import { CATEGORY_OPTIONS } from '../destek-yardimcilari';

export function YeniTalepFormu({
  businesses,
  onSuccess,
  onCancel,
}: {
  businesses: Array<{ id: string; name: string }>;
  onSuccess: (ticketId: string) => void;
  onCancel: () => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    const businessId = String(fd.get('businessId') ?? '') || null;
    const category = String(fd.get('category') ?? '');
    const subject = String(fd.get('subject') ?? '');
    const message = String(fd.get('message') ?? '');
    setError(null);
    startTransition(async () => {
      const result = await destekTalebiOlustur(businessId, category, subject, message);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      onSuccess(result.ticketId);
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-md rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Yeni Destek Talebi</h2>
        <form className="flex flex-col gap-3" onSubmit={handleSubmit}>
          {businesses.length > 1 && (
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">İşletme</label>
              <select name="businessId" className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong">
                <option value="">Genel (işletmeye özel değil)</option>
                {businesses.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </div>
          )}
          {businesses.length === 1 && <input type="hidden" name="businessId" value={businesses[0].id} />}

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Kategori</label>
            <select
              name="category"
              required
              defaultValue={CATEGORY_OPTIONS[0]}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            >
              {CATEGORY_OPTIONS.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Konu</label>
            <input
              name="subject"
              required
              maxLength={160}
              placeholder="Kısa bir başlık"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Mesaj</label>
            <textarea
              name="message"
              required
              maxLength={4000}
              rows={4}
              placeholder="Sorununuzu detaylı anlatın"
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
              {isPending ? 'Gönderiliyor...' : 'Talebi Gönder'}
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
      </div>
    </div>
  );
}
