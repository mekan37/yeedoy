import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { attachEvidenceSignedUrls } from '@/src/lib/storage/claim-evidence-signed-urls';
import { ClaimsTable } from './itiraz-tablosu';

export const metadata: Metadata = {
  title: 'Sahiplenme Kuyruğu | Yonetici Paneli',
  robots: { index: false, follow: false },
};

export default async function AdminClaimsPage() {
  const supabase = await createSupabaseServerClient();

  const { data: claims } = await (supabase as any)
    .from('owner_claims')
    .select(
      'id, status, created_at, evidence_storage_path, ' +
      'businesses(id, name, slug), ' +
      'user_profiles(user_id, display_name)',
    )
    .order('created_at', { ascending: true })
    .limit(100);

  const enrichedClaims = await attachEvidenceSignedUrls(supabase, claims ?? []);
  const pending = enrichedClaims.filter((c) => c.status === 'pending');
  const recent = enrichedClaims.filter((c) => c.status !== 'pending').slice(0, 20);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetici"
        title="Sahiplenme Kuyruğu"
        description={`${pending.length} bekleyen talep`}
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <PanelBolumKarti
            title="Bekleyen Talepler"
            description={`${pending.length} talep inceleme bekliyor`}
          >
            {pending.length === 0 ? (
              <PanelEmptyState
                icon={<CheckIcon />}
                title="Bekleyen talep yok"
                description="Tüm talepler işlendi."
              />
            ) : (
              <ClaimsTable claims={pending as any} />
            )}
          </PanelBolumKarti>

          {recent.length > 0 && (
            <PanelBolumKarti
              title="Son İşlenenler"
              description="En son onaylanan / reddedilen talepler"
            >
              <ClaimsTable claims={recent as any} compact />
            </PanelBolumKarti>
          )}
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function CheckIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}

