'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface Event {
  id: string; business_id: string; title: string; description: string;
  event_date: string; end_date: string | null; capacity: number | null;
  ticket_price: number | null; tickets_sold: number; status: string; created_at: string;
}

async function createEvent(data: {
  bizId: string; title: string; description: string; eventDate: string;
  capacity: number | null; ticketPrice: number | null;
}) {
  return fetch('/sunucu/sahip/etkinlik', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
}

async function cancelEvent(id: string) {
  return fetch('/sunucu/sahip/etkinlik', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, status: 'cancelled' }),
  });
}

export function EtkinlikYoneticisi({
  events, bizIds, bizMap, upcoming, past,
}: {
  events: Event[];
  bizIds: string[];
  bizMap: Record<string, string>;
  upcoming: Event[];
  past: Event[];
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [showCreate, setShowCreate] = useState(false);
  const [tab, setTab] = useState<'upcoming' | 'past'>('upcoming');

  // Form state
  const [bizId, setBizId] = useState(bizIds[0] ?? '');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [eventDate, setEventDate] = useState('');
  const [capacity, setCapacity] = useState('');
  const [ticketPrice, setTicketPrice] = useState('');
  const [error, setError] = useState('');

  const submit = () => {
    if (!title.trim() || !eventDate) { setError('Başlık ve tarih zorunludur'); return; }
    setError('');
    startTransition(async () => {
      const res = await createEvent({
        bizId,
        title: title.trim(),
        description: description.trim(),
        eventDate,
        capacity: capacity ? parseInt(capacity) : null,
        ticketPrice: ticketPrice ? parseFloat(ticketPrice) : null,
      });
      if (res.ok) {
        setShowCreate(false); setTitle(''); setDescription(''); setEventDate(''); setCapacity(''); setTicketPrice('');
        router.refresh();
      } else {
        setError('Etkinlik oluşturulamadı');
      }
    });
  };

  const displayed = tab === 'upcoming' ? upcoming : past;

  return (
    <div className="flex flex-col gap-4">
      {/* Controls */}
      <div className="flex items-center justify-between">
        <div className="flex gap-1 rounded-xl bg-zinc-100 p-1">
          {(['upcoming', 'past'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)}
              className={`rounded-lg px-4 py-1.5 text-sm font-bold transition-colors ${tab === t ? 'bg-white text-textStrong shadow-sm' : 'text-muted'}`}>
              {t === 'upcoming' ? `Yaklaşan (${upcoming.length})` : `Geçmiş (${past.length})`}
            </button>
          ))}
        </div>
        <button onClick={() => setShowCreate(!showCreate)}
          className="rounded-xl bg-primary px-4 py-2 text-sm font-extrabold text-white hover:bg-primary/90">
          + Etkinlik Ekle
        </button>
      </div>

      {/* Create Form */}
      {showCreate && (
        <div className="rounded-2xl border border-primary/30 bg-primary/5 p-5">
          <p className="mb-4 font-extrabold text-textStrong">Yeni Etkinlik Oluştur</p>
          <div className="grid gap-3 sm:grid-cols-2">
            {bizIds.length > 1 && (
              <div className="sm:col-span-2">
                <label className="mb-1 block text-xs font-bold text-muted">İşletme</label>
                <select value={bizId} onChange={e => setBizId(e.target.value)}
                  className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-hidden">
                  {bizIds.map(id => <option key={id} value={id}>{bizMap[id] ?? id}</option>)}
                </select>
              </div>
            )}
            <div className="sm:col-span-2">
              <label className="mb-1 block text-xs font-bold text-muted">Etkinlik Adı *</label>
              <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Ör: Aralık Müzik Gecesi"
                className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-hidden" />
            </div>
            <div className="sm:col-span-2">
              <label className="mb-1 block text-xs font-bold text-muted">Açıklama</label>
              <textarea value={description} onChange={e => setDescription(e.target.value)} rows={2}
                className="w-full resize-none rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-hidden" />
            </div>
            <div>
              <label className="mb-1 block text-xs font-bold text-muted">Tarih ve Saat *</label>
              <input type="datetime-local" value={eventDate} onChange={e => setEventDate(e.target.value)}
                className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-hidden" />
            </div>
            <div>
              <label className="mb-1 block text-xs font-bold text-muted">Kapasite (opsiyonel)</label>
              <input type="number" min={0} value={capacity} onChange={e => setCapacity(e.target.value)} placeholder="Sınırsız"
                className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-hidden" />
            </div>
            <div>
              <label className="mb-1 block text-xs font-bold text-muted">Bilet Fiyatı ₺ (opsiyonel)</label>
              <input type="number" min={0} step={0.01} value={ticketPrice} onChange={e => setTicketPrice(e.target.value)} placeholder="Ücretsiz"
                className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm focus:border-primary focus:outline-hidden" />
            </div>
          </div>
          {error && <p className="mt-2 text-xs font-bold text-red-600">{error}</p>}
          <div className="mt-4 flex gap-2">
            <button onClick={submit} disabled={isPending}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-extrabold text-white hover:bg-primary/90 disabled:opacity-50">
              {isPending ? 'Kaydediliyor…' : 'Oluştur'}
            </button>
            <button onClick={() => setShowCreate(false)} className="rounded-xl border border-border px-4 py-2 text-sm font-bold text-muted hover:text-textStrong">İptal</button>
          </div>
        </div>
      )}

      {/* Event List */}
      <div className="rounded-xl border border-border overflow-hidden">
        {displayed.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-12">
            <CalendarIcon />
            <p className="text-sm text-muted">{tab === 'upcoming' ? 'Yaklaşan etkinlik yok' : 'Geçmiş etkinlik yok'}</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-zinc-50 text-left">
                <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Etkinlik</th>
                <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
                <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kapasite</th>
                <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Bilet</th>
                <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
                <th className="px-5 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {displayed.map(ev => {
                const fillPct = ev.capacity ? Math.round((ev.tickets_sold / ev.capacity) * 100) : null;
                const isFull = fillPct !== null && fillPct >= 100;
                return (
                  <tr key={ev.id} className="hover:bg-black/2">
                    <td className="px-5 py-3">
                      <p className="font-bold text-textStrong">{ev.title}</p>
                      {ev.description && <p className="line-clamp-1 text-xs text-muted">{ev.description}</p>}
                      <p className="text-[10px] text-muted">{bizMap[ev.business_id] ?? ''}</p>
                    </td>
                    <td className="px-5 py-3 text-xs text-muted">
                      {new Date(ev.event_date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' })}
                    </td>
                    <td className="px-5 py-3">
                      {ev.capacity ? (
                        <div>
                          <div className="flex items-center gap-1.5">
                            <div className="h-1.5 w-16 overflow-hidden rounded-full bg-zinc-100">
                              <div className={`h-full rounded-full ${isFull ? 'bg-red-500' : 'bg-green-500'}`} style={{ width: `${Math.min(fillPct ?? 0, 100)}%` }} />
                            </div>
                            <span className="text-xs font-bold text-textStrong">{ev.tickets_sold}/{ev.capacity}</span>
                          </div>
                          {isFull && <span className="text-[10px] font-bold text-red-600">DOLU</span>}
                        </div>
                      ) : (
                        <span className="text-xs text-muted">Sınırsız</span>
                      )}
                    </td>
                    <td className="px-5 py-3 font-extrabold text-primary">
                      {ev.ticket_price ? `₺${ev.ticket_price.toLocaleString('tr-TR')}` : 'Ücretsiz'}
                    </td>
                    <td className="px-5 py-3">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold ${ev.status === 'active' ? 'bg-green-50 text-green-700' : ev.status === 'cancelled' ? 'bg-red-50 text-red-700' : 'bg-zinc-100 text-zinc-500'}`}>
                        {ev.status === 'active' ? 'Aktif' : ev.status === 'cancelled' ? 'İptal' : ev.status}
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      {ev.status === 'active' && (
                        <button
                          disabled={isPending}
                          onClick={() => startTransition(async () => { await cancelEvent(ev.id); router.refresh(); })}
                          className="rounded-lg border border-red-200 px-2 py-1 text-[10px] font-bold text-red-600 hover:bg-red-50 disabled:opacity-50"
                        >
                          İptal
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

function CalendarIcon() {
  return (
    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}
