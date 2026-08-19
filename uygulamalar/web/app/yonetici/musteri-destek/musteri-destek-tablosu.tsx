'use client';

import { useState, useTransition, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Clock, X } from 'lucide-react';
import { STATUS_MAP, PRIORITY_MAP, slaBadge, type DestekTalebi } from './musteri-destek-yardimcilari';

interface TicketMessage {
  id: string;
  ticket_id: string;
  sender: 'user' | 'agent';
  message: string;
  created_at: string;
}

const STATUS_CYCLE: Record<string, string> = {
  open: 'in_progress',
  in_progress: 'resolved',
  resolved: 'closed',
  closed: 'open',
};

const RESPONSE_TEMPLATES: Record<string, string[]> = {
  default: [
    'Merhaba, talebinizi aldık. En kısa sürede dönüş yapacağız.',
    'Sorununuzu inceliyoruz. Anlayışınız için teşekkür ederiz.',
    'Bu konuda yardımcı olmaktan memnuniyet duyarız. Lütfen ek detay paylaşabilir misiniz?',
  ],
  technical: [
    'Teknik ekibimize bildirdik. 24 saat içinde çözüm sağlayacağız.',
    'Lütfen uygulamayı yeniden başlatıp tekrar deneyin. Sorun devam ederse bildiriniz.',
  ],
  billing: [
    'Ödeme konusundaki talebinizi finans ekibimize ilettik.',
    'Para iadesi talebiniz işleme alınmıştır. 3-5 iş günü içinde hesabınıza yansıyacaktır.',
  ],
  complaint: [
    'Şikayetiniz için üzgünüz. Bu deneyimi iyileştirmek için gerekli adımları atacağız.',
    'Yaşadığınız olumsuz deneyim için özür dileriz. Size özel çözüm sunmak için iletişime geçeceğiz.',
  ],
};

async function apiPatch(ticketId: string, status: string) {
  return fetch('/sunucu/yonetici/musteri-destek', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ticketId, status }),
  });
}

async function apiReply(ticketId: string, message: string) {
  return fetch('/sunucu/yonetici/musteri-destek', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ticketId, message, sender: 'agent' }),
  });
}

