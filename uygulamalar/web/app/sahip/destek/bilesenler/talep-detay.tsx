'use client';

import { useState, useTransition } from 'react';
import type { DestekTicket, DestekMesaj } from '../destek-islemleri';
import { destekMesajGonder } from '../destek-islemleri';
import { STATUS_MAP } from '../destek-yardimcilari';

export function TalepDetay({
  ticket,
  messages,
  onBack,
  onMessageSent,
}: {
  ticket: DestekTicket;
  messages: DestekMesaj[];
  onBack: () => void;
  onMessageSent: (message: DestekMesaj) => void;
}) {
  const [reply, setReply] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleSend() {
    const trimmed = reply.trim();
    if (!trimmed) return;
    setError(null);
    startTransition(async () => {
      const result = await destekMesajGonder(ticket.id, trimmed);
      if (result?.error) {
        setError(result.error);
        return;
      }
      onMessageSent({
        id: `temp-${Date.now()}`,
        sender: 'user',
        message: trimmed,
        created_at: new Date().toISOString(),
      });
      setReply('');
    });
  }

  return (
    <div className="rounded-2xl border border-border bg-card">
      <div className="flex items-center gap-3 border-b border-border p-4">
        <button type="button" onClick={onBack} className="text-muted hover:text-textStrong cursor-pointer" aria-label="Geri">
          ←
        </button>
        <div className="min-w-0 flex-1">
          <p className="truncate font-bold text-textStrong">{ticket.subject}</p>
          <p className="text-xs text-muted">{ticket.category}</p>
        </div>
        <span className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-extrabold ${STATUS_MAP[ticket.status]?.color ?? ''}`}>
          {STATUS_MAP[ticket.status]?.label ?? ticket.status}
        </span>
      </div>

      <div className="flex flex-col gap-3 p-4">
        {messages.length === 0 ? (
          <p className="text-xs text-muted">Henüz mesaj yok.</p>
        ) : (
          messages.map((msg) => (
            <div key={msg.id} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div
                className={`max-w-[75%] rounded-2xl px-3 py-2 text-sm ${
                  msg.sender === 'user' ? 'bg-primary text-white' : 'bg-bg text-textStrong'
                }`}
              >
                <p>{msg.message}</p>
                <p className={`mt-1 text-[10px] ${msg.sender === 'user' ? 'text-white/70' : 'text-muted'}`}>
                  {new Date(msg.created_at).toLocaleString('tr-TR')}
                </p>
              </div>
            </div>
          ))
        )}
      </div>

      {error && <p className="px-4 text-xs font-bold text-red-600">{error}</p>}

      <div className="flex gap-2 border-t border-border p-4">
        <textarea
          value={reply}
          onChange={(e) => setReply(e.target.value)}
          placeholder="Yanıtınızı yazın..."
          rows={2}
          className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
        <button
          type="button"
          onClick={handleSend}
          disabled={isPending || !reply.trim()}
          className="rounded-xl bg-primary px-4 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
        >
          {isPending ? 'Gönderiliyor...' : 'Gönder'}
        </button>
      </div>
    </div>
  );
}
