import type { Metadata } from 'next';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { AKTIF_ISLETME_COOKIE_NAME } from '@/src/ui/kabuk/aktif-isletme-cerezi';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { MusterilerIstemcisi, type MusteriOzet } from './musteriler-istemcisi';
import { zincirAciklamasiOlustur } from './musteriler-yardimcilari';

export const metadata: Metadata = {
  title: 'Müşteriler | Sahip Paneli',
  robots: { index: false, follow: false },
};

const GUN_SAYISI = 14;

export default async function MusterilerSayfasi() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/musteriler');

  const [businesses, cookieStore] = await Promise.all([
    getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name'),
    cookies(),
  ]);
  if (businesses.length === 0) redirect('/sahip');

  const cookieId = cookieStore.get(AKTIF_ISLETME_COOKIE_NAME)?.value;
  const businessId = businesses.find((b) => b.id === cookieId)?.id ?? businesses[0].id;

  const sb = supabase as any;

  const [{ data: customersRaw }, { data: businessChain }, { data: program }] = await Promise.all([
    sb.rpc('get_business_customers_v1', { p_business_id: businessId }) as Promise<{ data: MusteriOzet[] | null }>,
    sb.from('businesses').select('chain_id, chains(name)').eq('id', businessId).maybeSingle() as Promise<{
      data: { chain_id: string | null; chains: { name: string } | null } | null;
    }>,
    sb.from('loyalty_programs').select('id').eq('business_id', businessId).maybeSingle() as Promise<{ data: { id: string } | null }>,
  ]);

  const musteriler = customersRaw ?? [];
  const zincirAdi = businessChain?.chains?.name ?? null;

  // Son GUN_SAYISI gün için gerçek günlük etkileşim serileri (ziyaret / rezervasyon / sadakat)
  const since = new Date(Date.now() - GUN_SAYISI * 86400000).toISOString();

  type OlayZamani = { created_at: string };
  const [{ data: pageViews }, { data: reservationRows }, { data: loyaltyEventRows }] = await Promise.all([
    sb.from('analytics_events').select('created_at').eq('business_id', businessId).eq('event_name', 'business_page_view').gte('created_at', since) as Promise<{ data: OlayZamani[] | null }>,
    sb.from('reservations').select('created_at').eq('business_id', businessId).gte('created_at', since) as Promise<{ data: OlayZamani[] | null }>,
    (program?.id
      ? sb.from('loyalty_events').select('created_at, loyalty_members!inner(program_id)').eq('loyalty_members.program_id', program.id).gte('created_at', since)
      : Promise.resolve({ data: [] })) as Promise<{ data: OlayZamani[] | null }>,
  ]);

  function gunlukSeri(rows: Array<{ created_at: string }> | null): Record<string, number> {
    const map: Record<string, number> = {};
    for (const r of rows ?? []) {
      const key = r.created_at.split('T')[0];
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  const ziyaretGunluk = gunlukSeri(pageViews);
  const rezervasyonGunluk = gunlukSeri(reservationRows);
  const sadakatGunluk = gunlukSeri(loyaltyEventRows);

  const gunler: string[] = [];
  for (let i = GUN_SAYISI - 1; i >= 0; i--) {
    gunler.push(new Date(Date.now() - i * 86400000).toISOString().split('T')[0]);
  }

  const etkilesimSerisi = gunler.map((g) => ({
    tarih: g,
    etiket: new Date(g).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' }),
    ziyaret: ziyaretGunluk[g] ?? 0,
    rezervasyon: rezervasyonGunluk[g] ?? 0,
    sadakat: sadakatGunluk[g] ?? 0,
  }));

  // En yoğun saat / en aktif gün (aynı GUN_SAYISI penceresindeki ziyaretlerden — gerçek)
  const saatDagilimi: Record<number, number> = {};
  const gunAdiDagilimi: Record<number, number> = {};
  for (const r of pageViews ?? []) {
    const d = new Date(r.created_at);
    saatDagilimi[d.getHours()] = (saatDagilimi[d.getHours()] ?? 0) + 1;
    gunAdiDagilimi[d.getDay()] = (gunAdiDagilimi[d.getDay()] ?? 0) + 1;
  }

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <MusterilerIstemcisi
          musteriler={musteriler}
          altBaslik={zincirAciklamasiOlustur(zincirAdi)}
          etkilesimSerisi={etkilesimSerisi}
          saatDagilimi={saatDagilimi}
          gunAdiDagilimi={gunAdiDagilimi}
        />
      </PanelIcerikYuzeyi>
    </div>
  );
}
