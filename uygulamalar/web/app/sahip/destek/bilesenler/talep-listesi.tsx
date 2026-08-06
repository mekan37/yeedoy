'use client';

import { useState } from 'react';
import type { DestekTicket } from '../destek-islemleri';
import { STATUS_MAP, ticketMatchesTab, formatTicketNo, type TicketTab } from '../destek-yardimcilari';

export function TalepListesi({
  tickets,
  onSelect,
  onYeniTalep,
}: {
  tickets: DestekTicket[];
  onSelect: (ticketId: string) => void;
  onYeniTalep: () => void;
}) {
  const [tab, setTab] = useState<TicketTab>('tumu');
  const visible = tickets.filter((t) => ticketMatchesTab(t.status, tab));

  const tabs: Array<{ id: TicketTab; label: string }> = [
    { id: 'tumu', label: `Tümü (${tickets.length})` },
    { id: 'acik', label: `Açık (${tickets.filter((t) => ticketMatchesTab(t.status, 'acik')).length})` },
    { id: 'beklemede', label: `Beklemede (${tickets.filter((t) => ticketMatchesTab(t.status, 'beklemede')).length})` },
    { id: 'cozuldu', label: `Çözüldü (${tickets.filter((t) => ticketMatchesTab(t.status, 'cozuldu')).length})` },
  ];

  return (
    <div className="rounded-2xl border border-border bg-card">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border p-4">
        <div className="flex flex-wrap gap-1">
          {tabs.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold cursor-pointer ${
                tab === t.id ? 'bg-primary text-white' : 'text-muted hover:bg-bg'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
        <button
          type="button"
          onClick={onYeniTalep}
          className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white cursor-pointer"
        >
          + Yeni Talep Oluştur
        </button>
      </div>

      {visible.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-12 text-center">
          <p className="text-sm font-bold text-textStrong">Bu sekmede talep yok</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[560px] text-sm">
            <thead>
              <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
                <th className="px-4 py-2">Talep No</th>
                <th className="px-4 py-2">Konu</th>
                <th className="px-4 py-2">Durum</th>
                <th className="px-4 py-2">Son Güncelleme</th>
              </tr>
            </thead>
            <tbody>
              {visible.map((ticket) => (
                <tr
                  key={ticket.id}
                  onClick={() => onSelect(ticket.id)}
                  className="cursor-pointer border-b border-border last:border-0 hover:bg-bg/60"
                >
                  <td className="px-4 py-3 font-mono text-xs text-muted">{formatTicketNo(ticket.id)}</td>
                  <td className="px-4 py-3 font-bold text-textStrong">{ticket.subject}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${STATUS_MAP[ticket.status]?.color ?? ''}`}
                    >
                      {STATUS_MAP[ticket.status]?.label ?? ticket.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-muted">
                    {new Date(ticket.updated_at).toLocaleDateString('tr-TR', {
                      day: '2-digit',
                      month: 'short',
                      year: 'numeric',
                    })}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
