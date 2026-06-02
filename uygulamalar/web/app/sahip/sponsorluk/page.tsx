import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { SponsorlukFormu } from './sponsorluk-formu';

export const metadata: Metadata = {
  title: 'Sponsorluk | Sahip Paneli',
  robots: { index: false, follow: false },
};

const VITRIN_OZELLIKLER = [
  { icon: '🏆', baslik: 'Öncelikli Sıralama', aciklama: 'İlçe ve kategori listelerinde üst 3 pozisyon' },
  { icon: '🔔', baslik: 'Push Bildirimi', aciklama: 'Ayda 4 kez takipçilerinize "bugünün spesiyali" bildirimi' },
  { icon: '📊', baslik: 'Aylık Görüntüleme Raporu', aciklama: 'Kaç kullanıcı profilinizi gördü ve tıkladı' },
  { icon: '✨', baslik: 'Vitrin İşletme Rozeti', aciklama: 'Profilinizde öne çıkan "Vitrin" rozeti' },
  { icon: '📱', baslik: 'QR Menü Önceliği', aciklama: 'Menü yüklenme ve gösterim önceliği' },
];

export default async function OwnerSponsorshipPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? await getOwnerBusinesses<{ id: string; name: string }>(supabase as any, user.id, 'id, name')
    : [];

  // Mevcut aktif başvuruları çek
  const { data: leads } = user
    ? await (supabase as any)
        .from('sponsorship_leads')
        .select('id, status, created_at, business:business_id(name)')
        .eq('owner_user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(5)
    : { data: [] };

  const mevcutBasvurular = (leads ?? []) as any[];
  const aktifBasvuru = mevcutBasvurular.find((l) => l.status === 'new' || l.status === 'contacted');

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Sponsorluk"
        description="Yeedoy Vitrin paketi ile işletmenizi öne çıkarın"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid gap-6 lg:grid-cols-2">
          {/* Sol: Paket detayı */}
          <PanelBolumKarti title="Yeedoy Vitrin Paketi">
            <div className="flex flex-col gap-4">
              {/* Fiyat */}
              <div className="rounded-xl bg-primary/5 border border-primary/20 p-5">
                <div className="flex items-baseline gap-1">
                  <span className="text-4xl font-[900] text-primary">490</span>
                  <span className="text-lg font-[700] text-primary">TL</span>
                  <span className="ml-1 text-sm text-muted">/ay</span>
                </div>
                <p className="mt-1 text-sm text-muted">Aylık, iptal edilebilir</p>
              </div>

              {/* Özellikler */}
              <div className="flex flex-col gap-3">
                {VITRIN_OZELLIKLER.map((o) => (
                  <div key={o.baslik} className="flex items-start gap-3">
                    <span className="text-xl leading-tight">{o.icon}</span>
                    <div>
                      <p className="text-sm font-[700] text-textStrong">{o.baslik}</p>
                      <p className="text-xs text-muted">{o.aciklama}</p>
                    </div>
                  </div>
                ))}
              </div>

              {/* Karşılaştırma notu */}
              <div className="rounded-xl bg-card border border-border p-4 text-xs text-muted">
                <p className="font-[700] text-textStrong mb-1">Neden Yeedoy Vitrin?</p>
                <p>Instagram reklam bütçenizin çok altında, ama satın alma niyetli kullanıcılarla buluşuyorsunuz. Yeedoy&apos;da restoran arayan biri zaten karar aşamasında.</p>
              </div>
            </div>
          </PanelBolumKarti>

          {/* Sağ: Form veya aktif başvuru */}
          <PanelBolumKarti title={aktifBasvuru ? 'Aktif Başvurunuz' : 'Paket Başvurusu'}>
            {aktifBasvuru ? (
              <div className="flex flex-col gap-4">
                <div className="rounded-xl bg-amber-50 border border-amber-200 p-5">
                  <p className="font-[800] text-amber-800">Başvurunuz İnceleniyor</p>
                  <p className="mt-1 text-sm text-amber-700">
                    <span className="font-[700]">{aktifBasvuru.business?.name}</span> için başvurunuz alındı.
                    Yeedoy ekibi en kısa sürede sizinle iletişime geçecek.
                  </p>
                  <p className="mt-2 text-xs text-amber-600">
                    Başvuru tarihi: {new Date(aktifBasvuru.created_at).toLocaleDateString('tr-TR')}
                  </p>
                </div>
                <p className="text-sm text-muted text-center">
                  Sorunuz mu var?{' '}
                  <a href="mailto:destek@yeedoy.com" className="text-primary font-[700] hover:underline">
                    destek@yeedoy.com
                  </a>
                </p>
              </div>
            ) : (
              <>
                {businesses.length === 0 ? (
                  <div className="text-center py-6">
                    <p className="text-sm text-muted">Başvuru yapabilmek için önce bir işletme eklemeniz gerekiyor.</p>
                    <Link
                      href="/sahip/isletmeler/yeni"
                      className="mt-3 inline-block rounded-xl bg-primary px-4 py-2 text-sm font-[800] text-white"
                    >
                      İşletme Ekle
                    </Link>
                  </div>
                ) : (
                  <SponsorlukFormu businesses={businesses as Array<{ id: string; name: string }>} />
                )}
              </>
            )}
          </PanelBolumKarti>
        </div>

        {/* Geçmiş başvurular */}
        {mevcutBasvurular.length > 1 && (
          <PanelBolumKarti title="Geçmiş Başvurular" className="mt-6">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {mevcutBasvurular.map((l: any) => (
                  <tr key={l.id}>
                    <td className="px-5 py-3 font-[700] text-textStrong">{l.business?.name ?? '—'}</td>
                    <td className="px-5 py-3">
                      <span
                        className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                          l.status === 'new'
                            ? 'bg-amber-50 text-amber-700'
                            : l.status === 'contacted'
                              ? 'bg-blue-50 text-blue-700'
                              : l.status === 'converted'
                                ? 'bg-green-50 text-green-700'
                                : 'bg-zinc-100 text-zinc-500'
                        }`}
                      >
                        {l.status === 'new'
                          ? 'Yeni'
                          : l.status === 'contacted'
                            ? 'İletişime Geçildi'
                            : l.status === 'converted'
                              ? 'Dönüştürüldü'
                              : l.status}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-xs text-muted">
                      {new Date(l.created_at).toLocaleDateString('tr-TR')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </PanelBolumKarti>
        )}
      </PanelIcerikYuzeyi>
    </div>
  );
}
