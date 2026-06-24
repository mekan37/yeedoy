import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { attachEvidenceSignedUrls } from '@/src/lib/storage/claim-evidence-signed-urls';
import { ClaimsTable } from './claims-table';

export const metadata: Metadata = {
  title: 'Sahiplenme Kuyruğu | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function AdminClaimsPage() {
  const supabase = await createSupabaseServerClient();

  // Use any[] since this table may not be in the typed schema yet
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
      <PanelPageHeader
        eyebrow="Admin"
        title="Sahiplenme Kuyruğu"
        description={`${pending.length} bekleyen talep`}
      />
      <PanelContentSurface className="pt-6">
        <div className="flex flex-col gap-6">
          <PanelSectionCard
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
          </PanelSectionCard>

          {recent.length > 0 && (
            <PanelSectionCard
              title="Son İşlenenler"
              description="En son onaylanan / reddedilen talepler"
            >
              <ClaimsTable claims={recent as any} compact />
            </PanelSectionCard>
          )}
        </div>
      </PanelContentSurface>
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
