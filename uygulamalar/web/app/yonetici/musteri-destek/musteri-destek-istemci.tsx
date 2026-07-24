'use client';

import { useState, useTransition, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { Clock } from 'lucide-react';

interface Ticket {
  id: string; subject: string; status: string; priority: string;
  category: string; created_at: string; updated_at: string;
  user_profiles: { display_name: string; email: string } | null;
}

interface TicketMessage {
  id: string; ticket_id: string; sender: 'user' | 'agent';
  message: string; created_at: string;
}

const STATUS_CYCLE: Record<string, string> = {
  open: 'in_progress', in_progress: 'resolved', resolved: 'closed', closed: 'open',
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
    'Tarayıcınızı veya uygulamanızı güncelleyerek tekrar deneyiniz.',
  ],
  billing: [
    'Ödeme konusundaki talebinizi finans ekibimize ilettik.',
    'Fatura bilgilerinizi kontrol ettik. Herhangi bir sorun tespit etmedik.',
    'Para iadesi talebiniz işleme alınmıştır. 3-5 iş günü içinde hesabınıza yansıyacaktır.',
  ],
  complaint: [
    'Şikayetiniz için üzgünüz. Bu deneyimi iyileştirmek için gerekli adımları atacağız.',
    'Geri bildiriminiz bizim için değerli. Konuyu ilgili ekibe ilettik.',
    'Yaşadığınız olumsuz deneyim için özür dileriz. Size özel çözüm sunmak için iletişime geçeceğiz.',
  ],
};

function slaStatus(createdAt: string): { label: string; color: string } {
  const hours = (Date.now() - new Date(createdAt).getTime()) / 3_600_000;
  if (hours < 4) return { label: `${Math.round(hours * 60)}d önce`, color: 'text-green-600 bg-green-50' };
  if (hours < 24) return { label: `${Math.round(hours)}sa önce`, color: 'text-yellow-600 bg-yellow-50' };
  const days = Math.floor(hours / 24);
  return { label: `${days}g önce`, color: 'text-red-600 bg-red-50' };
}

