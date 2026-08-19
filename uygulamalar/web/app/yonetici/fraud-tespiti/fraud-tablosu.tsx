'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { X } from 'lucide-react';
import { DURUM_ETIKETLERI, DURUM_RENKLERI, HEDEF_ETIKETLERI, type RaporDurumu, type HedefTuru } from '../raporlar/raporlar-yardimcilari';
import type { FraudRaporu } from './fraud-yardimcilari';

const STATUS_CYCLE: Record<RaporDurumu, RaporDurumu> = {
  open: 'reviewing',
  reviewing: 'closed',
  closed: 'open',
};

function durumEtiket(status: string): string {
  return DURUM_ETIKETLERI[status as RaporDurumu] ?? status;
}
function durumRenk(status: string): string {
  return DURUM_RENKLERI[status as RaporDurumu] ?? 'bg-zinc-100 text-zinc-500';
}
function hedefEtiket(t: string): string {
  return HEDEF_ETIKETLERI[t as HedefTuru] ?? t;
}
function incelemeHref(r: FraudRaporu): string {
  if (r.target_type === 'review') return `/yonetici/yorumlar?id=${r.target_id}`;
  if (r.target_type === 'business') return `/yonetici/isletmeler?id=${r.target_id}`;
  if (r.target_type === 'menu_item_photo') return `/yonetici/fotograf-moderasyon`;
  return '#';
}

async function apiPatch(reportId: string, status: string, adminNote?: string) {
  return fetch('/sunucu/yonetici/raporlar', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reportId, status, adminNote }),
  });
}

export function FraudTablosu({ reports }: { reports: FraudRaporu[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [openId, setOpenId] = useState<string | null>(null);
  const [bulkSending, setBulkSending] = useState(false);

  const toggleSelect = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };
  const toggleAll = () => setSelected((prev) => (prev.size === reports.length ? new Set() : new Set(reports.map((r) => r.id))));

  const bulkClose = async () => {
    if (selected.size === 0) return;
    setBulkSending(true);
    try {
      await Promise.all([...selected].map((id) => apiPatch(id, 'closed')));
      setSelected(new Set());
      router.refresh();
    } finally {
      setBulkSending(false);
    }
  };

  const openReport = reports.find((r) => r.id === openId) ?? null;

  return (
    <div className="flex flex-col gap-3">
      {selected.size > 0 && (
        <div className="flex flex-wrap items-center gap-2 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3">
          <span className="text-xs font-extrabold text-textStrong">{selected.size} rapor seçili</span>
          <button type="button" disabled={bulkSending} onClick={bulkClose} className="rounded-lg bg-primary px-3 py-1.5 text-xs font-extrabold text-white disabled:opacity-50">
            {bulkSending ? 'Uygulanıyor…' : 'Toplu Kapat'}
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
                  <input type="checkbox" checked={selected.size === reports.length && reports.length > 0} onChange={toggleAll} className="h-4 w-4 rounded border-border" aria-label="Tümünü seç" />
                </th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Rapor</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tür</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Neden</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
                <th className="px-3 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {reports.map((r) => (
                <tr key={r.id} className="hover:bg-black/2">
                  <td className="px-4 py-3">
                    <input type="checkbox" checked={selected.has(r.id)} onChange={() => toggleSelect(r.id)} className="h-4 w-4 rounded border-border" aria-label="rapor seç" />
                  </td>
                  <td className="px-3 py-3 font-mono text-[11px] text-muted">#{r.id.slice(0, 8)}</td>
                  <td className="px-3 py-3 text-xs font-bold text-textStrong">{hedefEtiket(r.target_type)}</td>
                  <td className="max-w-[240px] px-3 py-3">
                    <button onClick={() => setOpenId(r.id)} className="truncate text-left font-bold text-textStrong hover:text-primary hover:underline">
                      {r.reason || 'Sebep belirtilmedi'}
                    </button>
                  </td>
                  <td className="px-3 py-3">
                    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${durumRenk(r.status)}`}>{durumEtiket(r.status)}</span>
                  </td>
                  <td className="px-3 py-3 text-xs text-muted">{new Date(r.created_at).toLocaleDateString('tr-TR')}</td>
                  <td className="px-3 py-3 text-right">
                    <button onClick={() => setOpenId(r.id)} title="Detayı görüntüle" className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong">
                      <EyeIcon />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {openReport && (
        <RaporPaneli
          report={openReport}
          onClose={() => setOpenId(null)}
          onStatusChange={(status) => startTransition(async () => { await apiPatch(openReport.id, status); router.refresh(); })}
          isPending={isPending}
        />
      )}
    </div>
  );
}

function RaporPaneli({
  report, onClose, onStatusChange, isPending,
}: {
  report: FraudRaporu;
  onClose: () => void;
  onStatusChange: (status: string) => void;
  isPending: boolean;
}) {
  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/30" onClick={onClose} aria-hidden="true" />
      <div className="fixed inset-y-0 right-0 z-50 flex w-full max-w-md flex-col border-l border-border bg-white shadow-2xl">
        <div className="flex items-start justify-between gap-3 border-b border-border p-5">
          <div className="min-w-0">
            <p className="font-mono text-[11px] text-muted">#{report.id.slice(0, 8)}</p>
            <p className="font-black text-textStrong">{report.reason || 'Sebep belirtilmedi'}</p>
            <div className="mt-2 flex flex-wrap gap-1.5">
              <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${durumRenk(report.status)}`}>{durumEtiket(report.status)}</span>
              <span className="text-[10px] text-muted">{hedefEtiket(report.target_type)}</span>
            </div>
          </div>
          <button onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong" aria-label="Kapat">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-5">
          <div>
            <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Detay</p>
            <p className="mt-1 text-sm text-textStrong">{report.details || 'Ek detay girilmemiş.'}</p>
          </div>
          {report.admin_note && (
            <div>
              <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Yönetici Notu</p>
              <p className="mt-1 text-sm text-textStrong">{report.admin_note}</p>
            </div>
          )}
          <div>
            <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Oluşturulma</p>
            <p className="mt-1 text-sm text-textStrong">{new Date(report.created_at).toLocaleString('tr-TR')}</p>
          </div>
          <Link href={incelemeHref(report)} className="text-xs font-bold text-primary hover:underline">
            Hedefi görüntüle →
          </Link>
        </div>

        <div className="flex flex-wrap gap-2 border-t border-border p-5">
          <button
            disabled={isPending}
            onClick={() => onStatusChange(STATUS_CYCLE[report.status as RaporDurumu] ?? 'open')}
            className="rounded-lg bg-primary px-4 py-1.5 text-xs font-extrabold text-white hover:bg-primary/90 disabled:opacity-50"
          >
            {report.status === 'open' ? 'İncelemeye Al' : report.status === 'reviewing' ? 'Kapat' : 'Yeniden Aç'}
          </button>
        </div>
      </div>
    </>
  );
}

function EyeIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
    </svg>
  );
}
