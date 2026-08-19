import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getOnboardingStatus } from '@/src/lib/veri/owner/sahip-baslangic-durumu';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';

export const metadata: Metadata = {
  title: 'Başlangıç Rehberi | Sahip Paneli',
  robots: { index: false, follow: false },
};

type Durum = 'tamamlandi' | 'kismen' | 'eksik' | 'bekliyor';

const DURUM_ETIKETI: Record<Durum, { text: string; className: string }> = {
  tamamlandi: { text: 'Tamamlandı', className: 'bg-emerald-50 text-emerald-700' },
  kismen:     { text: 'Kısmen Tamamlandı', className: 'bg-amber-50 text-amber-700' },
  eksik:      { text: 'Eksik', className: 'bg-red-50 text-red-700' },
  bekliyor:   { text: 'Bekliyor', className: 'bg-zinc-100 text-zinc-500' },
};

export default async function OwnerOnboardingPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businessIds = await getOwnerBusinessIds(supabase as any, user!.id);

  const [{ data: submissions }, { data: profile }] = await Promise.all([
    (supabase as any)
      .from('business_submissions')
      .select('id, status')
      .eq('submitted_by', user!.id)
      .limit(1),
    (supabase as any)
      .from('user_profiles')
      .select('display_name')
      .eq('user_id', user!.id)
      .maybeSingle(),
  ]);

  const hasBusiness = businessIds.length > 0;
  const hasSubmission = (submissions ?? []).length > 0;
  const submissionPending = hasSubmission && submissions[0]?.status === 'new';
  const firstName = (profile?.display_name as string | null)?.trim().split(/\s+/)[0] || null;

  const onboarding = await getOnboardingStatus();

  let hasHours = false;
  let hasPhotos = false;
  let itemCount = 0;
  let hasCampaign = false;

  if (hasBusiness) {
    const [{ count: hoursCount }, { data: bizRows }, { count: campaignCount }, { data: menuRows }] = await Promise.all([
      (supabase as any).from('business_hours').select('id', { count: 'exact', head: true }).in('business_id', businessIds),
      (supabase as any).from('businesses').select('logo_url, cover_url').in('id', businessIds),
      (supabase as any).from('campaigns').select('id', { count: 'exact', head: true }).in('business_id', businessIds),
      (supabase as any).from('menus').select('id').in('business_id', businessIds),
    ]);
    hasHours = (hoursCount ?? 0) > 0;
    hasPhotos = (bizRows ?? []).some((b: { logo_url: string | null; cover_url: string | null }) => b.logo_url && b.cover_url);
    hasCampaign = (campaignCount ?? 0) > 0;

    const menuIds = ((menuRows ?? []) as Array<{ id: string }>).map((m) => m.id);
    if (menuIds.length > 0) {
      const { data: sectionRows } = await (supabase as any).from('menu_sections').select('id').in('menu_id', menuIds);
      const sectionIds = ((sectionRows ?? []) as Array<{ id: string }>).map((s) => s.id);
      if (sectionIds.length > 0) {
        const { count } = await (supabase as any).from('menu_items').select('id', { count: 'exact', head: true }).in('section_id', sectionIds);
        itemCount = count ?? 0;
      }
    }
  }

  const hasSomeItems = itemCount > 0;

  type Step = {
    num: number;
    title: string;
    description: string;
    durum: Durum;
    action: { label: string; href: string; variant: 'primary' | 'secondary' } | null;
  };

  const steps: Step[] = [
    {
      num: 1,
      title: 'İşletme bilgilerini tamamla',
      description: 'İşletme adı, adres, iletişim ve kategorilerini düzenle.',
      durum: hasBusiness ? 'tamamlandi' : submissionPending ? 'bekliyor' : 'eksik',
      action: hasBusiness
        ? { label: 'İşletmeleri Gör', href: '/sahip/isletmeler', variant: 'secondary' }
        : hasSubmission
          ? { label: 'Başvuruyu Görüntüle', href: '/sahip/isletmeler/basvurular', variant: 'secondary' }
          : { label: 'Başvuru Yap', href: '/sahip/isletmeler/yeni', variant: 'primary' },
    },
    {
      num: 2,
      title: 'Çalışma saatleri ekle',
      description: 'Haftalık çalışma saatlerini belirle ve müşterilerine göster.',
      durum: hasHours ? 'tamamlandi' : hasBusiness ? 'eksik' : 'bekliyor',
      action: hasBusiness ? { label: 'Şimdi Ekle', href: '/sahip/ayarlar', variant: 'primary' } : null,
    },
    {
      num: 3,
      title: 'Menü ürünlerini yükle',
      description: 'Lezzetli ürünlerini ekle, fiyatlandır ve kategorilere ayır.',
      durum: onboarding.hasPublishedMenu ? 'tamamlandi' : hasSomeItems ? 'kismen' : hasBusiness ? 'eksik' : 'bekliyor',
      action: hasBusiness ? { label: onboarding.hasPublishedMenu ? 'Menüyü Düzenle' : 'Devam Et', href: '/sahip/menu-yonetimi', variant: 'primary' } : null,
    },
    {
      num: 4,
      title: 'Fotoğraf ve kapak görseli ekle',
      description: 'İşletmeni en iyi şekilde yansıtan görseller yükle.',
      durum: hasPhotos ? 'tamamlandi' : hasBusiness ? 'eksik' : 'bekliyor',
      action: hasBusiness ? { label: 'Görsel Ekle', href: '/sahip/fotograflar', variant: 'primary' } : null,
    },
    {
      num: 5,
      title: 'QR menünü oluştur',
      description: 'Dijital menünü oluştur ve QR kodunu indir veya paylaş.',
      durum: onboarding.hasQrCode ? 'tamamlandi' : onboarding.hasPublishedMenu ? 'eksik' : 'bekliyor',
      action: onboarding.hasPublishedMenu ? { label: 'QR Oluştur', href: '/sahip/karekod', variant: 'primary' } : null,
    },
    {
      num: 6,
      title: 'İlk kampanyanı yayınla',
      description: 'Müşterilerini çekmek için ilk kampanyanı oluştur.',
      durum: hasCampaign ? 'tamamlandi' : hasBusiness ? 'eksik' : 'bekliyor',
      action: hasBusiness ? { label: 'Kampanya Oluştur', href: '/sahip/pazarlama/kampanyalar', variant: 'secondary' } : null,
    },
    {
      num: 7,
      title: 'Ekibini davet et',
      description: 'Ekibinle birlikte işletmeni daha verimli yönet.',
      durum: onboarding.hasTeamMember ? 'tamamlandi' : hasBusiness ? 'eksik' : 'bekliyor',
      action: hasBusiness ? { label: 'Ekip Davet Et', href: '/sahip/ekip', variant: 'secondary' } : null,
    },
  ];

  const doneCount = steps.filter((s) => s.durum === 'tamamlandi').length;
  const pct = Math.round((doneCount / steps.length) * 100);
  const ilkEksikAdim = steps.find((s) => s.durum !== 'tamamlandi' && s.action);

  return (
    <div className="flex flex-col">
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div>
            <h1 className="text-2xl font-black tracking-tight text-textStrong">Başlangıç Rehberi</h1>
            <p className="mt-1 text-sm text-muted">İşletmeni hızlıca kur, profilini tamamla ve ilk müşterilerine ulaş.</p>
          </div>

          <div className="flex items-center gap-4 rounded-2xl border border-border bg-card p-5">
            <span className="text-3xl">👋</span>
            <div>
              <p className="font-black text-textStrong">Hoş geldin{firstName ? ` ${firstName}` : ''}!</p>
              <p className="text-sm text-muted">İşletmeni yayına almak için aşağıdaki adımları tamamla.</p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
            <div className="flex flex-col gap-6">
              <div className="rounded-2xl border border-border bg-card p-5">
                <div className="flex items-center justify-between">
                  <h2 className="text-sm font-black text-textStrong">Kurulum İlerlemesi</h2>
                  <span className="text-xs font-bold text-muted">{doneCount} / {steps.length} adım tamamlandı</span>
                </div>
                <p className="mt-1 text-3xl font-black text-textStrong">%{pct}</p>
                <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-black/5">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{ width: `${pct}%`, background: 'linear-gradient(90deg, #7f1d1d, #dc2626)' }}
                  />
                </div>
                {doneCount === steps.length ? (
                  <p className="mt-3 rounded-xl bg-emerald-50 px-3 py-2 text-xs font-bold text-emerald-700">
                    Tebrikler! Başlangıç adımlarının tamamını tamamladın.
                  </p>
                ) : (
                  <p className="mt-3 text-xs text-muted">İşletmeni daha fazla kişiye ulaştırmak için adımları tamamlamaya devam et.</p>
                )}
              </div>

              <div>
                <h2 className="mb-3 text-sm font-black text-textStrong">Tamamlanacak Adımlar</h2>
                <div className="flex flex-col gap-3">
                  {steps.map((step) => (
                    <div key={step.num} className="flex items-start gap-4 rounded-2xl border border-border bg-card p-4">
                      <div
                        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-black ${
                          step.durum === 'tamamlandi' ? 'bg-emerald-500 text-white' : 'bg-black/5 text-muted'
                        }`}
                      >
                        {step.durum === 'tamamlandi' ? <CheckIcon /> : step.num}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <p className="text-sm font-extrabold text-textStrong">{step.title}</p>
                          <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${DURUM_ETIKETI[step.durum].className}`}>
                            {DURUM_ETIKETI[step.durum].text}
                          </span>
                        </div>
                        <p className="mt-1 text-sm text-muted">{step.description}</p>
                      </div>
                      {step.action && step.durum !== 'tamamlandi' && (
                        <Link href={step.action.href} className="shrink-0">
                          <PanelActionButton variant={step.action.variant}>{step.action.label}</PanelActionButton>
                        </Link>
                      )}
                    </div>
                  ))}
                </div>
                <p className="mt-3 text-xs text-muted">
                  💡 İpucu: Adımları tamamladıkça profilin daha fazla kişiye ulaşır ve daha çok müşteri kazanırsın.
                </p>
              </div>
            </div>

            <div className="flex flex-col gap-4">
              <div className="rounded-2xl border border-border bg-card p-4">
                <h3 className="mb-3 text-sm font-black text-textStrong">Sıradaki Öneriler</h3>
                <div className="flex flex-col gap-3">
                  <OneriKarti
                    title="Sadakat programı oluştur"
                    description="Düzenli müşterilerini ödüllendir ve sadakati artır."
                    href="/sahip/pazarlama/sadakat"
                    label="Oluştur"
                  />
                  <OneriKarti
                    title="Bildirim tercihlerini ayarla"
                    description="Önemli bildirimleri kaçırmamak için tercihlerini belirle."
                    href="/sahip/ayarlar"
                    label="Ayarla"
                  />
                  <OneriKarti
                    title="Fiyat raporunu incele"
                    description="Rakip analizini gör ve fiyatlarını optimize et."
                    href="/sahip/fiyat-raporu"
                    label="İncele"
                  />
                </div>
              </div>

              <div className="rounded-2xl border border-border bg-card p-4">
                <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı Başlangıç İpuçları</h3>
                <div className="flex flex-col gap-3">
                  <IpucuSatiri title="Profilini eksiksiz doldur" description="Tam profil, güven oluşturur ve keşfedilme şansını artırır." />
                  <IpucuSatiri title="Görseller ekle" description="Yüksek kaliteli görseller müşteri ilgisini artırır." />
                  <IpucuSatiri title="QR menünü paylaş" description="Sosyal medyada veya masalarda paylaşarak siparişleri artır." />
                  <IpucuSatiri title="Kampanya ile öne çık" description="İlk kampanyanla yeni müşterilere ulaş ve sadakat kazan." />
                </div>
              </div>
            </div>
          </div>

          {ilkEksikAdim && (
            <div
              className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left"
              style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}
            >
              <div>
                <p className="font-black text-textStrong">Kurulumu tamamla, daha fazla görünürlük kazan</p>
                <p className="text-sm text-muted">Tüm adımları tamamla, işletmeni daha fazla kişiye ulaştır ve satışlarını artır.</p>
              </div>
              <Link href={ilkEksikAdim.action!.href} className="shrink-0">
                <PanelActionButton variant="primary">Kurulumu Tamamla</PanelActionButton>
              </Link>
            </div>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function OneriKarti({ title, description, href, label }: { title: string; description: string; href: string; label: string }) {
  return (
    <div className="rounded-xl border border-border p-3">
      <p className="text-xs font-extrabold text-textStrong">{title}</p>
      <p className="mt-0.5 text-[11px] text-muted">{description}</p>
      <Link href={href} className="mt-2 inline-block text-xs font-extrabold text-primary hover:underline">
        {label} →
      </Link>
    </div>
  );
}

function IpucuSatiri({ title, description }: { title: string; description: string }) {
  return (
    <div className="border-b border-border pb-3 last:border-0 last:pb-0">
      <p className="text-xs font-extrabold text-textStrong">{title}</p>
      <p className="mt-0.5 text-[11px] text-muted">{description}</p>
    </div>
  );
}

function CheckIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