export function MusteriDestekListesi({
  tickets, statusMap, priorityMap,
}: {
  tickets: Ticket[];
  statusMap: Record<string, { label: string; color: string }>;
  priorityMap: Record<string, { label: string; color: string }>;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [filter, setFilter] = useState<string>('all');
  const [selected, setSelected] = useState<string | null>(null);
  const [messages, setMessages] = useState<Record<string, TicketMessage[]>>({});
  const [reply, setReply] = useState('');
  const [loadingMsg, setLoadingMsg] = useState<string | null>(null);
  const [templateOpen, setTemplateOpen] = useState(false);
  const replyRef = useRef<HTMLTextAreaElement>(null);

  const filtered = filter === 'all' ? tickets : tickets.filter(t => t.status === filter);

  const openTicket = async (ticketId: string) => {
    if (selected === ticketId) { setSelected(null); return; }
    setSelected(ticketId);
    if (!messages[ticketId]) {
      setLoadingMsg(ticketId);
      try {
        const res = await fetch(`/sunucu/yonetici/musteri-destek?ticketId=${ticketId}`);
        const data = await res.json();
        setMessages(prev => ({ ...prev, [ticketId]: data.messages ?? [] }));
      } finally { setLoadingMsg(null); }
    }
  };

  const updateStatus = (ticketId: string, newStatus: string) => {
    startTransition(async () => {
      await fetch('/sunucu/yonetici/musteri-destek', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ticketId, status: newStatus }),
      });
      router.refresh();
    });
  };

  const sendReply = (ticketId: string) => {
    if (!reply.trim()) return;
    startTransition(async () => {
      await fetch('/sunucu/yonetici/musteri-destek', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ticketId, message: reply.trim(), sender: 'agent' }),
      });
      setMessages(prev => ({
        ...prev,
        [ticketId]: [...(prev[ticketId] ?? []), {
          id: Date.now().toString(), ticket_id: ticketId, sender: 'agent',
          message: reply.trim(), created_at: new Date().toISOString(),
        }],
      }));
      setReply('');
      router.refresh();
    });
  };

  const applyTemplate = (text: string) => {
    setReply(text);
    setTemplateOpen(false);
    replyRef.current?.focus();
  };

  // Resolution rate
  const resolved = tickets.filter(t => t.status === 'resolved' || t.status === 'closed').length;
  const resolutionRate = tickets.length ? Math.round((resolved / tickets.length) * 100) : 0;
  const urgent = tickets.filter(t => t.priority === 'urgent' && t.status !== 'closed').length;
  const avgAge = tickets.length
    ? Math.round(tickets.reduce((s, t) => s + (Date.now() - new Date(t.created_at).getTime()) / 3_600_000, 0) / tickets.length)
    : 0;

  return (
    <div className="flex flex-col">
      {/* Analytics bar */}
      <div className="grid grid-cols-2 gap-3 border-b border-border p-5 sm:grid-cols-4">
        <div>
          <p className="text-[10px] font-bold uppercase tracking-wide text-muted">Çözüm Oranı</p>
          <p className="mt-0.5 text-lg font-black text-green-600">%{resolutionRate}</p>
        </div>
        <div>
          <p className="text-[10px] font-bold uppercase tracking-wide text-muted">Ort. Bekleme</p>
          <p className="mt-0.5 text-lg font-black text-textStrong">{avgAge}sa</p>
        </div>
        <div>
          <p className="text-[10px] font-bold uppercase tracking-wide text-muted">Acil Açık</p>
          <p className={`mt-0.5 text-lg font-black ${urgent > 0 ? 'text-red-600' : 'text-green-600'}`}>{urgent}</p>
        </div>
        <div>
          <p className="text-[10px] font-bold uppercase tracking-wide text-muted">Toplam Talep</p>
          <p className="mt-0.5 text-lg font-black text-textStrong">{tickets.length}</p>
        </div>
      </div>

      {/* Status filter */}
      <div className="flex flex-wrap gap-2 border-b border-border px-5 py-3">
        {['all', 'open', 'in_progress', 'resolved', 'closed'].map(s => (
          <button
            key={s}
            onClick={() => setFilter(s)}
            className={`rounded-lg px-3 py-1 text-xs font-bold transition-colors ${filter === s ? 'bg-primary text-white' : 'text-muted hover:text-textStrong'}`}
          >
            {s === 'all' ? `Tümü (${tickets.length})` : (statusMap[s]?.label ?? s)}
          </button>
        ))}
      </div>

      <div className="divide-y divide-border">
        {filtered.map(ticket => {
          const sla = slaStatus(ticket.created_at);
          const ticketMessages = messages[ticket.id] ?? [];
          return (
            <div key={ticket.id}>
              <button
                onClick={() => openTicket(ticket.id)}
                className="flex w-full items-start gap-4 px-5 py-4 text-left hover:bg-black/2"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${priorityMap[ticket.priority]?.color ?? 'bg-zinc-100 text-zinc-500'}`}>
                      {priorityMap[ticket.priority]?.label ?? ticket.priority}
                    </span>
                    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${statusMap[ticket.status]?.color ?? 'bg-zinc-100 text-zinc-500'}`}>
                      {statusMap[ticket.status]?.label ?? ticket.status}
                    </span>
                    {ticket.category && (
                      <span className="text-[10px] text-muted">{ticket.category}</span>
                    )}
                    {/* SLA badge */}
                    <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold ${sla.color}`}>
                      <Clock className="h-3 w-3" aria-hidden="true" /> {sla.label}
                    </span>
                  </div>
                  <p className="mt-1 truncate font-bold text-textStrong">{ticket.subject}</p>
                  <p className="text-xs text-muted">
                    {ticket.user_profiles?.display_name ?? 'Bilinmiyor'} · {ticket.user_profiles?.email ?? ''} · {new Date(ticket.created_at).toLocaleDateString('tr-TR')}
                  </p>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={`mt-1 shrink-0 text-muted transition-transform ${selected === ticket.id ? 'rotate-180' : ''}`}>
                  <polyline points="6 9 12 15 18 9" />
                </svg>
              </button>

              {selected === ticket.id && (
                <div className="flex flex-col gap-0 border-t border-border bg-zinc-50">
                  {/* Message thread */}
                  <div className="flex flex-col gap-3 px-5 py-4">
                    <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Mesaj Geçmişi</p>
                    {loadingMsg === ticket.id ? (
                      <p className="text-xs text-muted">Yükleniyor…</p>
                    ) : ticketMessages.length === 0 ? (
                      <p className="text-xs text-muted">Henüz mesaj yok.</p>
                    ) : (
                      <div className="flex flex-col gap-2">
                        {ticketMessages.map(msg => (
                          <div key={msg.id} className={`flex ${msg.sender === 'agent' ? 'justify-end' : 'justify-start'}`}>
                            <div className={`max-w-[70%] rounded-xl px-3 py-2 text-sm ${msg.sender === 'agent' ? 'bg-primary text-white' : 'bg-white border border-border text-textStrong'}`}>
                              <p>{msg.message}</p>
                              <p className={`mt-1 text-[10px] ${msg.sender === 'agent' ? 'text-white/70' : 'text-muted'}`}>
                                {msg.sender === 'agent' ? 'Destek Ekibi' : (ticket.user_profiles?.display_name ?? 'Kullanıcı')} · {new Date(msg.created_at).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
                              </p>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {/* Reply compose */}
                    <div className="mt-2 flex flex-col gap-2">
                      <div className="flex items-center justify-between">
                        <p className="text-[10px] font-extrabold uppercase tracking-wide text-muted">Yanıt Yaz</p>
                        <div className="relative">
                          <button
                            onClick={() => setTemplateOpen(!templateOpen)}
                            className="rounded-lg border border-border px-2 py-1 text-[10px] font-bold text-muted hover:text-textStrong"
                          >
                            Şablon Seç ▾
                          </button>
                          {templateOpen && (
                            <div className="absolute right-0 top-full z-10 mt-1 w-72 rounded-xl border border-border bg-white shadow-lg">
                              {Object.entries(RESPONSE_TEMPLATES).map(([cat, tmps]) => (
                                <div key={cat} className="border-b border-border last:border-0">
                                  <p className="px-3 pt-2 text-[9px] font-extrabold uppercase tracking-wide text-muted">{
                                    cat === 'default' ? 'Genel' : cat === 'technical' ? 'Teknik' : cat === 'billing' ? 'Ödeme' : 'Şikayet'
                                  }</p>
                                  {tmps.map((t, i) => (
                                    <button key={i} onClick={() => applyTemplate(t)}
                                      className="block w-full px-3 py-2 text-left text-xs text-textStrong hover:bg-black/3">
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
                        onChange={e => setReply(e.target.value)}
                        placeholder="Müşteriye yanıt yazın…"
                        rows={3}
                        className="w-full rounded-xl border border-border bg-white px-3 py-2 text-sm focus:border-primary focus:outline-hidden"
                      />
                      <div className="flex flex-wrap gap-2">
                        <button
                          disabled={isPending || !reply.trim()}
                          onClick={() => sendReply(ticket.id)}
                          className="rounded-lg bg-primary px-4 py-1.5 text-xs font-extrabold text-white hover:bg-primary/90 disabled:opacity-50"
                        >
                          {isPending ? 'Gönderiliyor…' : 'Yanıt Gönder'}
                        </button>
                        <button
                          disabled={isPending}
                          onClick={() => updateStatus(ticket.id, STATUS_CYCLE[ticket.status] ?? 'open')}
                          className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-muted hover:text-textStrong disabled:opacity-50"
                        >
                          {ticket.status === 'open' ? 'İşleme Al' :
                           ticket.status === 'in_progress' ? 'Çözüldü İşaretle' :
                           ticket.status === 'resolved' ? 'Kapat' : 'Yeniden Aç'}
                        </button>
                        {['open', 'in_progress', 'resolved', 'closed'].filter(s => s !== ticket.status).map(s => (
                          <button
                            key={s}
                            disabled={isPending}
                            onClick={() => updateStatus(ticket.id, s)}
                            className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-muted hover:text-textStrong disabled:opacity-50"
                          >
                            {statusMap[s]?.label ?? s} yap
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
