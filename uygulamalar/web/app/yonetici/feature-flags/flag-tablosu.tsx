'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import {
  flagDurum, DURUM_ETIKETLERI, DURUM_RENKLERI, TUR_SECENEKLERI, ORTAM_ETIKETLERI, hedefKitleEtiket,
  type FeatureFlag,
} from './flag-yardimcilari';

async function apiPatch(key: string, body: { enabled?: boolean; rollout_percent?: number }) {
  return fetch('/sunucu/yonetici/feature-flags', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id: key, ...body }),
  });
}

export function FlagTablosu({ flags }: { flags: FeatureFlag[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkRollout, setBulkRollout] = useState(100);
  const [bulkSending, setBulkSending] = useState(false);
  const [localEnabled, setLocalEnabled] = useState<Record<string, boolean>>({});

  const toggle = (key: string) =>
    setSelected((prev) => { const s = new Set(prev); s.has(key) ? s.delete(key) : s.add(key); return s; });
  const toggleAll = () =>
    setSelected((prev) => (prev.size === flags.length ? new Set() : new Set(flags.map((f) => f.key))));

  const bulkUpdateRollout = async () => {
    if (selected.size === 0) return;
    setBulkSending(true);
    try {
      await Promise.all([...selected].map((key) => apiPatch(key, { rollout_percent: bulkRollout })));
      setSelected(new Set());
      router.refresh();
    } finally {
      setBulkSending(false);
    }
  };

  const handleFlagToggle = (key: string, current: boolean) => {
    const next = !current;
    setLocalEnabled((prev) => ({ ...prev, [key]: next }));
    startTransition(async () => {
      const res = await apiPatch(key, { enabled: next });
      const json = await res.json().catch(() => ({ ok: false }));
      if (!json.ok) setLocalEnabled((prev) => ({ ...prev, [key]: current }));
      router.refresh();
    });
  };

  return (
    <div className="flex flex-col gap-3">
      {selected.size > 0 && (
        <div className="flex flex-wrap items-center gap-2 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3">
          <span className="text-xs font-extrabold text-textStrong">{selected.size} flag seçili</span>
          <input
            type="range" min={0} max={100} step={5}
            value={bulkRollout}
            onChange={(e) => setBulkRollout(Number(e.target.value))}
            className="w-32"
          />
          <span className="w-10 text-xs font-bold text-textStrong">%{bulkRollout}</span>
          <button type="button" disabled={bulkSending} onClick={bulkUpdateRollout} className="rounded-lg bg-primary px-3 py-1.5 text-xs font-extrabold text-white disabled:opacity-50">
            {bulkSending ? 'Uygulanıyor…' : 'Toplu Rollout Güncelle'}
          </button>
          <button type="button" onClick={() => setSelected(new Set())} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-muted hover:text-textStrong">
            Seçimi Temizle
          </button>
        </div>
      )}

      <div className="overflow-hidden rounded-2xl border border-border bg-card">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-left">
                <th className="w-10 px-4 py-3">
                  <input type="checkbox" checked={selected.size === flags.length && flags.length > 0} onChange={toggleAll} className="h-4 w-4 rounded border-border" aria-label="Tümünü seç" />
                </th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Feature Flag</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Açıklama</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Proje / Ortam</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Hedef Kitle</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Rollout</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Son Güncelleme</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {flags.map((f) => {
                const durum = flagDurum(f);
                const enabled = localEnabled[f.key] ?? f.enabled;
                return (
                  <tr key={f.key} className="hover:bg-black/2">
                    <td className="px-4 py-3">
                      <input type="checkbox" checked={selected.has(f.key)} onChange={() => toggle(f.key)} className="h-4 w-4 rounded border-border" aria-label="Flag seç" />
                    </td>
                    <td className="px-3 py-3">
                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          disabled={isPending || durum === 'draft'}
                          onClick={() => handleFlagToggle(f.key, enabled)}
                          title={durum === 'draft' ? 'Taslak flagler doğrudan açılamaz' : enabled ? 'Pasife al' : 'Aktife al'}
                          className={`relative inline-flex h-5 w-9 shrink-0 items-center rounded-full transition-colors disabled:opacity-40 ${enabled ? 'bg-emerald-500' : 'bg-border'}`}
                        >
                          <span className={`inline-block h-3.5 w-3.5 translate-x-1 rounded-full bg-white shadow transition-transform ${enabled ? 'translate-x-5' : ''}`} />
                        </button>
                        <div className="min-w-0">
                          <code className="block truncate rounded bg-cardAlt px-1.5 py-0.5 text-xs font-bold text-primary">{f.key}</code>
                          {f.metadata?.type && <span className="text-[10px] text-muted">{TUR_SECENEKLERI[f.metadata.type] ?? f.metadata.type}</span>}
                        </div>
                      </div>
                    </td>
                    <td className="max-w-[200px] px-3 py-3 text-xs text-muted">{f.metadata?.description || '—'}</td>
                    <td className="px-3 py-3 text-xs">
                      <p className="font-bold text-textStrong">{f.metadata?.project || '—'}</p>
                      <p className="text-muted">{ORTAM_ETIKETLERI[f.metadata?.environment ?? ''] ?? f.metadata?.environment ?? '—'}</p>
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">{hedefKitleEtiket(f.allowed_regions)}</td>
                    <td className="px-3 py-3">
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${DURUM_RENKLERI[durum]}`}>{DURUM_ETIKETLERI[durum]}</span>
                    </td>
                    <td className="px-3 py-3">
                      <div className="flex items-center gap-2">
                        <span className="w-9 text-xs font-extrabold text-textStrong">%{f.rollout_percent}</span>
                        <div className="h-1.5 w-16 overflow-hidden rounded-full bg-black/8">
                          <div className="h-full rounded-full bg-emerald-500" style={{ width: `${f.rollout_percent}%` }} />
                        </div>
                      </div>
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">
                      <p>{new Date(f.updated_at).toLocaleDateString('tr-TR')}</p>
                      {f.updated_by_name && <p className="text-[10px]">{f.updated_by_name}</p>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
