'use client';

import { useState } from 'react';
import type { DestekTicket, DestekMesaj } from './destek-islemleri';
import { destekTalebiDetay } from './destek-islemleri';
import { PopulerKonular } from './bilesenler/populer-konular';
import { SssWidget } from './bilesenler/sss-widget';
import { HizliIletisim } from './bilesenler/hizli-iletisim';
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
      </div>

      <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
        <SssWidget />
        <HizliIletisim />
      </div>

      {showForm && (
        <YeniTalepFormu businesses={businesses} onSuccess={handleNewTicketSuccess} onCancel={() => setShowForm(false)} />
      )}
    </div>
  );
}
