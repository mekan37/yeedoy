'use client';

import { useState, useTransition } from 'react';
import type { CokluSubeBranch } from '../coklu-sube-yardimcilari';
import { saatleriTopluUygula, type DayKey, type HoursTemplate } from '../coklu-sube-toplu-saat';

const DAYS: Array<{ key: DayKey; label: string }> = [
  { key: 'mon', label: 'Pazartesi' },
  { key: 'tue', label: 'Salı' },
  { key: 'wed', label: 'Çarşamba' },
  { key: 'thu', label: 'Perşembe' },
  { key: 'fri', label: 'Cuma' },
  { key: 'sat', label: 'Cumartesi' },
  { key: 'sun', label: 'Pazar' },
];

export function TopluSaatFormu({
  branches,
  onDone,
  onCancel,
}: {
  branches: CokluSubeBranch[];
  onDone: (successCount: number, failedCount: number) => void;
  onCancel: () => void;
}) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [openTime, setOpenTime] = useState('09:00');
  const [closeTime, setCloseTime] = useState('22:00');
  const [applyDays, setApplyDays] = useState<Set<DayKey>>(new Set(DAYS.map((d) => d.key)));
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

  function toggleDay(day: DayKey) {
    setApplyDays((prev) => {
      const next = new Set(prev);
      if (next.has(day)) next.delete(day);
      else next.add(day);
      return next;
    });
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (selectedIds.size === 0) {
      setError('En az bir şube seçin');
      return;
    }
    setError(null);
    const template: HoursTemplate = {};
    for (const day of applyDays) {
      template[day] = { open: openTime, close: closeTime };
    }
    startTransition(async () => {
      const result = await saatleriTopluUygula([...selectedIds], template);
      onDone(result.successCount, result.failedBusinessIds.length);
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-lg rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Çalışma Saatlerini Yönet</h2>
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

          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">Açılış</label>
              <input
                type="time"
                value={openTime}
                onChange={(e) => setOpenTime(e.target.value)}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">Kapanış</label>
              <input
                type="time"
                value={closeTime}
                onChange={(e) => setCloseTime(e.target.value)}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
              />
            </div>
          </div>

          <div>
            <p className="mb-2 text-xs font-bold text-muted">Hangi günlere uygulanacak</p>
            <div className="flex flex-wrap gap-2">
              {DAYS.map((d) => (
                <button
                  key={d.key}
                  type="button"
                  onClick={() => toggleDay(d.key)}
                  className={`rounded-lg px-2.5 py-1 text-xs font-bold cursor-pointer ${
                    applyDays.has(d.key) ? 'bg-primary text-white' : 'border border-border text-muted'
                  }`}
                >
                  {d.label}
                </button>
              ))}
            </div>
          </div>

          {error && <p className="text-xs font-bold text-red-600">{error}</p>}

          <div className="flex gap-2 pt-2">
            <button
              type="submit"
              disabled={isPending}
              className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
            >
              {isPending ? 'Uygulanıyor...' : `${selectedIds.size} Şubeye Uygula`}
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
