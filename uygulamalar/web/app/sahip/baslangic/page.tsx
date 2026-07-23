import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { getOnboardingStatus } from './baslangic-durumu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';

export const metadata: Metadata = {
  title: 'Başlangıç Rehberi | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function OwnerOnboardingPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const businessIds = await getOwnerBusinessIds(supabase as any, user!.id);

  const { data: submissions } = await (supabase as any)
    .from('business_submissions')
    .select('id, status')
    .eq('submitted_by', user!.id)
    .limit(1);

  const hasBusiness = businessIds.length > 0;
  const hasSubmission = (submissions ?? []).length > 0;
  const submissionPending = hasSubmission && submissions[0]?.status === 'new';

  const onboarding = await getOnboardingStatus();
  const doneCount = [
    hasBusiness,
    onboarding.hasPublishedMenu,
    onboarding.hasQrCode,
    onboarding.hasTeamMember,
  ].filter(Boolean).length;

  const steps = [
    {
      num: 1,
      title: 'İşletmenizi Ekleyin',
      description: hasBusiness
        ? 'İşletmeniz platforma eklenmiş.'
        : hasSubmission
          ? submissionPending
            ? 'Başvurunuz inceleniyor, onay bekliyorsunuz.'
            : 'Başvurunuz işlendi.'
          : 'Başvuru formu ile işletmenizi platforma ekleyin.',
      done: hasBusiness,
      pending: submissionPending,
      action: !hasBusiness && !hasSubmission ? (
        <Link href="/sahip/isletmeler/yeni">
          <PanelActionButton variant="primary" icon={<PlusIcon />}>
            Başvuru Yap
          </PanelActionButton>
        </Link>
      ) : hasSubmission && !hasBusiness ? (
        <Link href="/sahip/isletmeler/basvurular">
          <PanelActionButton variant="secondary">Başvuruyu Görüntüle</PanelActionButton>
        </Link>
      ) : (
        <Link href="/sahip/isletmeler">
          <PanelActionButton variant="secondary">İşletmeleri Gör</PanelActionButton>
        </Link>
      ),
    },
    {
      num: 2,
      title: 'İlk Menünüzü Oluşturun',
      description: 'İşletmeniz onaylandıktan sonra menü ve ürünlerinizi ekleyebilirsiniz.',
      done: onboarding.hasPublishedMenu,
      pending: false,
      action: hasBusiness ? (
        <Link href="/sahip/menuler">
          <PanelActionButton variant="primary" icon={<MenuIcon />}>
            Menülere Git
          </PanelActionButton>
        </Link>
      ) : null,
    },
    {
      num: 3,
      title: 'QR Kodunuzu Alın',
      description: 'Menünüzü yayınladıktan sonra masalarınıza QR kod ekleyebilirsiniz.',
      done: onboarding.hasQrCode,
      pending: false,
      action: null,
    },
    {
      num: 4,
      title: 'Ekibinizi Davet Edin',
      description: 'Yönetici, editör veya personel rolüyle ekip üyesi ekleyin.',
      done: onboarding.hasTeamMember,
      pending: false,
      action: hasBusiness ? (
        <Link href="/sahip/ekip">
          <PanelActionButton variant="secondary">Ekip Yönetimi</PanelActionButton>
        </Link>
      ) : null,
    },
  ];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Başlangıç Rehberi"
        description="Platforma başlamak için adım adım rehber"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="mb-4 flex items-center justify-between">
          <p className="text-sm font-[800] text-textStrong">{doneCount}/4 tamamlandı</p>
          <div className="h-2 w-40 overflow-hidden rounded-full bg-border">
            <div
              className="h-full rounded-full bg-green-500 transition-all"
              style={{ width: `${(doneCount / 4) * 100}%` }}
            />
          </div>
        </div>
        {onboarding.complete && (
          <div className="mb-4 rounded-xl border border-success/25 bg-success/[0.08] px-4 py-3 text-sm font-[700] text-success">
            Tebrikler! Başlangıç adımlarının tamamını tamamladınız.
          </div>
        )}
        <div className="flex flex-col gap-4">
          {steps.map((step) => (
            <PanelBolumKarti key={step.num}>
              <div className="flex items-start gap-4">
                <div
                  className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-[900] ${
                    step.done
                      ? 'bg-green-500 text-white'
                      : step.pending
                        ? 'bg-amber-400 text-white'
                        : 'bg-border text-muted'
                  }`}
                >
                  {step.done ? <CheckIcon /> : step.num}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="text-sm font-[800] text-textStrong">{step.title}</p>
                    {step.done && (
                      <span className="rounded-full bg-green-50 px-2 py-0.5 text-[10px] font-[800] text-green-700">
                        Tamamlandı
                      </span>
                    )}
                    {step.pending && (
                      <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-[800] text-amber-700">
                        Bekliyor
                      </span>
                    )}
                  </div>
                  <p className="mt-1 text-sm text-muted">{step.description}</p>
                  {step.action && <div className="mt-3">{step.action}</div>}
                </div>
              </div>
            </PanelBolumKarti>
          ))}
        </div>
      </PanelIcerikYuzeyi>
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

function PlusIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
    </svg>
  );
}

