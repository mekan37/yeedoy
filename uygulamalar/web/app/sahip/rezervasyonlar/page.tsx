import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { ReservationsClient } from './rezervasyonlar-istemcisi';

export const metadata: Metadata = {
  title: 'Rezervasyonlar | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerReservationsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris');

  const { data: claim } = await (supabase as any)
    .from('owner_claims')
    .select('business_id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .limit(1)
    .maybeSingle();

  if (!claim) redirect('/sahip/gosterge-panosu');

  const { data: business } = await (supabase as any)
    .from('businesses')
    .select('accepts_reservations')
    .eq('id', claim.business_id)
    .maybeSingle() as { data: { accepts_reservations: boolean | null } | null };

  if (!business?.accepts_reservations) {
    return (
      <div className="mx-auto max-w-[1300px] p-6">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-textStrong">Rezervasyonlar</h1>
          <p className="mt-1 text-sm text-muted">Tüm rezervasyonlarınızı görüntüleyin, durumlarını yönetin ve detaylarını inceleyin.</p>
        </div>
        <div className="mt-6 flex flex-col items-center gap-4 rounded-2xl border border-dashed border-border px-6 py-16 text-center">
          <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/10 text-primary">
            <CalendarOffIcon />
          </span>
          <div>
            <p className="text-base font-black text-textStrong">Rezervasyon kabulü kapalı</p>
            <p className="mx-auto mt-1 max-w-md text-sm text-muted">
              Müşterilerinizin rezervasyon talebi gönderebilmesi ve bu sayfayı kullanabilmeniz için önce
              Ayarlar → Rezervasyon Ayarları bölümünden rezervasyon kabulünü açmanız gerekiyor.
            </p>
          </div>
          <Link
            href="/sahip/ayarlar"
            className="inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
            style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
          >
            Ayarlardan Aç →
          </Link>
        </div>
      </div>
    );
  }

  const { data: result, error: rpcError } = await (supabase as any).rpc('owner_list_reservations_v1', {
    p_business_id: claim.business_id,
    p_limit: 200,
    p_offset: 0,
  });

  if (rpcError) {
    console.error('[owner/reservations] RPC error:', rpcError.message);
    // Still render the page with empty data rather than crashing
  }

  return (
    <ReservationsClient
      businessId={claim.business_id}
      initialReservations={result?.rows ?? []}
      total={result?.total ?? 0}
    />
  );
}

function CalendarOffIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" />
      <path d="M16 2v4M8 2v4M3 10h18" />
      <line x1="7" y1="14" x2="17" y2="20" />
    </svg>
  );
}
