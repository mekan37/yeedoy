import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
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
  const hasBusiness = businessIds.length > 0;

  const { data: submissions } = await (supabase as any)
    .from('business_submissions')
    .select('id, status')
    .eq('submitted_by', user!.id)
    .limit(1);

  const hasSubmission = (submissions ?? []).length > 0;
  const submissionPending = hasSubmission && submissions[0]?.status === 'new';

  const [publishedMenuRes, qrCodeRes, teamRes] = await Promise.all([
    hasBusiness
      ? (supabase as any).from('menus').select('id', { count: 'exact', head: true }).in('business_id', businessIds).eq('status', 'published')
      : Promise.resolve({ count: 0 }),
    hasBusiness
      ? (supabase as any).from('business_qr_codes').select('id', { count: 'exact', head: true }).in('business_id', businessIds)
      : Promise.resolve({ count: 0 }),
    hasBusiness
      ? (supabase as any).from('business_team_memberships').select('id', { count: 'exact', head: true }).in('business_id', businessIds).is('revoked_at', null)
      : Promise.resolve({ count: 0 }),
  ]);

  const hasPublishedMenu = (publishedMenuRes.count ?? 0) > 0;
  const hasQrCode = (qrCodeRes.count ?? 0) > 0;
  const hasTeamMember = (teamRes.count ?? 0) > 0;

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
      description: hasPublishedMenu
        ? 'Yayında bir menünüz var.'
        : 'İşletmeniz onaylandıktan sonra menü ve ürünlerinizi ekleyip yayına alın.',
      done: hasPublishedMenu,
      pending: false,
      action: hasBusiness ? (
        <Link href="/sahip/menuler">
          <PanelActionButton variant={hasPublishedMenu ? 'secondary' : 'primary'} icon={<MenuIcon />}>
            Menülere Git
          </PanelActionButton>
        </Link>
      ) : null,
    },
    {
      num: 3,
      title: 'QR Kodunuzu Alın',
      description: hasQrCode
        ? 'En az bir QR kodunuz oluşturuldu.'
        : 'Menünüzü yayınladıktan sonra masalarınıza QR kod ekleyebilirsiniz.',
      done: hasQrCode,
      pending: false,
      action: hasBusiness ? (
        <Link href="/sahip/karekod">
          <PanelActionButton variant={hasQrCode ? 'secondary' : 'primary'} icon={<QrIcon />}>
            QR Kod Oluştur
          </PanelActionButton>
        </Link>
      ) : null,
    },
    {
      num: 4,
      title: 'Ekibinizi Davet Edin',
      description: hasTeamMember
        ? 'Ekibinize en az bir üye eklediniz.'
        : 'Yönetici, editör veya personel rolüyle ekip üyesi ekleyin.',
      done: hasTeamMember,
      pending: false,
      action: hasBusiness ? (
        <Link href="/sahip/ekip">
          <PanelActionButton variant={hasTeamMember ? 'secondary' : 'primary'}>Ekip Yönetimi</PanelActionButton>
        </Link>
      ) : null,
    },
  ];

  const completedCount = steps.filter((s) => s.done).length;
  const allDone = completedCount === steps.length;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Owner"
        title="Başlangıç Rehberi"
        description={
          allDone
            ? 'Tüm adımları tamamladınız — bu sayfa artık menüden kalkacak.'
            : `Platforma başlamak için adım adım rehber — ${completedCount}/${steps.length} tamamlandı`
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-4">
          {allDone && (
            <div className="flex items-center gap-3 rounded-2xl border border-green-200 bg-green-50 px-5 py-4">
              <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-green-500 text-white">
                <CheckIcon />
              </div>
              <div>
                <p className="font-[900] text-green-900">Tebrikler, kurulum tamam!</p>
                <p className="mt-0.5 text-sm text-green-800">
                  Tüm başlangıç adımlarını tamamladınız. Bu rehber artık sol menüde görünmeyecek.
                </p>
              </div>
            </div>
          )}

          {/* İlerleme çubuğu */}
          <div className="flex items-center gap-3">
            <div className="h-2 flex-1 overflow-hidden rounded-full bg-bg">
              <div
                className="h-full rounded-full bg-primary transition-all"
                style={{ width: `${(completedCount / steps.length) * 100}%` }}
              />
            </div>
            <span className="shrink-0 text-xs font-[800] text-muted">{completedCount}/{steps.length}</span>
          </div>

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

function QrIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" />
    </svg>
  );
}
