import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { EtkinlikYoneticisi } from './etkinlik-istemci';

export const metadata: Metadata = {
  title: 'Etkinlik Yönetimi | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerEtkinlikPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  const businessIds = businesses.map((b) => b.id);

  // Fetch events
  const { data: events } = businessIds.length > 0
    ? await (supabase as any)
        .from('business_events')
        .select('id, business_id, title, description, event_date, end_date, capacity, ticket_price, tickets_sold, status, created_at')
        .in('business_id', businessIds)
        .order('event_date', { ascending: true })
        .limit(50)
    : { data: [] };

  const allEvents = (events ?? []) as Array<{
    id: string; business_id: string; title: string; description: string;
    event_date: string; end_date: string | null; capacity: number | null;
    ticket_price: number | null; tickets_sold: number; status: string; created_at: string;
  }>;

  const now = new Date();
  const upcoming = allEvents.filter(e => new Date(e.event_date) >= now && e.status === 'active');
  const past = allEvents.filter(e => new Date(e.event_date) < now || e.status !== 'active');

  // Revenue from tickets
  const totalRevenue = allEvents.reduce((s, e) => s + ((e.ticket_price ?? 0) * (e.tickets_sold ?? 0)), 0);
  const totalTicketsSold = allEvents.reduce((s, e) => s + (e.tickets_sold ?? 0), 0);

  const bizMap = Object.fromEntries(businesses.map(b => [b.id, b.name]));

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Sahip"
        title="Etkinlik Yönetimi"
        description="İşletme etkinlikleri, kapasite takibi ve bilet yönetimi"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Stats */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Yaklaşan</p>
              <p className="mt-1 text-2xl font-[900] text-blue-600">{upcoming.length}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Toplam Etkinlik</p>
              <p className="mt-1 text-2xl font-[900] text-textStrong">{allEvents.length}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Satılan Bilet</p>
              <p className="mt-1 text-2xl font-[900] text-green-600">{totalTicketsSold.toLocaleString('tr-TR')}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Bilet Geliri</p>
              <p className="mt-1 text-2xl font-[900] text-primary">₺{totalRevenue.toLocaleString('tr-TR')}</p>
            </div>
          </div>

          {/* Event Manager (create + list) */}
          <EtkinlikYoneticisi
            events={allEvents}
            bizIds={businessIds}
            bizMap={bizMap}
            upcoming={upcoming}
            past={past}
          />
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
