import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinesses } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { EPostaKampanyaFormu } from './eposta-formu';

export const metadata: Metadata = {
  title: 'E-posta Kampanyaları | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerEmailCampaignsPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businesses = user
    ? (await getOwnerBusinesses<{ id: string; name: string; is_active: boolean | null }>(
      supabase as any,
      user.id,
      'id, name, is_active',
    )).filter((business) => business.is_active !== false)
    : [];

  const businessIds = businesses.map((b: { id: string }) => b.id);

  const { data: kampanyalar } = businessIds.length > 0
    ? await (supabase as any)
        .from('email_campaigns')
        .select('id, subject, status, sent_to, created_at')
        .in('business_id', businessIds)
        .order('created_at', { ascending: false })
        .limit(10)
    : { data: [] };

  const gecmisKampanyalar = (kampanyalar ?? []) as Array<{
    id: string;
    subject: string;
    status: string;
    sent_to: number | null;
    created_at: string;
  }>;

  const sablonlar = [
    { icon: '🎉', baslik: 'Özel Kampanya', konu: 'Bugün özel fırsat!', icerik: 'Sevgili {isim},\n\nSizi özel bir kampanyamıza davet etmek istiyoruz. Bu hafta sonu tüm ürünlerimizde %20 indirim var!\n\nSizi görmek için sabırsızlanıyoruz.' },
    { icon: '⭐', baslik: 'Yeni Menü', konu: 'Menümüze yeni lezzetler eklendi!', icerik: 'Sevgili {isim},\n\nHeyecanlı bir haberimiz var! Menümüze harika yeni lezzetler ekledik. Özellikle {isletme_adi} şefimizin özel tarifleri sizi bekliyor.\n\nRezervasyon için bize ulaşın.' },
    { icon: '🎂', baslik: 'Sezon Sonu', konu: 'Sezon sonu veda indirimi', icerik: 'Sevgili {isim},\n\nBu sezon bizimle olduğunuz için teşekkür ederiz. Veda indirimlerimizden yararlanmak için son fırsat!\n\nSevgilerle, {isletme_adi} ekibi' },
    { icon: '🌟', baslik: 'VIP Davet', konu: 'Sadık müşterimiz olarak sizi özel etkinliğimize davet ediyoruz', icerik: 'Sevgili {isim},\n\nDeğerli müşterimiz olarak sizi özel bir etkinliğe davet etmek istiyoruz.\n\nTarih: {tarih}\nYer: {isletme_adi}\n\nKatılımınızı bekliyoruz!' },
  ];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Pazarlama"
        title="E-posta Kampanyaları"
        description="Takipçilerinize e-posta ile ulaşın"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
          {/* Kampanya editörü */}
          <PanelBolumKarti title="Yeni E-posta Kampanyası">
            {businesses.length > 0 ? (
              <EPostaKampanyaFormu businesses={businesses} sablonlar={sablonlar} />
            ) : (
              <PanelEmptyState
                icon={<MailIcon />}
                title="İşletme bulunamadı"
                description="E-posta kampanyası için önce işletme ekleyin."
              />
            )}
          </PanelBolumKarti>

          {/* Sağ kolon */}
          <div className="flex flex-col gap-4">
            {/* Kişiselleştirme değişkenleri */}
            <PanelBolumKarti title="Kişiselleştirme">
              <div className="flex flex-col gap-2">
                <p className="text-xs text-muted mb-2">E-postanızda kullanabileceğiniz değişkenler:</p>
                {[
                  { kod: '{isim}', aciklama: 'Alıcının adı' },
                  { kod: '{isletme_adi}', aciklama: 'İşletmenizin adı' },
                  { kod: '{tarih}', aciklama: 'Bugünün tarihi' },
                  { kod: '{yil}', aciklama: 'Mevcut yıl' },
                ].map(v => (
                  <div key={v.kod} className="flex items-center justify-between">
                    <code className="rounded bg-cardAlt px-2 py-0.5 text-xs font-[700] text-primary">{v.kod}</code>
                    <span className="text-xs text-muted">{v.aciklama}</span>
                  </div>
                ))}
              </div>
            </PanelBolumKarti>

            {/* Geçmiş kampanyalar */}
            {gecmisKampanyalar.length > 0 && (
              <PanelBolumKarti title="Son Kampanyalar" noPadding>
                <ul className="divide-y divide-border">
                  {gecmisKampanyalar.map(k => (
                    <li key={k.id} className="flex items-start gap-3 px-4 py-3">
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-[700] text-textStrong truncate">{k.subject}</p>
                        <p className="text-xs text-muted">
                          {new Date(k.created_at).toLocaleDateString('tr-TR')}
                          {k.sent_to !== null && ` · ${k.sent_to} kişi`}
                        </p>
                      </div>
                      <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-[800] ${
                        k.status === 'sent' ? 'bg-success/10 text-success'
                        : k.status === 'scheduled' ? 'bg-info/10 text-info'
                        : 'bg-border text-muted'
                      }`}>
                        {k.status === 'sent' ? 'Gönderildi' : k.status === 'scheduled' ? 'Planlandı' : k.status}
                      </span>
                    </li>
                  ))}
                </ul>
              </PanelBolumKarti>
            )}

            {/* İpucu */}
            <div className="rounded-xl border border-info/25 bg-info/[0.06] p-4 text-xs text-muted">
              <strong>İpucu:</strong> E-postalar takipçilerinizin kayıtlı e-posta adreslerine gönderilir. Spam gitmemesi için e-posta doğrulaması gerekebilir.
            </div>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function MailIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
      <polyline points="22,6 12,13 2,6" />
    </svg>
  );
}
