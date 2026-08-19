'use client';

import { useState } from 'react';
import type { DestekTicket, DestekMesaj } from './destek-islemleri';
import { destekTalebiDetay } from './destek-islemleri';
import { PopulerKonular } from './bilesenler/populer-konular';
import { SssWidget } from './bilesenler/sss-widget';
import { HizliIletisim } from './bilesenler/hizli-iletisim';
import { YardimKaynaklari } from './bilesenler/yardim-kaynaklari';
import { TalepListesi } from './bilesenler/talep-listesi';
import { TalepDetay } from './bilesenler/talep-detay';
import { YeniTalepFormu } from './bilesenler/yeni-talep-formu';

export function DestekIstemci({
  initialTickets,
  businesses,
}: {
  initialTickets: DestekTicket[];
  businesses: Array<{ id: string; name: string }>;
}) {
  const tickets = initialTickets;
  const [selected, setSelected] = useState<{ ticket: DestekTicket; messages: DestekMesaj[] } | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [arama, setArama] = useState('');

  async function openTicket(ticketId: string) {
    setLoadError(null);
    const result = await destekTalebiDetay(ticketId);
    if ('error' in result) {
      setLoadError(result.error);
      return;
    }
    setSelected(result);
  }

  function handleNewTicketSuccess(ticketId: string) {
    setShowForm(false);
    void openTicket(ticketId);
  }

  function handleMessageSent(message: DestekMesaj) {
    if (!selected) return;
    setSelected({ ...selected, messages: [...selected.messages, message] });
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-textStrong">Yeedoy Destek</h1>
          <p className="mt-1 text-sm text-muted">Sorularınız için buradayız! Size nasıl yardımcı olabiliriz?</p>
        </div>
        <div className="relative w-full sm:max-w-xs">
          <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={arama}
            onChange={(e) => setArama(e.target.value)}
            placeholder="Destek merkezinde ara..."
            className="w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </div>
      </div>

      <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
        <div className="flex min-w-0 flex-1 flex-col gap-6">
          <PopulerKonular />

          {loadError && <p className="text-xs font-bold text-red-600">{loadError}</p>}

          {selected ? (
            <TalepDetay
              ticket={selected.ticket}
              messages={selected.messages}
              onBack={() => setSelected(null)}
              onMessageSent={handleMessageSent}
            />
          ) : (
            <TalepListesi tickets={tickets} onSelect={openTicket} onYeniTalep={() => setShowForm(true)} />
          )}

          <div
            className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left"
            style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}
          >
            <div>
              <p className="font-black text-textStrong">Başka bir sorunuz mu var?</p>
              <p className="text-sm text-muted">Ekibimiz size en kısa sürede yardımcı olacaktır.</p>
            </div>
            <button
              type="button"
              onClick={() => setShowForm(true)}
              className="inline-flex shrink-0 items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
              style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
            >
              <PlusIcon /> Yeni Talep Oluştur
            </button>
          </div>
        </div>

        <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
          <SssWidget filter={arama} />
          <HizliIletisim />
          <YardimKaynaklari />
        </div>
      </div>

      {showForm && (
        <YeniTalepFormu businesses={businesses} onSuccess={handleNewTicketSuccess} onCancel={() => setShowForm(false)} />
      )}
    </div>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={className}>
      <circle cx="11" cy="11" r="7" />
      <path d="m21 21-4.35-4.35" />
    </svg>
  );
}
function PlusIcon() {
  return (
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
      <path d="M12 5v14M5 12h14" />
    </svg>
  );
}
