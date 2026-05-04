import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { ClaimsTable } from './claims-table';

export const metadata: Metadata = {
  title: 'Sahiplenme Kuyruğu | Admin Panel',
  robots: { index: false, follow: false },
};

export default async function AdminClaimsPage() {
  const supabase = await createSupabaseServerClient();

  // Use any[] since this table may not be in the typed schema yet
  const { data: claims } = await (supabase as any)
    .from('business_ownership_claims')
    .select(
      'id, status, created_at, ' +
      'businesses(id, name, slug), ' +
      'user_profiles(id, display_name, email)',
    )
    .order('created_at', { ascending: true })
    .limit(100);

  const pending = (claims ?? []).filter((c: any) => c.status === 'pending');
  const recent = (claims ?? []).filter((c: any) => c.status !== 'pending').slice(0, 20);

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
              <ClaimsTable claims={pending} />
            )}
          </PanelSectionCard>

          {recent.length > 0 && (
            <PanelSectionCard
              title="Son İşlenenler"
              description="En son onaylanan / reddedilen talepler"
            >
              <ClaimsTable claims={recent} compact />
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
