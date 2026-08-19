'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import {
  anahtarDurum, DURUM_ETIKETLERI, DURUM_RENKLERI, scopeEtiket, scopeRenk, goreliZaman,
  type ApiKey,
} from './api-anahtarlari-yardimcilari';

async function revoke(id: string) {
  return fetch('/sunucu/yonetici/api-anahtarlari', {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id }),
  });
}

export function AnahtarTablosu({ keys }: { keys: ApiKey[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkSending, setBulkSending] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const revocableIds = keys.filter((k) => k.is_active).map((k) => k.id);

  const toggle = (id: string) =>
    setSelected((prev) => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });
  const toggleAll = () =>
    setSelected((prev) => (prev.size === revocableIds.length ? new Set() : new Set(revocableIds)));

  const bulkRevoke = async () => {
    if (selected.size === 0) return;
    if (!confirm(`${selected.size} API anahtarı iptal edilecek. Devam et?`)) return;
    setBulkSending(true);
    try {
      await Promise.all([...selected].map((id) => revoke(id)));
      setSelected(new Set());
      router.refresh();
    } finally {
      setBulkSending(false);
    }
  };

  const handleRevoke = (id: string) => {
    if (!confirm('Bu API anahtarı iptal edilecek. Devam et?')) return;
    startTransition(async () => {
      await revoke(id);
      router.refresh();
    });
  };

  const kopyala = (k: ApiKey) => {
    navigator.clipboard.writeText(k.prefix);
    setCopiedId(k.id);
    setTimeout(() => setCopiedId((c) => (c === k.id ? null : c)), 1500);
  };

  return (
    <div className="flex flex-col gap-3">
      {selected.size > 0 && (
        <div className="flex flex-wrap items-center gap-2 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3">
          <span className="text-xs font-extrabold text-textStrong">{selected.size} anahtar seçili</span>
          <button type="button" disabled={bulkSending} onClick={bulkRevoke} className="rounded-lg border border-danger/30 px-3 py-1.5 text-xs font-extrabold text-danger disabled:opacity-50 hover:bg-danger/6">
            {bulkSending ? 'İptal ediliyor…' : 'Toplu İptal Et'}
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
                  <input type="checkbox" checked={selected.size === revocableIds.length && revocableIds.length > 0} onChange={toggleAll} className="h-4 w-4 rounded border-border" aria-label="Tümünü seç" />
                </th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Anahtar Adı</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Anahtar</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kapsam</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Son Kullanım</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Oluşturulma</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlem</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {keys.map((k) => {
                const durum = anahtarDurum(k);
                return (
                  <tr key={k.id} className="hover:bg-black/2">
                    <td className="px-4 py-3">
                      {k.is_active && (
                        <input type="checkbox" checked={selected.has(k.id)} onChange={() => toggle(k.id)} className="h-4 w-4 rounded border-border" aria-label="Anahtar seç" />
                      )}
                    </td>
                    <td className="px-3 py-3">
                      <p className="font-extrabold text-textStrong">{k.name}</p>
                      {k.created_by_name && <p className="text-[11px] text-muted">{k.created_by_name}</p>}
                    </td>
                    <td className="px-3 py-3">
                      <div className="flex items-center gap-1.5">
                        <code className="rounded bg-cardAlt px-2 py-0.5 text-[11px] font-bold text-muted">{k.prefix}•••••</code>
                        <button
                          type="button"
                          onClick={() => kopyala(k)}
                          title="Anahtar öneki panoya kopyalanır — tam anahtar yalnızca oluşturulduğunda bir kez gösterilir"
                          className="rounded-lg border border-border px-2 py-1 text-[10px] font-bold text-muted hover:border-primary/30 hover:text-primary"
                        >
                          {copiedId === k.id ? 'Kopyalandı' : 'Kopyala'}
                        </button>
                      </div>
                    </td>
                    <td className="px-3 py-3">
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${scopeRenk(k.scope)}`}>{scopeEtiket(k.scope)}</span>
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">{goreliZaman(k.last_used_at)}</td>
                    <td className="px-3 py-3">
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${DURUM_RENKLERI[durum]}`}>{DURUM_ETIKETLERI[durum]}</span>
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">{new Date(k.created_at).toLocaleDateString('tr-TR')}</td>
                    <td className="px-3 py-3">
                      {k.is_active ? (
                        <button
                          type="button"
                          disabled={isPending}
                          onClick={() => handleRevoke(k.id)}
                          className="rounded-lg border border-danger/30 px-3 py-1.5 text-xs font-bold text-danger transition-colors hover:bg-danger/6 disabled:opacity-50"
                        >
                          İptal Et
                        </button>
                      ) : (
                        <span className="text-xs text-muted">—</span>
                      )}
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
