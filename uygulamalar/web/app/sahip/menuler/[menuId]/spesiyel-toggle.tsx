'use client';

import { useState } from 'react';

interface SpesiyelToggleProps {
  menuItemId: string;
  itemName: string;
  isSpecial: boolean;
  specialNote: string | null;
}

export function SpesiyelToggle({ menuItemId, itemName, isSpecial: initial, specialNote: initialNote }: SpesiyelToggleProps) {
  const [isSpecial, setIsSpecial] = useState(initial);
  const [note, setNote] = useState(initialNote ?? '');
  const [showNoteInput, setShowNoteInput] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function toggle(newValue: boolean) {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/sunucu/sahip/spesiyel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          menuItemId,
          isSpecial: newValue,
          note: newValue ? note.trim() || undefined : undefined,
        }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? 'Hata');
      setIsSpecial(newValue);
      if (!newValue) { setNote(''); setShowNoteInput(false); }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  if (isSpecial) {
    return (
      <div className="flex items-center gap-2">
        <span className="inline-flex items-center gap-1 rounded-full border border-amber-300 bg-amber-50 px-2 py-0.5 text-[11px] font-[800] text-amber-700">
          ⭐ Bugünün Spesiyali
        </span>
        <button
          onClick={() => toggle(false)}
          disabled={loading}
          className="text-[11px] font-[700] text-muted underline-offset-2 hover:underline disabled:opacity-50"
        >
          {loading ? '…' : 'Kaldır'}
        </button>
        {error && <span className="text-[11px] text-danger">{error}</span>}
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-1">
      <div className="flex items-center gap-2">
        <button
          onClick={() => setShowNoteInput(!showNoteInput)}
          disabled={loading}
          className="text-[11px] font-[700] text-primary underline-offset-2 hover:underline disabled:opacity-50"
        >
          ⭐ Spesiyel İşaretle
        </button>
        {error && <span className="text-[11px] text-danger">{error}</span>}
      </div>
      {showNoteInput && (
        <div className="flex items-center gap-1.5">
          <input
            type="text"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder={`${itemName} için not (opsiyonel)`}
            maxLength={200}
            className="input-yd h-7 flex-1 rounded-lg px-2 text-xs"
          />
          <button
            onClick={() => toggle(true)}
            disabled={loading}
            className="btn-primary rounded-lg px-2.5 py-1 text-xs font-[800] text-white disabled:opacity-50"
          >
            {loading ? '…' : 'Onayla'}
          </button>
        </div>
      )}
    </div>
  );
}
