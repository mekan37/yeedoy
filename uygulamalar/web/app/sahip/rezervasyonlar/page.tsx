import type { Metadata } from 'next';
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

  const { data: result, error: rpcError } = await (supabase as any).rpc('owner_list_reservations_v1', {
    p_business_id: claim.business_id,
    p_limit: 50,
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