export function MusteriDestekTablosu({ tickets }: { tickets: DestekTalebi[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [openTicketId, setOpenTicketId] = useState<string | null>(null);
  const [bulkReply, setBulkReply] = useState('');
  const [bulkSending, setBulkSending] = useState(false);

  const toggleSelect = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  const toggleSelectAll = () => {
    setSelected((prev) => (prev.size === tickets.length ? new Set() : new Set(tickets.map((t) => t.id))));
  };

  const sendBulkReply = async () => {
    if (!bulkReply.trim() || selected.size === 0) return;
    setBulkSending(true);
    try {
      await Promise.all([...selected].map((id) => apiReply(id, bulkReply.trim())));
      setBulkReply('');
      setSelected(new Set());
      router.refresh();
    } finally {
      setBulkSending(false);
    }
  };

  const openTicket = tickets.find((t) => t.id === openTicketId) ?? null;

  return (
    <div className="flex flex-col gap-3">
      {selected.size > 0 && (
        <div className="flex flex-wrap items-center gap-2 rounded-xl border border-primary/30 bg-primary/5 px-4 py-3">
          <span className="text-xs font-extrabold text-textStrong">{selected.size} talep seçili</span>
          <input
            value={bulkReply}
            onChange={(e) => setBulkReply(e.target.value)}
            placeholder="Seçili taleplerin hepsine gönderilecek yanıt..."
            className="min-w-0 flex-1 rounded-lg border border-border bg-white px-3 py-1.5 text-xs focus:border-primary focus:outline-hidden"
          />
          <button
            type="button"
            disabled={bulkSending || !bulkReply.trim()}
            onClick={sendBulkReply}
            className="rounded-lg bg-primary px-3 py-1.5 text-xs font-extrabold text-white disabled:opacity-50"
          >
            {bulkSending ? 'Gönderiliyor…' : 'Toplu Yanıt Gönder'}
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
                  <input type="checkbox" checked={selected.size === tickets.length && tickets.length > 0} onChange={toggleSelectAll} className="h-4 w-4 rounded border-border" aria-label="Tümünü seç" />
                </th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Talep</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Konu</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kategori</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Öncelik</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                <th className="px-3 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Son Güncelleme</th>
                <th className="px-3 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {tickets.map((ticket) => {
                const sla = slaBadge(ticket.created_at);
                return (
                  <tr key={ticket.id} className="hover:bg-black/2">
                    <td className="px-4 py-3">
                      <input type="checkbox" checked={selected.has(ticket.id)} onChange={() => toggleSelect(ticket.id)} className="h-4 w-4 rounded border-border" aria-label={`${ticket.subject} seç`} />
                    </td>
                    <td className="px-3 py-3">
                      <span className="font-mono text-[11px] text-muted">#{ticket.id.slice(0, 8)}</span>
                      <span className={`ml-2 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold ${sla.color}`}>
                        <Clock className="h-3 w-3" aria-hidden="true" /> {sla.label}
                      </span>
                    </td>
                    <td className="max-w-[220px] px-3 py-3">
                      <button onClick={() => setOpenTicketId(ticket.id)} className="truncate text-left font-bold text-textStrong hover:text-primary hover:underline">
                        {ticket.subject}
                      </button>
                    </td>
                    <td className="px-3 py-3">
                      <p className="font-bold text-textStrong">{ticket.requester_name ?? 'Bilinmiyor'}</p>
                      <p className="text-xs text-muted">{ticket.requester_email ?? ''}</p>
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">{ticket.category}</td>
                    <td className="px-3 py-3">
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${PRIORITY_MAP[ticket.priority]?.color ?? 'bg-zinc-100 text-zinc-500'}`}>
                        {PRIORITY_MAP[ticket.priority]?.label ?? ticket.priority}
                      </span>
                    </td>
                    <td className="px-3 py-3">
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${STATUS_MAP[ticket.status]?.color ?? 'bg-zinc-100 text-zinc-500'}`}>
                        {STATUS_MAP[ticket.status]?.label ?? ticket.status}
                      </span>
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">{new Date(ticket.updated_at).toLocaleDateString('tr-TR')}</td>
                    <td className="px-3 py-3 text-right">
                      <button onClick={() => setOpenTicketId(ticket.id)} title="Detayı görüntüle" className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong">
                        <EyeIcon />
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {openTicket && (
        <TalepPaneli
          ticket={openTicket}
          onClose={() => setOpenTicketId(null)}
          onStatusChange={(status) => startTransition(async () => { await apiPatch(openTicket.id, status); router.refresh(); })}
          isPending={isPending}
        />
      )}
    </div>
  );
}

function TalepPaneli({
  ticket, onClose, onStatusChange, isPending,
}: {
  ticket: DestekTalebi;
  onClose: () => void;
  onStatusChange: (status: string) => void;
  isPending: boolean;
}) {
  const router = useRouter();
  const [messages, setMessages] = useState<TicketMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [reply, setReply] = useState('');
  const [sending, setSending] = useState(false);
  const [templateOpen, setTemplateOpen] = useState(false);
  const replyRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetch(`/sunucu/yonetici/musteri-destek?ticketId=${ticket.id}`)
      .then((res) => res.json())
      .then((data) => { if (!cancelled) setMessages(data.messages ?? []); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [ticket.id]);

  const sendReply = async () => {
    if (!reply.trim()) return;
    setSending(true);
    try {
      await apiReply(ticket.id, reply.trim());
      setMessages((prev) => [...prev, {
        id: `local-${Date.now()}`, ticket_id: ticket.id, sender: 'agent', message: reply.trim(), created_at: new Date().toISOString(),
      }]);
      setReply('');
      router.refresh();
    } finally {
      setSending(false);
    }
  };

  const applyTemplate = (text: string) => {
    setReply(text);
    setTemplateOpen(false);
    replyRef.current?.focus();
  };

  return (
    <>
      <div className="fixed inset-0 z-40 bg-black/30" onClick={onClose} aria-hidden="true" />
      <div className="fixed inset-y-0 right-0 z-50 flex w-full max-w-md flex-col border-l border-border bg-white shadow-2xl">
        <div className="flex items-start justify-between gap-3 border-b border-border p-5">
          <div className="min-w-0">
            <p className="font-mono text-[11px] text-muted">#{ticket.id.slice(0, 8)}</p>
            <p className="font-black text-textStrong">{ticket.subject}</p>
            <p className="text-xs text-muted">{ticket.requester_name ?? 'Bilinmiyor'} · {ticket.requester_email ?? ''}</p>
            <div className="mt-2 flex flex-wrap gap-1.5">
              <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${PRIORITY_MAP[ticket.priority]?.color ?? ''}`}>{PRIORITY_MAP[ticket.priority]?.label ?? ticket.priority}</span>
              <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${STATUS_MAP[ticket.status]?.color ?? ''}`}>{STATUS_MAP[ticket.status]?.label ?? ticket.status}</span>
              <span className="text-[10px] text-muted">{ticket.category}</span>
            </div>
          </div>
          <button onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-black/4 hover:text-textStrong" aria-label="Kapat">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="flex flex-1 flex-col gap-3 overflow-y-auto p-5">
          <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Mesaj Geçmişi</p>
          {loading ? (
            <p className="text-xs text-muted">Yükleniyor…</p>
          ) : messages.length === 0 ? (
            <p className="text-xs text-muted">Henüz mesaj yok.</p>
          ) : (
            <div className="flex flex-col gap-2">
              {messages.map((msg) => (
                <div key={msg.id} className={`flex ${msg.sender === 'agent' ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[85%] rounded-xl px-3 py-2 text-sm ${msg.sender === 'agent' ? 'bg-primary text-white' : 'border border-border bg-zinc-50 text-textStrong'}`}>
                    <p>{msg.message}</p>
                    <p className={`mt-1 text-[10px] ${msg.sender === 'agent' ? 'text-white/70' : 'text-muted'}`}>
                      {msg.sender === 'agent' ? 'Destek Ekibi' : (ticket.requester_name ?? 'Kullanıcı')} · {new Date(msg.created_at).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="flex flex-col gap-2 border-t border-border p-5">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Yanıt Yaz</p>
            <div className="relative">
              <button onClick={() => setTemplateOpen(!templateOpen)} className="rounded-lg border border-border px-2 py-1 text-[10px] font-bold text-muted hover:text-textStrong">
                Şablon Seç ▾
              </button>
              {templateOpen && (
                <div className="absolute right-0 bottom-full z-10 mb-1 w-72 rounded-xl border border-border bg-white shadow-lg">
                  {Object.entries(RESPONSE_TEMPLATES).map(([cat, tmps]) => (
                    <div key={cat} className="border-b border-border last:border-0">
                      <p className="px-3 pt-2 text-[9px] font-extrabold uppercase tracking-wide text-muted">
                        {cat === 'default' ? 'Genel' : cat === 'technical' ? 'Teknik' : cat === 'billing' ? 'Ödeme' : 'Şikayet'}
                      </p>
                      {tmps.map((t, i) => (
                        <button key={i} onClick={() => applyTemplate(t)} className="block w-full px-3 py-2 text-left text-xs text-textStrong hover:bg-black/3">
                          {t.length > 60 ? t.slice(0, 60) + '…' : t}
                        </button>
                      ))}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
          <textarea
            ref={replyRef}
            value={reply}
            onChange={(e) => setReply(e.target.value)}
            placeholder="Müşteriye yanıt yazın…"
            rows={3}
            className="w-full rounded-xl border border-border bg-white px-3 py-2 text-sm focus:border-primary focus:outline-hidden"
          />
          <div className="flex flex-wrap gap-2">
            <button disabled={sending || !reply.trim()} onClick={sendReply} className="rounded-lg bg-primary px-4 py-1.5 text-xs font-extrabold text-white hover:bg-primary/90 disabled:opacity-50">
              {sending ? 'Gönderiliyor…' : 'Yanıt Gönder'}
            </button>
            <button disabled={isPending} onClick={() => onStatusChange(STATUS_CYCLE[ticket.status] ?? 'open')} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-muted hover:text-textStrong disabled:opacity-50">
              {ticket.status === 'open' ? 'İşleme Al' : ticket.status === 'in_progress' ? 'Çözüldü İşaretle' : ticket.status === 'resolved' ? 'Kapat' : 'Yeniden Aç'}
            </button>
          </div>
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
