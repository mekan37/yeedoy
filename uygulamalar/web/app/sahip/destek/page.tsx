import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { DestekIstemci } from './destek-istemci';
import type { DestekTicket } from './destek-islemleri';

export const metadata: Metadata = {
  title: 'Destek | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function DestekSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=%2Fsahip%2Fdestek');

  const businessIds = await getOwnerBusinessIds(supabase, user.id);
  const { data: businessRows } =
    businessIds.length > 0
      ? await (supabase as any).from('businesses').select('id, name').in('id', businessIds)
      : { data: [] };
  const businesses = (businessRows ?? []) as Array<{ id: string; name: string }>;

  const { data: ticketRows } = await (supabase as any)
    .from('support_tickets')
    .select('id, subject, status, category, business_id, created_at, updated_at')
    .eq('user_id', user.id)
    .order('updated_at', { ascending: false });
  const tickets = (ticketRows ?? []) as DestekTicket[];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Destek"
        title="Yeedoy Destek"
        description="Sorularınız için buradayız! Size nasıl yardımcı olabiliriz?"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <DestekIstemci initialTickets={tickets} businesses={businesses} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
