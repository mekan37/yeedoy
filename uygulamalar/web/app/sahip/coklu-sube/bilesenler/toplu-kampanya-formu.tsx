'use client';

import { useState, useTransition } from 'react';
import type { CokluSubeBranch } from '../coklu-sube-yardimcilari';
import { kampanyaTopluOlustur, type KampanyaSablonu } from '../coklu-sube-toplu-kampanya';

export function TopluKampanyaFormu({
  branches,
  onDone,
  onCancel,
}: {
  branches: CokluSubeBranch[];
  onDone: (successCount: number, failedCount: number) => void;
  onCancel: () => void;
}) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function toggleBusiness(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (selectedIds.size === 0) {
      setError('En az bir şube seçin');
      return;
    }
    const fd = new FormData(e.currentTarget);
    const title = String(fd.get('title') ?? '').trim();
    if (!title) {
      setError('Kampanya başlığı boş olamaz');
      return;
    }
    setError(null);
    const template: KampanyaSablonu = {
      title,
      type: fd.get('type') as KampanyaSablonu['type'],
      status: 'draft',
      description: String(fd.get('description') ?? '') || undefined,
      discountPercent: fd.get('discount_percent') ? Number(fd.get('discount_percent')) : undefined,
    };
    startTransition(async () => {
      const result = await kampanyaTopluOlustur([...selectedIds], template);
      onDone(result.successCount, result.failedBusinessIds.length);
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-lg rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Kampanya Ata</h2>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <p className="mb-2 text-xs font-bold text-muted">Şubeler</p>
            <div className="flex max-h-40 flex-col gap-1 overflow-y-auto rounded-xl border border-border p-2">
              {branches.map((b) => (
                <label key={b.business_id} className="flex items-center gap-2 text-sm text-textStrong cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selectedIds.has(b.business_id)}
                    onChange={() => toggleBusiness(b.business_id)}
                    className="rounded"
                  />
                  {b.name}
                </label>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Başlık</label>
            <input
              name="title"
              required
              maxLength={120}
              placeholder="örn. Hafta Sonu %20 İndirim"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Tür</label>
            <select
              name="type"
              defaultValue="discount"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            >
              <option value="discount">İndirim</option>
              <option value="special_offer">Özel Teklif</option>
              <option value="loyalty">Sadakat</option>
              <option value="announcement">Duyuru</option>
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">İndirim Yüzdesi (opsiyonel)</label>
            <input
              name="discount_percent"
              type="number"
              min={1}
              max={100}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Açıklama (opsiyonel)</label>
            <textarea
              name="description"
              maxLength={500}
              rows={2}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            />
          </div>

          {error && <p className="text-xs font-bold text-red-600">{error}</p>}

          <div className="flex gap-2 pt-2">
            <button
              type="submit"
              disabled={isPending}
              className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
            >
              {isPending ? 'Oluşturuluyor...' : `${selectedIds.size} Şubeye Ata`}
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
