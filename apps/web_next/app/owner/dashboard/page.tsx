import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { MetricCard } from '@/src/ui/components/metric-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export const metadata: Metadata = {
  title: 'Genel Bakış | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerDashboardPage() {
  const supabase = await createSupabaseServerClient();

  const { data: { user } } = await supabase.auth.getUser();

  // Fetch summary counts for the authenticated owner
  const bizIds = ((await (supabase as any).from('businesses').select('id').eq('owner_id', user!.id) as { data: Array<{ id: string }> | null }).data ?? []).map((b) => b.id);
  const [businessesRes, menusRes] = await Promise.all([
    (supabase as any)
      .from('businesses')
      .select('id', { count: 'exact', head: true })
      .eq('owner_id', user!.id) as Promise<{ count: number | null }>,
    bizIds.length > 0
      ? (supabase as any)
          .from('menus')
          .select('id', { count: 'exact', head: true })
          .in('business_id', bizIds) as Promise<{ count: number | null }>
      : Promise.resolve({ count: 0 }),
  ]);

  const businessCount = businessesRes.count ?? 0;
  const menuCount = menusRes.count ?? 0;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Genel Bakış"
        description="İşletmelerinizin özet durumu"
      />
      <PanelContentSurface className="pt-6">
        {businessCount === 0 ? (
          <PanelEmptyState
            icon={<BuildingIcon />}
            title="Henüz işletme yok"
            description="İlk işletmenizi ekleyerek başlayın."
          />
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <MetricCard
              title="İşletmeler"
              value={businessCount}
              icon={<BuildingIcon />}
            />
            <MetricCard
              title="Menüler"
              value={menuCount}
              icon={<MenuIcon />}
            />
          </div>
        )}
      </PanelContentSurface>
    </div>
  );
}

function BuildingIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
      <path d="M9 22V12h6v10" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
    </svg>
  );
}
