import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface, PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { DomainVerifyCard } from '@/src/ui/bilesenler/domain-verify-card';

export const metadata: Metadata = {
  title: 'Özel Domain | Owner Panel',
  robots: { index: false, follow: false },
};

export default async function OwnerSettingsDomainPage() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: businesses } = await (supabase as any)
    .from('businesses')
    .select('id, name, custom_domain')
    .eq('owner_id', user!.id) as { data: Array<{ id: string; name: string; custom_domain: string | null }> | null };

  const list = (businesses ?? []) as Array<{ id: string; name: string; custom_domain: string | null }>;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Özel Domain"
        description="İşletmeleriniz için özel alan adı ayarlarını yönetin"
      />
      <PanelContentSurface className="pt-6">
        {list.length === 0 ? (
          <PanelEmptyState
            icon={<GlobeIcon />}
            title="İşletme bulunamadı"
            description="Özel domain eklemek için önce bir işletme oluşturun."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {list.map((b) => (
              <PanelSectionCard key={b.id} title={b.name}>
                <div className="flex flex-col gap-4">
                  {b.custom_domain && (
                    <div className="flex items-center gap-2">
                      <span className="rounded-lg border border-green-200 bg-green-50 px-3 py-1.5 text-sm font-[700] text-green-700">
                        {b.custom_domain}
                      </span>
                      <span className="rounded-full bg-green-50 px-2 py-0.5 text-[11px] font-[800] text-green-700">
                        Aktif
                      </span>
                    </div>
                  )}
                  <DomainVerifyCard businessId={b.id} currentDomain={b.custom_domain} />
                </div>
              </PanelSectionCard>
            ))}
          </div>
        )}
      </PanelContentSurface>
    </div>
  );
}

function GlobeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <line x1="2" y1="12" x2="22" y2="12" />
      <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  );
}
