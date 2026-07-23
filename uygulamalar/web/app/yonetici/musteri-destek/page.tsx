import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MusteriDestekListesi } from './musteri-destek-istemci';

export const metadata: Metadata = {
  title: 'Müşteri Destek | Admin Panel',
  robots: { index: false, follow: false },
};

const STATUS_MAP: Record<string, { label: string; color: string }> = {
  open:        { label: 'Açık',        color: 'bg-blue-50 text-blue-700' },
  in_progress: { label: 'İşlemde',     color: 'bg-yellow-50 text-yellow-700' },
  resolved:    { label: 'Çözüldü',     color: 'bg-green-50 text-green-700' },
  closed:      { label: 'Kapatıldı',   color: 'bg-zinc-100 text-zinc-500' },
};

const PRIORITY_MAP: Record<string, { label: string; color: string }> = {
  low:    { label: 'Düşük',  color: 'bg-zinc-50 text-zinc-500' },
  medium: { label: 'Orta',   color: 'bg-blue-50 text-blue-700' },
  high:   { label: 'Yüksek', color: 'bg-orange-50 text-orange-700' },
  urgent: { label: 'Acil',   color: 'bg-red-50 text-red-700' },
};

export default async function MusteriDestekPage() {
  const supabase = await createSupabaseServerClient();

  const { data: tickets } = await (supabase as any)
    .from('support_tickets')
    .select('id, subject, status, priority, category, created_at, updated_at, requester_name, requester_email')
    .order('created_at', { ascending: false })
    .limit(100) as { data: Array<{
      id: string; subject: string; status: string; priority: string;
      category: string; created_at: string; updated_at: string;
      requester_name: string | null; requester_email: string | null;
    }> | null };

  const allTickets = (tickets ?? []).map((ticket) => ({
    id: ticket.id,
    subject: ticket.subject,
    status: ticket.status,
    priority: ticket.priority,
    category: ticket.category,
    created_at: ticket.created_at,
    updated_at: ticket.updated_at,
    user_profiles: {
      display_name: ticket.requester_name ?? 'Bilinmiyor',
      email: ticket.requester_email ?? '',
    },
  }));

  const counts = {
    open:        allTickets.filter(t => t.status === 'open').length,
    in_progress: allTickets.filter(t => t.status === 'in_progress').length,
    resolved:    allTickets.filter(t => t.status === 'resolved').length,
    urgent:      allTickets.filter(t => t.priority === 'urgent').length,
  };

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Müşteri Destek"
        description="Destek talepleri ve kullanıcı sorunlarını yönet"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          {/* Stats */}
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Açık</p>
              <p className="mt-1 text-2xl font-[900] text-blue-600">{counts.open}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">İşlemde</p>
              <p className="mt-1 text-2xl font-[900] text-yellow-600">{counts.in_progress}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Çözüldü</p>
              <p className="mt-1 text-2xl font-[900] text-green-600">{counts.resolved}</p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4">
              <p className="text-xs font-[700] uppercase tracking-wide text-muted">Acil</p>
              <p className="mt-1 text-2xl font-[900] text-red-600">{counts.urgent}</p>
            </div>
          </div>

          {/* Ticket List */}
          <PanelBolumKarti title="Destek Talepleri" noPadding>
            {allTickets.length === 0 ? (
              <div className="flex flex-col items-center gap-3 py-16">
                <HeadsetIcon />
                <p className="text-sm text-muted">Henüz destek talebi yok</p>
              </div>
            ) : (
              <MusteriDestekListesi
                tickets={allTickets}
                statusMap={STATUS_MAP}
                priorityMap={PRIORITY_MAP}
              />
            )}
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function HeadsetIcon() {
  return (
    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
      <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
    </svg>
  );
}
